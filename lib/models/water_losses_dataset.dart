// lib/models/water_losses_dataset.dart
//
// Датасет «Баланс воды / Потери»
// ──────────────────────────────────────────────────────────────────────────────
// Помесячные цифры по объектам ВЗУ из выгрузки биллинга (файл «ОБЩАЯ 2-2.xlsx»),
// перегнанной в assets/water_losses/*.json скриптом tool/generate_water_losses.py.
//
// Важное свойство источника: колонка «поднято» заполнена меньше чем у половины
// объектов — где-то пусто, где-то текст «неиспр» / «нет ПУ» / «байпас». Это не
// дефект разбора, а фактическое состояние приборов учёта, поэтому оно доезжает
// до UI как [PumpedStatus], а не молча превращается в нуль.
// ──────────────────────────────────────────────────────────────────────────────

/// Состояние цифры «поднято» в выгрузке.
enum PumpedStatus {
  /// В ячейке число — потери считать можно.
  ok,

  /// Ячейка пустая.
  missing,

  /// «нет ПУ» — прибор учёта не установлен.
  noDevice,

  /// «неиспр» — прибор учёта неисправен.
  faulty,

  /// «байпас» — вода идёт мимо прибора учёта.
  bypass,

  /// «останов» — объект остановлен.
  stopped,

  /// «нераб» — объект не работает.
  notWorking,

  /// «некор» — показания признаны некорректными.
  incorrect,

  /// Любой другой текст вместо числа; исходное значение — в `pumpedRaw`.
  unknown;

  static PumpedStatus parse(String? raw) {
    switch (raw) {
      case 'ok':
        return PumpedStatus.ok;
      case 'missing':
        return PumpedStatus.missing;
      case 'noDevice':
        return PumpedStatus.noDevice;
      case 'faulty':
        return PumpedStatus.faulty;
      case 'bypass':
        return PumpedStatus.bypass;
      case 'stopped':
        return PumpedStatus.stopped;
      case 'notWorking':
        return PumpedStatus.notWorking;
      case 'incorrect':
        return PumpedStatus.incorrect;
      default:
        return PumpedStatus.unknown;
    }
  }
}

extension PumpedStatusText on PumpedStatus {
  /// Причина отсутствия цифры — показывается вместо потерь в карточке объекта.
  String get reason {
    switch (this) {
      case PumpedStatus.ok:
        return '';
      case PumpedStatus.missing:
        return 'Нет данных: подъём в выгрузке не заполнен';
      case PumpedStatus.noDevice:
        return 'Нет данных: прибор учёта не установлен';
      case PumpedStatus.faulty:
        return 'Нет данных: прибор учёта неисправен';
      case PumpedStatus.bypass:
        return 'Нет данных: вода идёт через байпас';
      case PumpedStatus.stopped:
        return 'Нет данных: объект остановлен';
      case PumpedStatus.notWorking:
        return 'Нет данных: объект не работает';
      case PumpedStatus.incorrect:
        return 'Нет данных: показания признаны некорректными';
      case PumpedStatus.unknown:
        return 'Нет данных: в выгрузке текст вместо числа';
    }
  }

  /// Короткая пометка для плитки «Поднято».
  String get shortLabel {
    switch (this) {
      case PumpedStatus.ok:
        return '';
      case PumpedStatus.missing:
        return 'не заполнено';
      case PumpedStatus.noDevice:
        return 'нет ПУ';
      case PumpedStatus.faulty:
        return 'неисправен';
      case PumpedStatus.bypass:
        return 'байпас';
      case PumpedStatus.stopped:
        return 'останов';
      case PumpedStatus.notWorking:
        return 'не работает';
      case PumpedStatus.incorrect:
        return 'некорректно';
      case PumpedStatus.unknown:
        return 'нет числа';
    }
  }
}

/// Цифры по одному объекту за один месяц — ровно то, что было в выгрузке.
class WaterMonthEntry {
  /// Количество лицевых счетов (колонка «ФЛС»).
  final int? accounts;

  /// Реализовано абонентам, м³ (колонка «Объем ВСЕГО» — с учётом сторно,
  /// поэтому местами уходит в минус).
  final double? realized;

