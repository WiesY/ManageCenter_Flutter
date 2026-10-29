#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Генератор датасета «Баланс воды / Потери» из выгрузки биллинга в .xlsx.

Зачем скрипт, а не разовый разбор руками: выгрузка приходит каждый квартал,
и следующую версию нужно пересобирать той же командой.

    python3 tool/generate_water_losses.py "ОБЩАЯ 2-2.xlsx" assets/water_losses/2026_q1.json

Если аргументы не заданы — берутся значения по умолчанию (см. main).

Формат исходника (лист один):
  • строка с датами   — даты помесячных блоков в объединённых ячейках (D2:G2 и т.п.);
  • строка заголовков — B=ВЗУ, C=ЭР, далее блоки ФЛС / Объем / Объем сторно /
                        Объем ВСЕГО / ВЗУ (поднято);
  • далее строки данных до первой строки без названия объекта.

openpyxl намеренно не используется — его нет в окружении, а xlsx это zip с XML.
"""

import json
import os
import re
import sys
import zipfile
import datetime
import xml.etree.ElementTree as ET
from collections import Counter

NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'

# Excel-serial 1 == 1900-01-02 в 1900-й системе дат, отсюда база 1899-12-30.
EXCEL_EPOCH = datetime.date(1899, 12, 30)

# Текст вместо числа в колонке «поднято» — не ошибка выгрузки, а состояние
# прибора учёта. Порядок важен: проверяем подстроки сверху вниз.
PUMPED_STATUS_RULES = [
    ('нет пу', 'noDevice'),
    ('неиспр', 'faulty'),
    ('байпас', 'bypass'),
    ('останов', 'stopped'),
    ('нераб', 'notWorking'),
    ('некор', 'incorrect'),
]

# Ожидаемые подписи внутри одного помесячного блока.
BLOCK_HEADERS = ['ФЛС', 'Объем', 'Объем сторно', 'Объем ВСЕГО', 'ВЗУ']


# ─────────────────────────────────────────────────────────────────────────────
# Разбор xlsx
# ─────────────────────────────────────────────────────────────────────────────

def col_to_index(col):
    """'A' -> 0, 'B' -> 1, 'AA' -> 26."""
    n = 0
    for ch in col:
        n = n * 26 + (ord(ch) - ord('A') + 1)
    return n - 1


def index_to_col(idx):
    """0 -> 'A'. Нужно только для сообщений об ошибках."""
    s = ''
    idx += 1
    while idx:
        idx, rem = divmod(idx - 1, 26)
        s = chr(ord('A') + rem) + s
    return s


def read_sheet(path):
    """Возвращает {номер строки: {колонка: значение}}; значения — str или float."""
    with zipfile.ZipFile(path) as z:
        shared = []
        if 'xl/sharedStrings.xml' in z.namelist():
            root = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for si in root.findall(f'{NS}si'):
                shared.append(''.join(t.text or '' for t in si.iter(f'{NS}t')))
        sheet = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))

    rows = {}
    for row in sheet.iter(f'{NS}row'):
        cells = {}
        for c in row.findall(f'{NS}c'):
            col = re.match(r'([A-Z]+)', c.get('r')).group(1)
            ctype = c.get('t')
            v = c.find(f'{NS}v')
            inline = c.find(f'{NS}is')

            if ctype == 's' and v is not None:
                val = shared[int(v.text)]
            elif ctype == 'inlineStr' and inline is not None:
                val = ''.join(t.text or '' for t in inline.iter(f'{NS}t'))
            elif ctype == 'str' and v is not None:  # результат формулы
                val = v.text
            elif v is not None:
                try:
                    val = float(v.text)
                except (TypeError, ValueError):
                    val = v.text
            else:
                continue

            if isinstance(val, str):
                val = val.strip()
                if not val:
                    continue
            cells[col] = val
        if cells:
            rows[int(row.get('r'))] = cells
    return rows


# ─────────────────────────────────────────────────────────────────────────────
# Разбор структуры листа
# ─────────────────────────────────────────────────────────────────────────────

def find_header_row(rows):
    """Строка заголовков — та, где B='ВЗУ' и C='ЭР'."""
    for r in sorted(rows):
        cells = rows[r]
        if cells.get('B') == 'ВЗУ' and cells.get('C') == 'ЭР':
            return r
    raise SystemExit('Не найдена строка заголовков (ожидались B="ВЗУ", C="ЭР")')


def find_blocks(rows, header_row):
    """
    Находит помесячные блоки: [(period_key, {'accounts': 'D', 'realized': 'G',
    'pumped': 'H'}), ...] — отсортированные по колонке.

    Дата блока лежит в строке над заголовками, в левой ячейке объединения.
    """
    date_row = rows.get(header_row - 1, {})
    starts = []
    for col, val in date_row.items():
        if isinstance(val, float) and val > 20000:  # похоже на Excel-serial
            starts.append((col_to_index(col), col, val))
    if not starts:
        raise SystemExit(
            f'В строке {header_row - 1} не найдено ни одной даты помесячного блока')
    starts.sort()

    header = rows[header_row]
    blocks = []
    for start_idx, start_col, serial in starts:
        cols = [index_to_col(start_idx + i) for i in range(5)]
        labels = [header.get(c) for c in cols]
        if labels != BLOCK_HEADERS:
            print(f'  ! блок с {start_col}: подписи {labels} != {BLOCK_HEADERS} '
                  f'— структура выгрузки изменилась', file=sys.stderr)
        date = EXCEL_EPOCH + datetime.timedelta(days=int(serial))
        blocks.append((
            f'{date.year:04d}-{date.month:02d}',
            {'accounts': cols[0], 'realized': cols[3], 'pumped': cols[4]},
        ))
    return blocks


def classify_pumped(raw):
    """
    Возвращает (pumped, status, pumpedRaw).

    pumped — float либо None; status — одно из ok/missing/... ; pumpedRaw —
    исходный текст, если в ячейке был не число (в UI показываем его как есть).
    """
    if raw is None:
        return None, 'missing', None
    if isinstance(raw, float):
        return raw, 'ok', None

    text = str(raw)
    low = text.lower()
    for needle, status in PUMPED_STATUS_RULES:
        if needle in low:
            return None, status, text
    # Число, записанное текстом, — всё-таки данные.
    try:
        return float(low.replace(',', '.').replace(' ', '')), 'ok', None
    except ValueError:
        return None, 'unknown', text


def num(cells, col):
    v = cells.get(col)
    return v if isinstance(v, float) else None


def build_dataset(rows, source_name):
    header_row = find_header_row(rows)
    blocks = find_blocks(rows, header_row)
    print(f'Заголовки: строка {header_row}. Блоки: '
          + ', '.join(f'{p} (поднято в {c["pumped"]})' for p, c in blocks))

    nodes = []
    status_counter = Counter()
    r = header_row + 1
    while True:
        cells = rows.get(r)
        if not cells:
            break
        name = cells.get('B')
        if not isinstance(name, str) or not name:
            break

        district = num(cells, 'C')
        node = {
            'name': name,
            'district': int(district) if district is not None else None,
            'months': {},
        }
        for period, cols in blocks:
            accounts = num(cells, cols['accounts'])
            realized = num(cells, cols['realized'])
            pumped, status, pumped_raw = classify_pumped(cells.get(cols['pumped']))

            # Месяц, в котором вообще нет цифр, в датасет не пишем.
            if accounts is None and realized is None and pumped is None \
                    and pumped_raw is None:
                continue

            month = {'pumpedStatus': status}
            if accounts is not None:
                month['accounts'] = int(accounts)
            if realized is not None:
                month['realized'] = round(realized, 2)
            if pumped is not None:
                month['pumped'] = round(pumped, 2)
            if pumped_raw is not None:
                month['pumpedRaw'] = pumped_raw

            node['months'][period] = month
            status_counter[status] += 1

        nodes.append(node)
        r += 1

    return {
        'source': source_name,
        'periods': [p for p, _ in blocks],
        'nodes': nodes,
    }, status_counter


# ─────────────────────────────────────────────────────────────────────────────
# Отчёт о качестве данных
# ─────────────────────────────────────────────────────────────────────────────

def report(dataset, status_counter):
    periods = dataset['periods']
    nodes = dataset['nodes']
    print(f'\nОбъектов: {len(nodes)}, периодов: {len(periods)}')
    print('Статусы «поднято» (по всем месяцам):')
    for status, cnt in status_counter.most_common():
        print(f'  {status:<12} {cnt}')

    for period in periods:
        valid = negative = exceeds = suspicious = no_pumped = 0
        for n in nodes:
            m = n['months'].get(period)
            if m is None:
                no_pumped += 1
                continue
            realized = m.get('realized')
            pumped = m.get('pumped')
            if m['pumpedStatus'] != 'ok' or pumped is None or pumped <= 0:
                no_pumped += 1
                continue
            if realized is None or realized < 0:
                negative += 1
                continue
            if realized > pumped:
                exceeds += 1
                continue
            valid += 1
            if (pumped - realized) / pumped > 0.6:
                suspicious += 1
        print(f'\n{period}: расчёт возможен у {valid} из {len(nodes)} объектов'
              f' (из них {suspicious} с потерями >60%)')
        print(f'  нет данных подъёма: {no_pumped}, '
              f'отрицательная реализация: {negative}, '
              f'реализация > подъёма: {exceeds}')


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, 'ОБЩАЯ 2-2.xlsx')
    dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
        root, 'assets', 'water_losses', '2026_q1.json')

    if not os.path.exists(src):
        raise SystemExit(f'Не найден исходный файл: {src}')

    print(f'Читаю {src}')
    rows = read_sheet(src)
    dataset, status_counter = build_dataset(rows, os.path.basename(src))
    report(dataset, status_counter)

    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, 'w', encoding='utf-8') as f:
        json.dump(dataset, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(f'\nЗаписано: {dst}')


if __name__ == '__main__':
    main()
