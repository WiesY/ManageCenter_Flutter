// test/water_losses_test.dart
//
// Проверяем контракт датасета «Баланс воды» и правила расчёта: главное, чтобы
// объекты без пригодных цифр не превращались в «потери 0 · в норме».

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manage_center/models/water_losses_dataset.dart';

void main() {
  group('датасет выгрузки', () {
    late WaterLossesDataset dataset;

    setUpAll(() {
      final raw = File('assets/water_losses/2026_q1.json').readAsStringSync();
      dataset = WaterLossesDataset.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    });

    test('читается целиком', () {
      expect(dataset.periods, ['2026-01', '2026-02', '2026-03']);
      expect(dataset.nodes.length, 59);
      expect(dataset.nodes.every((n) => n.name.isNotEmpty), isTrue);
    });

    test('ЭР у всех объектов в диапазоне 1–5', () {
      for (final n in dataset.nodes) {
        expect(n.district, isNotNull, reason: n.name);
        expect(n.district, inInclusiveRange(1, 5), reason: n.name);
      }
    });

    test('текст в колонке подъёма превращается в статус, а не в число', () {
      for (final n in dataset.nodes) {
        for (final m in n.months.values) {
          if (m.pumpedStatus == PumpedStatus.ok) {
            expect(m.pumped, isNotNull, reason: n.name);
          } else {
            expect(m.pumped, isNull, reason: n.name);
          }
        }
      }
    });

    test('нормализация имён схлопывает пунктуацию и пробелы', () {
      expect(normalizeNodeName('ВЗУ Дедовск(N1, N2 )'), 'взу дедовск n1 n2');
      expect(normalizeNodeName('ВЗУ  д.Чёрная, ул. Европейская'),
          'взу д черная ул европейская');
    });
  });

  group('расчёт баланса', () {
    WaterBalance compute(WaterMonthEntry? e, [WaterOverride? o]) =>
        WaterBalance.compute(entry: e, override: o);

    test('нормальные цифры дают потери и процент', () {
      final b = compute(const WaterMonthEntry(
        accounts: 226,
        realized: 1171.53,
        pumped: 2302,
        pumpedStatus: PumpedStatus.ok,
      ));
      expect(b.state, WaterBalanceState.calculated);
      expect(b.losses, closeTo(1130.47, 0.01));
      expect(b.lossPercent, closeTo(49.11, 0.01));
      expect(b.needsReview, isFalse);
      expect(b.financialLoss(50), closeTo(56523.5, 0.1));
    });

    test('нет прибора учёта — не нуль, а причина', () {
      final b = compute(const WaterMonthEntry(
        realized: 706.28,
        pumpedStatus: PumpedStatus.noDevice,
        pumpedRaw: 'нет ПУ',
      ));
      expect(b.state, WaterBalanceState.noPumped);
      expect(b.losses, isNull);
      expect(b.isValid, isFalse);
      expect(b.message, contains('прибор учёта не установлен'));
    });

    test('нулевой подъём тоже не даёт расчёта', () {
      final b = compute(const WaterMonthEntry(
        realized: 1515.37,
        pumped: 0,
        pumpedStatus: PumpedStatus.ok,
      ));
      expect(b.state, WaterBalanceState.noPumped);
    });

    test('отрицательная реализация помечается как некорректная', () {
      final b = compute(const WaterMonthEntry(
        realized: -4463.39,
        pumped: 504,
        pumpedStatus: PumpedStatus.ok,
      ));
      expect(b.state, WaterBalanceState.negativeRealized);
      expect(b.isBroken, isTrue);
      expect(b.message, contains('сторно'));
    });

    test('реализация больше подъёма требует проверки', () {
      final b = compute(const WaterMonthEntry(
        realized: 5614.53,
        pumped: 620,
        pumpedStatus: PumpedStatus.ok,
      ));
      expect(b.state, WaterBalanceState.realizedExceedsPumped);
      expect(b.isBroken, isTrue);
    });

    test('нет реализации — отдельное состояние', () {
      final b = compute(const WaterMonthEntry(
        pumped: 1240,
        pumpedStatus: PumpedStatus.ok,
      ));
      expect(b.state, WaterBalanceState.noRealized);
    });

    test('потери выше 60% считаются, но помечаются', () {
      final b = compute(const WaterMonthEntry(
        realized: 14,
        pumped: 12164,
        pumpedStatus: PumpedStatus.ok,
      ));
      expect(b.state, WaterBalanceState.calculated);
      expect(b.needsReview, isTrue);
    });

    test('ручной ввод перекрывает выгрузку и снимает статус прибора', () {
      final b = compute(
        const WaterMonthEntry(
          realized: 700.81,
          pumpedStatus: PumpedStatus.noDevice,
          pumpedRaw: 'нет ПУ',
        ),
        const WaterOverride(pumped: 900),
      );
      expect(b.state, WaterBalanceState.calculated);
      expect(b.pumped, 900);
      expect(b.pumpedIsManual, isTrue);
      expect(b.realizedIsManual, isFalse);
    });

    test('сброс правки возвращает значение выгрузки', () {
      const o = WaterOverride(pumped: 900, realized: 100);
      expect(o.copyWith(dropPumped: true).pumped, isNull);
      expect(o.copyWith(dropPumped: true).realized, 100);
      expect(
          o.copyWith(dropPumped: true, dropRealized: true).isEmpty, isTrue);
    });
  });
}