  /// Поднято, м³. `null`, если [pumpedStatus] != [PumpedStatus.ok].
  final double? pumped;

  final PumpedStatus pumpedStatus;

  /// Исходный текст ячейки «поднято», если там было не число.
  final String? pumpedRaw;

  const WaterMonthEntry({
    this.accounts,
    this.realized,
    this.pumped,
    required this.pumpedStatus,
    this.pumpedRaw,
  });

  factory WaterMonthEntry.fromJson(Map<String, dynamic> j) => WaterMonthEntry(
        accounts: (j['accounts'] as num?)?.toInt(),
        realized: (j['realized'] as num?)?.toDouble(),
        pumped: (j['pumped'] as num?)?.toDouble(),
        pumpedStatus: PumpedStatus.parse(j['pumpedStatus'] as String?),
        pumpedRaw: j['pumpedRaw'] as String?,
      );
}

/// Объект ВЗУ из выгрузки.
class WaterNode {
  final String name;

  /// Эксплуатационный район (1–5). `null`, если в выгрузке не указан.
  final int? district;

  /// Цифры по месяцам, ключ — `YYYY-MM`.
  final Map<String, WaterMonthEntry> months;

  /// Нормализованное имя: ключ для SharedPreferences и для сопоставления
  /// с объектами из API.
  final String key;

  WaterNode({
    required this.name,
    required this.district,
    required this.months,
  }) : key = normalizeNodeName(name);

  factory WaterNode.fromJson(Map<String, dynamic> j) => WaterNode(
        name: j['name'] as String,
        district: (j['district'] as num?)?.toInt(),
        months: (j['months'] as Map<String, dynamic>).map(
          (period, v) => MapEntry(
            period,
            WaterMonthEntry.fromJson(v as Map<String, dynamic>),
          ),
        ),
      );
}

class WaterLossesDataset {
  /// Имя исходного файла выгрузки — показываем в UI, чтобы было видно,
  /// откуда цифры.
  final String source;

  /// Периоды в порядке возрастания, ключи `YYYY-MM`.
  final List<String> periods;

  final List<WaterNode> nodes;

  const WaterLossesDataset({
    required this.source,
    required this.periods,
    required this.nodes,
  });

