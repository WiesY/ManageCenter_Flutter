// lib/screens/water_losses_screen.dart
//
// Экран «Баланс воды / Потери»
// ──────────────────────────────────────────────────────────────────────────────
// Назначение:
//   Расчёт небаланса между объёмом поднятой воды (1-й и 2-й подъём ВЗУ)
//   и объёмом воды, реализованной абонентам.
//   Результат: потери в м³, % потерь, финансовые потери по тарифу.
//
// Источники данных:
//   • «Поднято» — автоматически из API (счётчики расхода, параметры SCADA)
//                 или ручной ввод, если параметры не подключены.
//   • «Реализовано» — ручной ввод из данных биллинга / расчётного отдела.
//   • Тариф — ручной ввод, сохраняется в SharedPreferences.
//
// Подключение к навигации:
//   Добавьте пункт в BottomNavigationBar / Drawer, например:
//     NavigationDestination(icon: Icon(Icons.water_drop), label: 'Баланс воды')
//   И в соответствующем switch-case:
//     case 3: return const WaterLossesScreen();
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Вспомогательные модели
// ═══════════════════════════════════════════════════════════════════════════════

/// Конфигурация одного ВЗУ — хранится в SharedPreferences
class _NodeConfig {
  final int boilerId;
  int? param1LiftId;    // ID параметра «Расход / счётчик 1-й подъём»
  int? param2LiftId;    // ID параметра «Расход / счётчик 2-й подъём» (необяз.)
  double manualPumped;  // Ручной ввод «поднято», м³
  double realized;      // Реализовано абонентам, м³

  _NodeConfig({
    required this.boilerId,
    this.param1LiftId,
    this.param2LiftId,
    this.manualPumped = 0,
    this.realized = 0,
  });

  Map<String, dynamic> toJson() => {
    'boilerId': boilerId,
    'param1LiftId': param1LiftId,
    'param2LiftId': param2LiftId,
    'manualPumped': manualPumped,
    'realized': realized,
  };

  factory _NodeConfig.fromJson(Map<String, dynamic> j) => _NodeConfig(
    boilerId: j['boilerId'] as int,
    param1LiftId: j['param1LiftId'] as int?,
    param2LiftId: j['param2LiftId'] as int?,
    manualPumped: (j['manualPumped'] ?? 0).toDouble(),
    realized: (j['realized'] ?? 0).toDouble(),
  );
}

/// Расчётные данные одного ВЗУ — живёт только в памяти
class _NodeData {
  final BoilerListItem boiler;
  final _NodeConfig config;
  double pumped;
  bool pumpedFromApi;
  bool isLoading;
  String? loadError;

  _NodeData({
    required this.boiler,
    required this.config,
    this.pumped = 0,
    this.pumpedFromApi = false,
    this.isLoading = false,
    this.loadError,
  });

  double get realized     => config.realized;
  double get losses       => pumped > realized ? pumped - realized : 0;
  double get lossPercent  => pumped > 0 ? (losses / pumped * 100) : 0;
  double financialLoss(double tariff) => losses * tariff;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Перечисление периодов
// ═══════════════════════════════════════════════════════════════════════════════

enum _Period { currentMonth, previousMonth, currentYear, custom }

extension _PeriodExt on _Period {
  String get label {
    switch (this) {
      case _Period.currentMonth:   return 'Тек. месяц';
      case _Period.previousMonth:  return 'Пред. месяц';
      case _Period.currentYear:    return 'Тек. год';
      case _Period.custom:         return 'Период…';
    }
  }
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
  // ── SharedPreferences ключи ────────────────────────────────────────────────
  static const _kTariff  = 'wl_tariff';
  static const _kCfgPfx  = 'wl_cfg_';

  // ── Состояние ─────────────────────────────────────────────────────────────
  List<_NodeData> _nodes = [];
  bool   _loading = true;
  String? _error;

  double _tariff  = 0;
  _Period _period = _Period.currentMonth;
  DateTimeRange? _customRange;

  late ApiService     _api;
  late StorageService _storage;
  SharedPreferences?  _prefs;

  // ── Инициализация ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _api     = context.read<ApiService>();
    _storage = context.read<StorageService>();
    _init();
  }

