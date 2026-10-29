// lib/screens/water_losses_screen.dart
//
// Экран «Баланс воды / Потери»
// ──────────────────────────────────────────────────────────────────────────────
// Назначение:
//   Небаланс между объёмом поднятой воды и объёмом, реализованным абонентам.
//   Результат: потери в м³, % потерь, финансовые потери по тарифу.
//
// Источники данных:
//   • Датасет из квартальной выгрузки биллинга — assets/water_losses/*.json,
//     собирается скриптом tool/generate_water_losses.py. Список объектов
//     раздела строится ИМЕННО из него, а не из /Dashboard: названия ВЗУ в
//     выгрузке и в системе автоматически не сходятся, и часть ВЗУ в системе
//     отсутствует вовсе.
//   • Ручной ввод оператора — перекрывает выгрузку, хранится в
//     SharedPreferences per «объект × месяц».
//   • Тариф — ручной ввод (в выгрузке тарифа нет).
//
// Про честность цифр:
//   Колонка «поднято» заполнена меньше чем у половины объектов, а реализация
//   местами уходит в минус из-за сторно. Поэтому потери считаются только при
//   пригодных данных, а иначе карточка показывает причину — см. [WaterBalance].
//   Сводка суммирует только объекты с посчитанными потерями и подписывает,
//   по скольким объектам из скольких она получена.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/water_losses_dataset.dart';
import 'package:manage_center/screens/Boiler_detail_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/services/water_losses_repository.dart';
import 'package:manage_center/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Вспомогательные типы
// ═══════════════════════════════════════════════════════════════════════════════

/// Порядок карточек в списке.
enum _SortMode { lossesDesc, name, missingFirst }

extension _SortModeText on _SortMode {
  String get label {
    switch (this) {
      case _SortMode.lossesDesc:
        return 'По потерям';
      case _SortMode.name:
        return 'По названию';
      case _SortMode.missingFirst:
        return 'Сначала без данных';
    }
  }
}

/// Объект + его расчёт за выбранный месяц.
class _Row {
  final WaterNode node;
  final WaterBalance balance;

  /// ID объекта в системе, если название удалось сопоставить.
  final int? boilerId;

  /// Название объекта в системе (может отличаться от названия в выгрузке).
  final String? boilerName;

  const _Row({
    required this.node,
    required this.balance,
    this.boilerId,
    this.boilerName,
  });
}

/// Итоги по выборке.
class _Totals {
  final double pumped;
  final double realized;
  final int valid;
  final int total;
  final int needsReview;
  final int broken;
  final int noData;

  const _Totals({
    required this.pumped,
    required this.realized,
    required this.valid,
    required this.total,
    required this.needsReview,
    required this.broken,
    required this.noData,
  });

  double get losses => pumped - realized;
  double get lossPercent => pumped > 0 ? losses / pumped * 100 : 0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Главный виджет
// ═══════════════════════════════════════════════════════════════════════════════

class WaterLossesScreen extends StatefulWidget {
  const WaterLossesScreen({super.key});

  @override
  State<WaterLossesScreen> createState() => _WaterLossesScreenState();
}

class _WaterLossesScreenState extends State<WaterLossesScreen> {
  static const _monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  WaterLossesRepository? _repo;
  WaterLossesDataset? _dataset;

  bool _loading = true;
  String? _error;

  String? _period;
  double _tariff = 0;
  int? _districtFilter;
  _SortMode _sort = _SortMode.lossesDesc;