  factory WaterLossesDataset.fromJson(Map<String, dynamic> j) =>
      WaterLossesDataset(
        source: (j['source'] as String?) ?? '',
        periods: (j['periods'] as List).cast<String>(),
        nodes: (j['nodes'] as List)
            .map((e) => WaterNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Приводит название объекта к виду, по которому можно сравнивать выгрузку
/// с названиями в системе: «ВЗУ Дедовск(N1, N2 )» → «взу дедовск n1 n2».
String normalizeNodeName(String raw) {
  final lower = raw.toLowerCase().replaceAll('ё', 'е').replaceAll('№', 'n');
  final cleaned = lower.replaceAll(RegExp(r'[^0-9a-zа-я]+'), ' ');
  return cleaned.trim();
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ручные правки
// ═══════════════════════════════════════════════════════════════════════════════

/// Ручной ввод, перекрывающий выгрузку. Хранится per объект × месяц.
class WaterOverride {
  final double? realized;
  final double? pumped;

  const WaterOverride({this.realized, this.pumped});

  bool get isEmpty => realized == null && pumped == null;

  Map<String, dynamic> toJson() => {
        if (realized != null) 'realized': realized,
        if (pumped != null) 'pumped': pumped,
      };

  factory WaterOverride.fromJson(Map<String, dynamic> j) => WaterOverride(
        realized: (j['realized'] as num?)?.toDouble(),
        pumped: (j['pumped'] as num?)?.toDouble(),
      );

  WaterOverride copyWith({
    double? realized,
    double? pumped,
    bool dropRealized = false,
    bool dropPumped = false,
  }) =>
      WaterOverride(
        realized: dropRealized ? null : (realized ?? this.realized),
        pumped: dropPumped ? null : (pumped ?? this.pumped),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Расчёт баланса
// ═══════════════════════════════════════════════════════════════════════════════

/// Что удалось посчитать по объекту за месяц.
enum WaterBalanceState {
  /// Потери посчитаны.
  calculated,

  /// Объекта нет в выгрузке за этот месяц.
  noData,

  /// Нет пригодной цифры подъёма (статус прибора учёта или подъём = 0).
  noPumped,

  /// Нет цифры реализации.
  noRealized,

  /// Реализация отрицательная — сторно перекрыло начисления.
  negativeRealized,

  /// Реализация больше подъёма.
  realizedExceedsPumped,
}

/// Итог расчёта по одному объекту за один месяц.
///
/// Потери считаются ТОЛЬКО при [WaterBalanceState.calculated]; во всех
/// остальных случаях числа нет и карточка показывает [message]. Возвращать
/// вместо этого нуль нельзя: «потерь 0» и «данных нет» — разные вещи.
class WaterBalance {
  final WaterBalanceState state;
  final int? accounts;
  final double? pumped;
  final double? realized;
  final bool pumpedIsManual;
  final bool realizedIsManual;
  final PumpedStatus pumpedStatus;
  final String? pumpedRaw;
  final String message;

  const WaterBalance._({
    required this.state,
    required this.pumpedStatus,
    this.accounts,
    this.pumped,
    this.realized,
    this.pumpedIsManual = false,
    this.realizedIsManual = false,
    this.pumpedRaw,
    this.message = '',
  });

  double? get losses =>
      state == WaterBalanceState.calculated ? pumped! - realized! : null;

  double? get lossPercent =>
      state == WaterBalanceState.calculated ? (pumped! - realized!) / pumped! * 100 : null;

  double? financialLoss(double tariff) {
    final l = losses;
    return l == null || tariff <= 0 ? null : l * tariff;
  }

  /// Цифра есть, но выглядит нереалистично — в UI идёт бейджем «Требует
  /// проверки», а не заменой числа.
  bool get needsReview =>
      state == WaterBalanceState.calculated && (lossPercent ?? 0) > 60;

  /// В сводку попадают только объекты с посчитанными потерями.
  bool get isValid => state == WaterBalanceState.calculated;

  /// Данные есть, но им нельзя верить: сводку по ним не считаем, но и
  /// «в норме» не рисуем.
  bool get isBroken =>
      state == WaterBalanceState.negativeRealized ||
      state == WaterBalanceState.realizedExceedsPumped;

  static WaterBalance compute({
    required WaterMonthEntry? entry,
    WaterOverride? override,
  }) {
    if (entry == null && (override == null || override.isEmpty)) {
      return const WaterBalance._(
        state: WaterBalanceState.noData,
        pumpedStatus: PumpedStatus.missing,
        message: 'Объекта нет в выгрузке за этот месяц',
      );
    }

    final manualPumped = override?.pumped;
    final manualRealized = override?.realized;
    final pumped = manualPumped ?? entry?.pumped;
    final realized = manualRealized ?? entry?.realized;
    final status = manualPumped != null
        ? PumpedStatus.ok
        : (entry?.pumpedStatus ?? PumpedStatus.missing);

    WaterBalance withState(WaterBalanceState state, String message) =>
        WaterBalance._(
          state: state,
          accounts: entry?.accounts,
          pumped: pumped,
          realized: realized,
          pumpedIsManual: manualPumped != null,
          realizedIsManual: manualRealized != null,
          pumpedStatus: status,
          pumpedRaw: entry?.pumpedRaw,
          message: message,
        );

    if (status != PumpedStatus.ok || pumped == null) {
      return withState(WaterBalanceState.noPumped, status.reason);
    }
    if (pumped <= 0) {
      return withState(
        WaterBalanceState.noPumped,
        'Нет данных: подъём равен нулю',
      );
    }
    if (realized == null) {
      return withState(
        WaterBalanceState.noRealized,
        'Нет данных: реализация в выгрузке не заполнена',
      );
    }
    if (realized < 0) {
      return withState(
        WaterBalanceState.negativeRealized,
        'Некорректные данные: отрицательная реализация (сторно)',
      );
    }
    if (realized > pumped) {
      return withState(
        WaterBalanceState.realizedExceedsPumped,
        'Реализация превышает подъём — данные требуют проверки',
      );
    }
    return withState(WaterBalanceState.calculated, '');
  }
}