  Future<void> _init() async {
    _prefs  = await SharedPreferences.getInstance();
    _tariff = _prefs!.getDouble(_kTariff) ?? 0;
    await _loadNodes();
  }

  // ── Диапазон дат периода ──────────────────────────────────────────────────
  DateTimeRange _range() {
    final n = DateTime.now();
    switch (_period) {
      case _Period.currentMonth:
        return DateTimeRange(
          start: DateTime(n.year, n.month, 1),
          end: DateTime(n.year, n.month + 1, 1).subtract(const Duration(seconds: 1)),
        );
      case _Period.previousMonth:
        final pm = n.month == 1 ? 12 : n.month - 1;
        final py = n.month == 1 ? n.year - 1 : n.year;
        return DateTimeRange(
          start: DateTime(py, pm, 1),
          end: DateTime(py, pm + 1, 1).subtract(const Duration(seconds: 1)),
        );
      case _Period.currentYear:
        return DateTimeRange(
          start: DateTime(n.year, 1, 1),
          end: DateTime(n.year, 12, 31, 23, 59, 59),
        );
      case _Period.custom:
        return _customRange ?? DateTimeRange(start: DateTime(n.year, n.month, 1), end: n);
    }
  }

  // ── Загрузка списка объектов ──────────────────────────────────────────────
  Future<void> _loadNodes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token   = await _storage.getToken() ?? '';
      final boilers = await _api.getBoilers(token);

      setState(() {
        _nodes = boilers.map((b) {
          final cfg = _loadCfg(b.id);
          return _NodeData(
            boiler:       b,
            config:       cfg,
            pumped:       cfg.manualPumped,
            pumpedFromApi: false,
          );
        }).toList();
        _loading = false;
      });