  /// Сопоставление «нормализованное имя из выгрузки» → объект в системе.
  /// Заполняется по возможности: если /Dashboard недоступен, раздел работает
  /// без переходов в карточки объектов.
  final Map<String, _MatchedBoiler> _matches = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await WaterLossesRepository.create();
      final dataset = await repo.loadDataset();
      if (!mounted) return;
      setState(() {
        _repo = repo;
        _dataset = dataset;
        _tariff = repo.tariff;
        // По умолчанию — последний месяц выгрузки.
        _period = dataset.periods.isEmpty ? null : dataset.periods.last;
        _loading = false;
      });
      _matchBoilers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить датасет выгрузки: $e';
        _loading = false;
      });
    }
  }

  /// Необязательная привязка к объектам системы — только чтобы показать
  /// иконку перехода в карточку. Ошибки глушим: раздел от API не зависит.
  Future<void> _matchBoilers() async {
    try {
      final boilers = await context.read<ApiService>().getBoilers();
      if (!mounted) return;
      final byKey = <String, _MatchedBoiler>{};
      for (final b in boilers) {
        byKey[normalizeNodeName(b.name)] = _MatchedBoiler(
          id: b.id,
          name: b.name,
          districtName: b.district.name,
        );
      }
      setState(() {
        _matches
          ..clear()
          ..addAll(byKey);
      });
    } catch (_) {
      // Молча: несопоставленные объекты всё равно показываются.
    }
  }

  // ── Выборка ───────────────────────────────────────────────────────────────
  List<_Row> get _rows {
    final dataset = _dataset;
    final period = _period;
    if (dataset == null || period == null) return const [];

    final rows = <_Row>[];
    for (final node in dataset.nodes) {
      if (_districtFilter != null && node.district != _districtFilter) continue;
      final match = _matches[node.key];
      rows.add(_Row(
        node: node,
        balance: WaterBalance.compute(
          entry: node.months[period],
          override: _repo?.readOverride(node.key, period),
        ),
        boilerId: match?.id,
        boilerName: match?.name,
      ));
    }

    switch (_sort) {
      case _SortMode.lossesDesc:
        // Объекты с цифрами — сверху по убыванию потерь, остальные — в конце.
        rows.sort((a, b) {
          final la = a.balance.losses;
          final lb = b.balance.losses;
          if (la == null && lb == null) return a.node.name.compareTo(b.node.name);
          if (la == null) return 1;
          if (lb == null) return -1;
          return lb.compareTo(la);
        });
      case _SortMode.name:
        rows.sort((a, b) => a.node.name.compareTo(b.node.name));
      case _SortMode.missingFirst:
        rows.sort((a, b) {
          final va = a.balance.isValid ? 1 : 0;
          final vb = b.balance.isValid ? 1 : 0;
          if (va != vb) return va - vb;
          return a.node.name.compareTo(b.node.name);
        });
    }
    return rows;
  }

  _Totals _totalsOf(List<_Row> rows) {
    double pumped = 0, realized = 0;
    int valid = 0, needsReview = 0, broken = 0, noData = 0;
    for (final r in rows) {
      final b = r.balance;
      if (b.isValid) {
        pumped += b.pumped!;
        realized += b.realized!;
        valid++;
        if (b.needsReview) needsReview++;
      } else if (b.isBroken) {
        broken++;
      } else {
        noData++;
      }
    }
    return _Totals(
      pumped: pumped,
      realized: realized,
      valid: valid,
      total: rows.length,
      needsReview: needsReview,
      broken: broken,
      noData: noData,
    );
  }

  // ── Оформление сводной панели ─────────────────────────────────────────────
  /// Сводка остаётся тёмной в обеих темах: белые цифры на ней читаются лучше
  /// всего, а светлая плашка во весь экран слепит ночью.
  List<Color> get _panelGradient {
    final colors = context.colors;
    return context.isDark
        ? [colors.surfaceContainer, colors.surfaceContainerLowest]
        : [
            Color.lerp(colors.primary, Colors.black, 0.28)!,
            Color.lerp(colors.primary, Colors.black, 0.55)!,
          ];
  }

  /// Цвет надписей поверх [_panelGradient].
  Color get _onPanel => Colors.white;

  /// Подписи делений у шкал потерь.
  TextStyle get _scaleLabelStyle =>
      TextStyle(fontSize: 9, color: context.colors.onSurfaceVariant);

  String _periodLabel(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return period;
    return '${_monthNames[month - 1]} ${parts[0]}';
  }

  String _periodShortLabel(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return period;
    return _monthNames[month - 1];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  PreferredSizeWidget _appBar() {
    final colors = context.colors;
    // Ночью синяя шапка во весь экран слепит — берём тёмную поверхность.
    final gradient = context.isDark
        ? [colors.surfaceContainer, colors.surfaceContainerHigh]
        : [colors.primary, Color.lerp(colors.primary, Colors.black, 0.25)!];
    final onHeader = context.isDark ? colors.onSurface : colors.onPrimary;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Баланс воды',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Потери при транспортировке',
              style: TextStyle(
                fontSize: 11,
                color: onHeader.withValues(alpha: 0.7),
              )),
        ],
      ),
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: onHeader,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.payments_outlined),
          tooltip: 'Тариф',
          onPressed: _dlgTariff,
        ),
        PopupMenuButton<_SortMode>(
          icon: const Icon(Icons.sort),
          tooltip: 'Сортировка',
          initialValue: _sort,
          onSelected: (v) => setState(() => _sort = v),
          itemBuilder: (_) => _SortMode.values
              .map((m) => PopupMenuItem(value: m, child: Text(m.label)))
              .toList(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Обновить',
          onPressed: _init,
        ),
      ],
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 56, color: context.colors.error),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.error)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _init,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );

  Widget _buildBody() {
    final rows = _rows;
    final totals = _totalsOf(rows);

    return RefreshIndicator(
      color: context.colors.primary,
      onRefresh: _init,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        children: [
          _buildPeriodBar(),
          const SizedBox(height: 10),
          _buildFilterBar(),
          const SizedBox(height: 10),
          _buildSummaryCard(totals),
          if (_tariff <= 0) ...[const SizedBox(height: 8), _buildTariffHint()],
          const SizedBox(height: 12),
          if (rows.isEmpty)
            _buildEmpty()
          else
            ...rows.map(_buildNodeCard),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.filter_alt_off,
                size: 44, color: context.colors.onSurfaceVariant),
            const SizedBox(height: 10),
            Text('Нет объектов по выбранному фильтру',
                style: TextStyle(color: context.colors.onSurfaceVariant)),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: выбор месяца
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPeriodBar() {
    final colors = context.colors;
    final dataset = _dataset!;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: context.isDark ? colors.surfaceContainer : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            context.isDark ? Border.all(color: colors.outlineVariant) : null,
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // Периоды — только те, что есть в выгрузке. Относительных
              // «текущий месяц / год» здесь быть не может: выгрузка за
              // I квартал, и такие периоды давали бы пустой экран.
              children: dataset.periods.map((p) {
                final sel = _period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      _periodLabel(p),
                      style: TextStyle(
                        fontSize: 12,
                        color: sel
                            ? AppTheme.onSolidAccent
                            : colors.onPrimaryContainer,
                      ),
                    ),
                    selected: sel,
                    showCheckmark: false,
                    selectedColor: AppTheme.solidAccent(colors.primary),
                    backgroundColor: colors.primaryContainer,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onSelected: (v) {
                      if (v) setState(() => _period = p);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 13, color: colors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dataset.source.isEmpty
                      ? 'Данные из выгрузки биллинга'
                      : 'Выгрузка: ${dataset.source}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: фильтр по ЭР и сортировка
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFilterBar() {
    final colors = context.colors;

    Widget chip(String label, int? district) {
      final sel = _districtFilter == district;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: sel ? AppTheme.onSolidAccent : colors.onSurfaceVariant,
            ),
          ),
          selected: sel,
          showCheckmark: false,
          selectedColor: AppTheme.solidAccent(colors.primary),
          backgroundColor:
              context.isDark ? colors.surfaceContainerHigh : colors.surface,
          side: BorderSide(color: colors.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onSelected: (v) =>
              setState(() => _districtFilter = v ? district : null),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Все ЭР', null),
                for (var d = 1; d <= 5; d++) chip('ЭР $d', d),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.sort, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(_sort.label,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: сводная карточка
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryCard(_Totals t) {
    final pct = t.lossPercent;
    final finLosses = t.losses * _tariff;
    // Сводка — тёмная панель в обеих темах, поэтому статусные цвета берём из
    // тёмной палитры: светлые варианты на ней не читаются.
    final accents = AppSemanticColors.dark;
    final hasData = t.valid > 0;
    final pctColor = !hasData
        ? _onPanel.withValues(alpha: 0.5)
        : pct <= 15
            ? accents.success
            : pct <= 25
                ? accents.warning
                : const Color(0xFFEF5350);
    final pctLabel = !hasData
        ? 'нет данных'
        : pct <= 15
            ? '✓ В норме'
            : pct <= 25
                ? '⚠ Повышенные'
                : '✗ Сверхнормативные';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _panelGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Охват данных: без этой строки сводка врёт ────────────────────
          _buildCoverage(t),
          const SizedBox(height: 12),
          // ── Три числа: поднято / реализовано / потери
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumItem('Поднято', hasData ? _fmtM3(t.pumped) : '—', 'м³',
                  const Color(0xFF90CAF9)),
              _vDivider(),
              _sumItem('Реализовано', hasData ? _fmtM3(t.realized) : '—', 'м³',
                  accents.success),
              _vDivider(),
              _sumItem('Потери', hasData ? _fmtM3(t.losses) : '—', 'м³',
                  const Color(0xFFEF9A9A)),
            ],
          ),
          const SizedBox(height: 14),
          // ── Процент + финансы
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _onPanel.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      hasData ? '${pct.toStringAsFixed(1)}%' : '—',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: pctColor),
                    ),
                    Text('Уровень потерь',
                        style: TextStyle(
                            fontSize: 10,
                            color: _onPanel.withValues(alpha: 0.55))),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: pctColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: pctColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(pctLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: pctColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                _panelDivider(56),
                Column(
                  children: [
                    Text(
                      _tariff > 0 && hasData ? '${_fmtRub(finLosses)} ₽' : '— ₽',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accents.warning),
                    ),
                    Text('Финансовые потери',
                        style: TextStyle(
                            fontSize: 10,
                            color: _onPanel.withValues(alpha: 0.55))),
                    if (_tariff > 0)
                      Text(
                        'тариф: ${_tariff.toStringAsFixed(2)} ₽/м³',
                        style: TextStyle(
                            fontSize: 9,
                            color: _onPanel.withValues(alpha: 0.4)),
                      ),
                  ],
                ),
                _panelDivider(56),
                Column(
                  children: [
                    Text(
                      '${t.valid}',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _onPanel),
                    ),
                    Text('объектов в расчёте',
                        style: TextStyle(
                            fontSize: 10,
                            color: _onPanel.withValues(alpha: 0.55))),
                    Text('из ${t.total}',
                        style: TextStyle(
                            fontSize: 9,
                            color: _onPanel.withValues(alpha: 0.4))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Шкала норматива
          _buildNormBar(hasData ? pct : null),
        ],
      ),
    );
  }

  /// Строка охвата: сколько объектов реально попало в сумму и почему остальные
  /// не попали. Суммировать статусные объекты как нули нельзя, поэтому охват
  /// обязан быть виден.
  Widget _buildCoverage(_Totals t) {
    final accents = AppSemanticColors.dark;
    final period = _period;

    final notes = <String>[];
    if (t.noData > 0) notes.add('${t.noData} без данных подъёма');
    if (t.broken > 0) notes.add('${t.broken} с некорректными цифрами');
    if (t.needsReview > 0) notes.add('${t.needsReview} требуют проверки');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _onPanel.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _onPanel.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 14, color: _onPanel),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Данные по ${t.valid} из ${t.total} объектов'
                  '${period == null ? '' : ' · ${_periodShortLabel(period)}'}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _onPanel),
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              notes.join(' · '),
              style: TextStyle(
                  fontSize: 10, color: accents.warning.withValues(alpha: 0.9)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panelDivider(double height) =>
      Container(width: 1, height: height, color: _onPanel.withValues(alpha: 0.12));

  Widget _vDivider() => _panelDivider(40);

  Widget _sumItem(String label, String value, String unit, Color color) =>
      Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(unit,
              style:
                  TextStyle(fontSize: 10, color: _onPanel.withValues(alpha: 0.4))),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: _onPanel.withValues(alpha: 0.6))),
        ],
      );

  /// [pct] == null — данных для расчёта нет, маркер не показываем.
  Widget _buildNormBar(double? pct) {
    final accents = AppSemanticColors.dark;
    const danger = Color(0xFFEF5350);
    final scaleLabel = TextStyle(
      color: _onPanel.withValues(alpha: 0.32),
      fontSize: 9,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Нормативный уровень потерь',
                style: TextStyle(
                    color: _onPanel.withValues(alpha: 0.4), fontSize: 10)),
            Row(
              children: [
                _NormChip(color: accents.success, label: '≤15%'),
                const SizedBox(width: 4),
                _NormChip(color: accents.warning, label: '15–25%'),
                const SizedBox(width: 4),
                const _NormChip(color: danger, label: '>25%'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [accents.success, accents.warning, danger],
                ),
              ),
            ),
            // Маркер позиции
            if (pct != null)
              Positioned(
                left: (MediaQuery.of(context).size.width - 56) *
                    (pct / 40).clamp(0, 1),
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _onPanel,
                    border: Border.all(color: _panelGradient.last, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: scaleLabel),
            Text('10%', style: scaleLabel),
            Text('20%', style: scaleLabel),
            Text('30%', style: scaleLabel),
            Text('40%+', style: scaleLabel),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: подсказка о тарифе
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTariffHint() {
    final appColors = context.appColors;
    return InkWell(
      onTap: _dlgTariff,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: appColors.warningContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appColors.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: appColors.onWarningContainer, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Тариф не задан — финансовые потери не рассчитаны. Нажмите, чтобы указать.',
                style:
                    TextStyle(fontSize: 12, color: appColors.onWarningContainer),
              ),
            ),
            Icon(Icons.chevron_right, color: appColors.onWarningContainer),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: карточка одного объекта
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNodeCard(_Row row) {
    final colors = context.colors;
    final appColors = context.appColors;
    final b = row.balance;
    final calculated = b.state == WaterBalanceState.calculated;

    // Объект без пригодных цифр не должен выглядеть «нормальным»: гасим акцент
    // заголовка, чтобы список читался с первого взгляда.
    final headerColor = calculated
        ? AppTheme.solidAccent(colors.primary)
        : b.isBroken
            ? AppTheme.solidAccent(colors.error)
            : AppTheme.solidAccent(appColors.archived);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Заголовок ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    calculated
                        ? Icons.water
                        : b.isBroken
                            ? Icons.report_gmailerrorred
                            : Icons.help_outline,
                    color: AppTheme.onSolidAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.node.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text(
                        _nodeSubtitle(row),
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Переход в карточку объекта — только если название сошлось
                // с объектом в системе.
                if (row.boilerId != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    color: colors.primary,
                    tooltip: 'Открыть объект «${row.boilerName}»',
                    onPressed: () => _openBoiler(row),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  )
                else
                  Tooltip(
                    message: 'Объект не сопоставлен с системой',
                    child: Icon(Icons.link_off,
                        size: 16,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Поднято / Реализовано ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _pumpedTile(row)),
                const SizedBox(width: 8),
                Expanded(child: _realizedTile(row)),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 10),

            // ── Потери или причина, по которой их нет ─────────────────────
            if (calculated) ..._lossBlock(row) else _statusBlock(row),
          ],
        ),
      ),
    );
  }

  String _nodeSubtitle(_Row row) {
    final parts = <String>[
      row.node.district != null ? 'ЭР ${row.node.district}' : 'ЭР не указан',
    ];
    final accounts = row.balance.accounts;
    if (accounts != null) parts.add('$accounts л/с');
    return parts.join(' · ');
  }

  void _openBoiler(_Row row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (ctx) => BoilerDetailBloc(
            apiService: ctx.read<ApiService>(),
            storageService: ctx.read<StorageService>(),
          ),
          child: BoilerDetailScreen(
            boilerId: row.boilerId!,
            boilerName: row.boilerName ?? row.node.name,
            districtName: _matches[row.node.key]?.districtName,
          ),
        ),
      ),
    );
  }

  // ── Плитка «Поднято» ──────────────────────────────────────────────────────
  Widget _pumpedTile(_Row row) {
    final b = row.balance;
    final colors = context.colors;
    final hasNumber = b.pumped != null && b.pumpedStatus == PumpedStatus.ok;

    return _metricTile(
      icon: Icons.arrow_circle_up,
      color: hasNumber ? colors.primary : colors.onSurfaceVariant,
      label: 'Поднято',
      value: hasNumber
          ? '${_fmtM3(b.pumped!)} м³'
          // Показываем именно то, что стояло в выгрузке: «нет ПУ», «байпас»…
          : (b.pumpedRaw ?? b.pumpedStatus.shortLabel),
      valueIsPlaceholder: !hasNumber,
      isManual: b.pumpedIsManual,
      onEdit: () => _dlgEditValue(row, isPumped: true),
      onReset: b.pumpedIsManual ? () => _resetValue(row, isPumped: true) : null,
    );
  }

  // ── Плитка «Реализовано» ──────────────────────────────────────────────────
  Widget _realizedTile(_Row row) {
    final b = row.balance;
    final colors = context.colors;
    final appColors = context.appColors;
    final v = b.realized;
    final negative = v != null && v < 0;

    return _metricTile(
      icon: Icons.people_alt_outlined,
      color: negative
          ? colors.error
          : v == null
              ? colors.onSurfaceVariant
              : appColors.success,
      label: 'Реализовано',
      value: v == null ? 'не заполнено' : '${_fmtM3(v)} м³',
      valueIsPlaceholder: v == null,
      valueColor: negative ? colors.error : null,
      isManual: b.realizedIsManual,
      onEdit: () => _dlgEditValue(row, isPumped: false),
      onReset:
          b.realizedIsManual ? () => _resetValue(row, isPumped: false) : null,
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onEdit,
    VoidCallback? onReset,
    bool isManual = false,
    bool valueIsPlaceholder = false,
    Color? valueColor,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.appColors.neutralSurface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isManual
              ? colors.primary.withValues(alpha: 0.55)
              : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 9, color: colors.onSurfaceVariant)),
                    if (isManual) ...[
                      const SizedBox(width: 4),
                      // Ручной ввод перекрывает выгрузку — это обязательно
                      // должно быть видно, иначе цифру не с чем сверить.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.solidAccent(colors.primary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('вручную',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSolidAccent)),
                      ),
                    ],
                  ],
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight:
                        valueIsPlaceholder ? FontWeight.w500 : FontWeight.w600,
                    fontSize: valueIsPlaceholder ? 11 : 13,
                    fontStyle:
                        valueIsPlaceholder ? FontStyle.italic : FontStyle.normal,
                    color: valueColor ??
                        (valueIsPlaceholder ? colors.onSurfaceVariant : null),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onReset != null)
            GestureDetector(
              onTap: onReset,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.restore,
                    size: 15, color: colors.onSurfaceVariant),
              ),
            ),
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined,
                size: 15, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  // ── Блок посчитанных потерь ───────────────────────────────────────────────
  List<Widget> _lossBlock(_Row row) {
    final colors = context.colors;
    final appColors = context.appColors;
    final b = row.balance;
    final pct = b.lossPercent!;
    final lossClr = pct <= 15
        ? appColors.success
        : pct <= 25
            ? appColors.warning
            : colors.error;
    final lossBg = pct <= 15
        ? appColors.successContainer
        : pct <= 25
            ? appColors.warningContainer
            : colors.errorContainer;
    final onLossBg = pct <= 15
        ? appColors.onSuccessContainer
        : pct <= 25
            ? appColors.onWarningContainer
            : colors.onErrorContainer;
    final fin = b.financialLoss(_tariff);

    return [
      Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: lossBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: lossClr.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Потери воды',
                          style: TextStyle(
                              fontSize: 10,
                              color: onLossBg.withValues(alpha: 0.8))),
                      Text(
                        '${_fmtM3(b.losses!)} м³',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: onLossBg),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.solidAccent(lossClr),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: AppTheme.onSolidAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (fin != null) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: appColors.warningContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: appColors.warning.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Убыток',
                        style: TextStyle(
                            fontSize: 10,
                            color: appColors.onWarningContainer
                                .withValues(alpha: 0.8))),
                    Text(
                      '${_fmtRub(fin)} ₽',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: appColors.onWarningContainer),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),

      // Потери выше 60% — почти всегда дефект источника, а не реальная утечка.
      // Цифру показываем, но не выдаём её за проверенную.
      if (b.needsReview) ...[
        const SizedBox(height: 8),
        _reviewBadge(
          'Требует проверки: потери ${pct.toStringAsFixed(0)}% — '
          'проверьте показания и привязку абонентов',
        ),
      ],

      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (pct / 40).clamp(0, 1),
          minHeight: 5,
          backgroundColor: colors.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(lossClr),
        ),
      ),
      const SizedBox(height: 2),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('0%', style: _scaleLabelStyle),
          Text('20%', style: _scaleLabelStyle),
          Text('40%+', style: _scaleLabelStyle),
        ],
      ),
    ];
  }

  Widget _reviewBadge(String text) {
    final appColors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appColors.warningContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 14, color: appColors.onWarningContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: appColors.onWarningContainer)),
          ),
        ],
      ),
    );
  }

  // ── Блок «числа нет, вот почему» ──────────────────────────────────────────
  Widget _statusBlock(_Row row) {
    final colors = context.colors;
    final appColors = context.appColors;
    final b = row.balance;

    // Некорректные данные — красным: это не «нет данных», а сигнал в биллинг.
    final isError = b.state == WaterBalanceState.negativeRealized;
    final isWarning = b.state == WaterBalanceState.realizedExceedsPumped;

    final bg = isError
        ? colors.errorContainer
        : isWarning
            ? appColors.warningContainer
            : appColors.archivedContainer;
    final fg = isError
        ? colors.onErrorContainer
        : isWarning
            ? appColors.onWarningContainer
            : appColors.onArchivedContainer;
    final icon = isError
        ? Icons.error_outline
        : isWarning
            ? Icons.warning_amber_rounded
            : Icons.do_not_disturb_on_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Потери не рассчитаны',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(b.message,
              style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.9))),
          if (b.state == WaterBalanceState.noPumped) ...[
            const SizedBox(height: 6),
            Text(
              'Введите объём подъёма вручную, чтобы объект попал в расчёт.',
              style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ДИАЛОГИ
  // ══════════════════════════════════════════════════════════════════════════

  /// Ввод / изменение тарифа
  void _dlgTariff() {
    final ctrl = TextEditingController(
        text: _tariff > 0 ? _tariff.toStringAsFixed(2) : '');
    _showInputDialog(
      title: 'Тариф на воду',
      icon: Icons.payments_outlined,
      iconColor: context.colors.primary,
      field: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        decoration: InputDecoration(
          labelText: 'Тариф',
          suffixText: '₽/м³',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.water_drop_outlined),
          helperText: 'Установленный тариф на 1 м³ питьевой воды',
        ),
      ),
      onSave: () async {
        final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
        await _repo?.saveTariff(v);
        if (mounted) setState(() => _tariff = v);
      },
    );
  }

  /// Ручной ввод «поднято» / «реализовано» за выбранный месяц.
  void _dlgEditValue(_Row row, {required bool isPumped}) {
    final period = _period;
    if (period == null) return;

    final b = row.balance;
    final current = isPumped ? b.pumped : b.realized;
    final imported = isPumped
        ? row.node.months[period]?.pumped
        : row.node.months[period]?.realized;
    final ctrl = TextEditingController(
        text: current == null ? '' : _plain(current));

    final importedNote = imported != null
        ? 'В выгрузке: ${_plain(imported)} м³'
        : isPumped
            ? 'В выгрузке: ${b.pumpedRaw ?? b.pumpedStatus.shortLabel}'
            : 'В выгрузке значения нет';

    _showInputDialog(
      title: isPumped ? 'Поднято воды' : 'Реализовано абонентам',
      subtitle: row.node.name,
      icon: isPumped ? Icons.arrow_circle_up : Icons.people_alt_outlined,
      iconColor:
          isPumped ? context.colors.primary : context.appColors.success,
      extraInfo: '${_periodLabel(period)} · $importedNote',
      field: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
            decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]'))
        ],
        decoration: InputDecoration(
          labelText: isPumped ? 'Поднято, м³' : 'Реализовано, м³',
          suffixText: 'м³',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(
              isPumped ? Icons.arrow_upward : Icons.people_outlined),
          helperText: isPumped
              ? 'Суммарный объём за месяц (1-й + 2-й подъём)'
              : 'Данные расчётного отдела / биллинга',
        ),
      ),
      saveColor:
          isPumped ? context.colors.primary : context.appColors.success,
      onSave: () async {
        final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
        await _writeOverride(row, period, isPumped: isPumped, value: v);
      },
    );
  }

  /// Сброс ручной правки к значению из выгрузки.
  Future<void> _resetValue(_Row row, {required bool isPumped}) async {
    final period = _period;
    if (period == null) return;
    await _writeOverride(row, period, isPumped: isPumped, value: null);
  }

  Future<void> _writeOverride(
    _Row row,
    String period, {
    required bool isPumped,
    required double? value,
  }) async {
    final repo = _repo;
    if (repo == null) return;
    final existing = repo.readOverride(row.node.key, period) ??
        const WaterOverride();
    final updated = isPumped
        ? (value == null
            ? existing.copyWith(dropPumped: true)
            : existing.copyWith(pumped: value))
        : (value == null
            ? existing.copyWith(dropRealized: true)
            : existing.copyWith(realized: value));
    await repo.writeOverride(row.node.key, period, updated);
    if (mounted) setState(() {});
  }

  /// Универсальный шаблон простого диалога с одним полем ввода
  void _showInputDialog({
    required String title,
    String? subtitle,
    String? extraInfo,
    required IconData icon,
    required Color iconColor,
    required Widget field,
    required Future<void> Function() onSave,
    String saveLabel = 'Сохранить',
    Color? saveColor,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (extraInfo != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appColors.neutralSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range,
                        size: 13, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(extraInfo,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.colors.onSurfaceVariant)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            field,
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.solidAccent(
                  saveColor ?? context.colors.primary),
              foregroundColor: AppTheme.onSolidAccent,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            onPressed: () async {
              await onSave();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(saveLabel),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ФОРМАТИРОВАНИЕ ЧИСЕЛ
  // ══════════════════════════════════════════════════════════════════════════
  String _fmtM3(double v) {
    final a = v.abs();
    if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} млн';
    if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)} тыс';
    return v.toStringAsFixed(1);
  }

  String _fmtRub(double v) {
    final a = v.abs();
    if (a >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} млн';
    if (a >= 1000) return '${(v / 1000).toStringAsFixed(1)} тыс';
    return v.toStringAsFixed(0);
  }

  /// Число без сокращений — для полей ввода и подписей «в выгрузке».
  String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

/// Объект системы, с которым сошлось название из выгрузки.
class _MatchedBoiler {
  final int id;
  final String name;
  final String districtName;

  const _MatchedBoiler({
    required this.id,
    required this.name,
    required this.districtName,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Вспомогательный виджет: чип нормы на легенде
// ═══════════════════════════════════════════════════════════════════════════════
class _NormChip extends StatelessWidget {
  final Color color;
  final String label;
  const _NormChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