      // Авто-загрузка API для настроенных объектов
      for (final nd in _nodes) {
        if (nd.config.param1LiftId != null) _fetchApi(nd);
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Загрузка данных из API (счётчик расхода) ──────────────────────────────
  Future<void> _fetchApi(_NodeData nd) async {
    setState(() { nd.isLoading = true; nd.loadError = null; });
    try {
      final token = await _storage.getToken() ?? '';
      final r     = _range();
      double v1   = 0, v2 = 0;

      if (nd.config.param1LiftId != null) {
        final vals = await _api.getParameterHistoryValues(
          token, nd.boiler.id, nd.config.param1LiftId!, r.start, r.end, 60,
        );
        v1 = _deltaFromHistory(vals);
      }
      if (nd.config.param2LiftId != null) {
        final vals = await _api.getParameterHistoryValues(
          token, nd.boiler.id, nd.config.param2LiftId!, r.start, r.end, 60,
        );
        v2 = _deltaFromHistory(vals);
      }

      setState(() {
        nd.pumped       = v1 + v2;
        nd.pumpedFromApi = true;
        nd.isLoading    = false;
      });
    } catch (e) {
      setState(() {
        nd.isLoading  = false;
        nd.loadError  = 'Ошибка загрузки данных счётчика';
      });
    }
  }

  /// Разница «последнее − первое» для накопительного счётчика
  double _deltaFromHistory(List<dynamic> vals) {
    if (vals.isEmpty) return 0;
    final first = double.tryParse(vals.first.value?.toString() ?? '') ?? 0;
    final last  = double.tryParse(vals.last.value?.toString()  ?? '') ?? 0;
    return (last - first).abs();
  }

  // ── SharedPreferences: конфиги ────────────────────────────────────────────
  _NodeConfig _loadCfg(int id) {
    final raw = _prefs?.getString('$_kCfgPfx$id');
    if (raw != null) {
      try { return _NodeConfig.fromJson(jsonDecode(raw)); } catch (_) {}
    }
    return _NodeConfig(boilerId: id);
  }

  Future<void> _saveCfg(_NodeConfig cfg) async {
    await _prefs?.setString('$_kCfgPfx${cfg.boilerId}', jsonEncode(cfg.toJson()));
  }

  Future<void> _saveTariff(double v) async {
    await _prefs?.setDouble(_kTariff, v);
    setState(() => _tariff = v);
  }

  // ── Итоговые значения ─────────────────────────────────────────────────────
  double get _totalPumped   => _nodes.fold(0, (s, n) => s + n.pumped);
  double get _totalRealized => _nodes.fold(0, (s, n) => s + n.realized);
  double get _totalLosses   => _nodes.fold(0, (s, n) => s + n.losses);
  double get _avgLossPct    => _totalPumped > 0 ? _totalLosses / _totalPumped * 100 : 0;

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _appBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Баланс воды', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        Text('Потери при транспортировке', style: TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    ),
    automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    actions: [
      IconButton(
        icon: const Icon(Icons.payments_outlined),
        tooltip: 'Тариф',
        onPressed: _dlgTariff,
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Обновить',
        onPressed: _loadNodes,
      ),
    ],
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNodes,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    ),
  );

  Widget _buildBody() {
    return RefreshIndicator(
      color: Colors.blue.shade600,
      onRefresh: _loadNodes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        children: [
          _buildPeriodBar(),
          const SizedBox(height: 10),
          _buildSummaryCard(),
          if (_tariff <= 0) ...[const SizedBox(height: 8), _buildTariffHint()],
          const SizedBox(height: 12),
          ..._nodes.map(_buildNodeCard),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: выбор периода
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPeriodBar() {
    final fmt = DateFormat('dd.MM.yy');
    final r   = _range();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.blue.shade100.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _Period.values.map((p) {
                final sel = _period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(p.label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.blue.shade700)),
                    selected: sel,
                    selectedColor: Colors.blue.shade700,
                    backgroundColor: Colors.blue.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onSelected: (v) async {
                      if (!v) return;
                      if (p == _Period.custom) {
                        final res = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _customRange,
                          locale: const Locale('ru'),
                        );
                        if (res != null) {
                          setState(() { _period = p; _customRange = res; });
                          _reloadAll();
                        }
                      } else {
                        setState(() => _period = p);
                        _reloadAll();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.date_range, size: 13, color: Colors.blue.shade500),
              const SizedBox(width: 4),
              Text(
                '${fmt.format(r.start)}  —  ${fmt.format(r.end)}',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _reloadAll() {
    for (final nd in _nodes) {
      if (nd.config.param1LiftId != null) _fetchApi(nd);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: сводная карточка
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryCard() {
    final pct       = _avgLossPct;
    final finLosses = _totalLosses * _tariff;
    final pctColor  = pct <= 15
        ? Colors.greenAccent.shade400
        : pct <= 25
            ? Colors.orangeAccent
            : Colors.redAccent;
    final pctLabel  = pct <= 15 ? '✓ В норме' : pct <= 25 ? '⚠ Повышенные' : '✗ Сверхнормативные';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.blue.shade900.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // ── Три числа: поднято / реализовано / потери
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumItem('Поднято',      _fmtM3(_totalPumped),   'м³', Colors.blue.shade200),
              _vDivider(),
              _sumItem('Реализовано',  _fmtM3(_totalRealized), 'м³', Colors.green.shade300),
              _vDivider(),
              _sumItem('Потери',       _fmtM3(_totalLosses),   'м³', Colors.red.shade300),
            ],
          ),
          const SizedBox(height: 14),
          // ── Процент + финансы
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: pctColor),
                    ),
                    Text('Уровень потерь', style: TextStyle(fontSize: 10, color: Colors.white54)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: pctColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: pctColor.withOpacity(0.4)),
                      ),
                      child: Text(pctLabel, style: TextStyle(fontSize: 10, color: pctColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Container(width: 1, height: 56, color: Colors.white12),
                Column(
                  children: [
                    Text(
                      _tariff > 0 ? '${_fmtRub(finLosses)} ₽' : '— ₽',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                    Text('Финансовые потери', style: TextStyle(fontSize: 10, color: Colors.white54)),
                    if (_tariff > 0)
                      Text(
                        'тариф: ${_tariff.toStringAsFixed(2)} ₽/м³',
                        style: TextStyle(fontSize: 9, color: Colors.white38),
                      ),
                  ],
                ),
                Container(width: 1, height: 56, color: Colors.white12),
                Column(
                  children: [
                    Text(
                      '${_nodes.length}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text('объектов ВЗУ', style: TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Шкала норматива
          _buildNormBar(pct),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 40, color: Colors.white12);

  Widget _sumItem(String label, String value, String unit, Color color) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(unit,  style: const TextStyle(fontSize: 10, color: Colors.white38)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
    ],
  );

  Widget _buildNormBar(double pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Нормативный уровень потерь', style: TextStyle(color: Colors.white38, fontSize: 10)),
            const Row(
              children: [
                _NormChip(color: Colors.green,  label: '≤15%'),
                SizedBox(width: 4),
                _NormChip(color: Colors.orange, label: '15–25%'),
                SizedBox(width: 4),
                _NormChip(color: Colors.red,    label: '>25%'),
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
                gradient: const LinearGradient(colors: [Colors.green, Colors.orange, Colors.red]),
              ),
            ),
            // Маркер позиции
            Positioned(
              left: (MediaQuery.of(context).size.width - 56) * (pct / 40).clamp(0, 1),
              top: -2,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.blue.shade900, width: 2),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%',  style: TextStyle(color: Colors.white30, fontSize: 9)),
            Text('10%', style: TextStyle(color: Colors.white30, fontSize: 9)),
            Text('20%', style: TextStyle(color: Colors.white30, fontSize: 9)),
            Text('30%', style: TextStyle(color: Colors.white30, fontSize: 9)),
            Text('40%+', style: TextStyle(color: Colors.white30, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: подсказка о тарифе
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTariffHint() => InkWell(
    onTap: _dlgTariff,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Тариф не задан — финансовые потери не рассчитаны. Нажмите, чтобы указать.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.orange.shade600),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // БЛОК: карточка одного объекта
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNodeCard(_NodeData nd) {
    final pct      = nd.lossPercent;
    final lossClr  = pct <= 15 ? Colors.green.shade600 : pct <= 25 ? Colors.orange.shade700 : Colors.red.shade600;
    final lossBg   = pct <= 15 ? Colors.green.shade50  : pct <= 25 ? Colors.orange.shade50  : Colors.red.shade50;

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
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.water, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nd.boiler.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(nd.boiler.district.name,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                // Статус источника данных
                if (nd.isLoading)
                  SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade400))
                else if (nd.pumpedFromApi)
                  Tooltip(
                    message: 'Поднято загружено из SCADA',
                    child: Icon(Icons.cloud_done, color: Colors.blue.shade400, size: 16),
                  )
                else
                  Tooltip(
                    message: 'Ручной ввод',
                    child: Icon(Icons.edit_note, color: Colors.grey.shade400, size: 16),
                  ),
                // Кнопка настроек
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  color: Colors.grey.shade500,
                  tooltip: 'Настройка параметров счётчиков',
                  onPressed: () => _dlgSettings(nd),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),

            if (nd.loadError != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 13, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(nd.loadError!, style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // ── Поднято / Реализовано ─────────────────────────────────────
            Row(
              children: [
                Expanded(child: _metricTile(
                  icon:  Icons.arrow_circle_up,
                  color: Colors.blue.shade600,
                  label: nd.config.param1LiftId != null ? 'Поднято (SCADA)' : 'Поднято',
                  value: '${_fmtM3(nd.pumped)} м³',
                  onEdit: nd.config.param1LiftId == null ? () => _dlgEditPumped(nd) : null,
                )),
                const SizedBox(width: 8),
                Expanded(child: _metricTile(
                  icon:  Icons.people_alt_outlined,
                  color: Colors.green.shade600,
                  label: 'Реализовано',
                  value: '${_fmtM3(nd.realized)} м³',
                  onEdit: () => _dlgEditRealized(nd),
                )),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 10),

            // ── Потери ────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: lossBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: lossClr.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Потери воды', style: TextStyle(fontSize: 10, color: lossClr.withOpacity(0.8))),
                            Text(
                              '${_fmtM3(nd.losses)} м³',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: lossClr),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lossClr,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_tariff > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Убыток', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                          Text(
                            '${_fmtRub(nd.financialLoss(_tariff))} ₽',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // ── Полоса прогресса ─────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 40).clamp(0, 1),
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(lossClr),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%',   style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                Text('20%',  style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                Text('40%+', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit_outlined, size: 15, color: color.withOpacity(0.7)),
              ),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // ДИАЛОГИ
  // ══════════════════════════════════════════════════════════════════════════

  /// Ввод / изменение тарифа
  void _dlgTariff() {
    final ctrl = TextEditingController(text: _tariff > 0 ? _tariff.toStringAsFixed(2) : '');
    _showInputDialog(
      title: 'Тариф на воду',
      icon: Icons.payments_outlined,
      iconColor: Colors.blue.shade600,
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
        await _saveTariff(v);
      },
    );
  }

  /// Ручной ввод «поднято» (если не подключены счётчики SCADA)
  void _dlgEditPumped(_NodeData nd) {
    final ctrl = TextEditingController(
        text: nd.pumped > 0 ? nd.pumped.toStringAsFixed(1) : '');
    _showInputDialog(
      title: 'Поднято воды',
      subtitle: nd.boiler.name,
      icon: Icons.arrow_circle_up,
      iconColor: Colors.blue.shade600,
      field: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        decoration: InputDecoration(
          labelText: 'Объём поднятой воды, м³',
          suffixText: 'м³',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.arrow_upward),
          helperText: 'Суммарный объём за выбранный период (1-й + 2-й подъём)',
        ),
      ),
      onSave: () async {
        final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
        nd.config.manualPumped = v;
        await _saveCfg(nd.config);
        setState(() => nd.pumped = v);
      },
    );
  }

  /// Ввод «реализовано» (из биллинга)
  void _dlgEditRealized(_NodeData nd) {
    final ctrl = TextEditingController(
        text: nd.realized > 0 ? nd.realized.toStringAsFixed(1) : '');
    final r   = _range();
    final fmt = DateFormat('dd.MM.yy');
    _showInputDialog(
      title: 'Реализовано абонентам',
      subtitle: nd.boiler.name,
      icon: Icons.people_alt_outlined,
      iconColor: Colors.green.shade600,
      extraInfo: '${fmt.format(r.start)} — ${fmt.format(r.end)}',
      field: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        decoration: InputDecoration(
          labelText: 'Реализовано, м³',
          suffixText: 'м³',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: const Icon(Icons.people_outlined),
          helperText: 'Данные из расчётного отдела / биллинговой системы',
        ),
      ),
      saveLabel: 'Сохранить',
      saveColor: Colors.green.shade600,
      onSave: () async {
        final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
        nd.config.realized = v;
        await _saveCfg(nd.config);
        setState(() {});
      },
    );
  }

  /// Настройка ID параметров счётчиков (SCADA)
  void _dlgSettings(_NodeData nd) {
    final ctrl1 = TextEditingController(text: nd.config.param1LiftId?.toString() ?? '');
    final ctrl2 = TextEditingController(text: nd.config.param2LiftId?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Параметры счётчиков', style: TextStyle(fontSize: 15)),
                  Text(nd.boiler.name, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ID параметра можно найти в разделе\n«Параметры объекта» → нужный счётчик.',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl1,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'ID счётчика  «1-й подъём»',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.looks_one_outlined),
                helperText: 'Суммарный расход насосов 1-го подъёма',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl2,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'ID счётчика «2-й подъём» (необяз.)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.looks_two_outlined),
                helperText: 'Суммарный расход насосов 2-го подъёма',
              ),
            ),
            const SizedBox(height: 6),
            // Если параметры заданы — показываем кнопку сброса
            if (nd.config.param1LiftId != null)
              TextButton.icon(
                onPressed: () async {
                  nd.config.param1LiftId = null;
                  nd.config.param2LiftId = null;
                  nd.pumpedFromApi = false;
                  await _saveCfg(nd.config);
                  setState(() {});
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.link_off, size: 14),
                label: const Text('Отвязать счётчики', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            onPressed: () async {
              nd.config.param1LiftId = int.tryParse(ctrl1.text);
              nd.config.param2LiftId = int.tryParse(ctrl2.text);
              await _saveCfg(nd.config);
              Navigator.pop(ctx);
              if (nd.config.param1LiftId != null) _fetchApi(nd);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
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
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(extraInfo, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            field,
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: saveColor ?? Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} млн';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)} тыс';
    return v.toStringAsFixed(1);
  }

  String _fmtRub(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} млн';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)} тыс';
    return v.toStringAsFixed(0);
  }
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
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }
}