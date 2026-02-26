// parameter_chart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:manage_center/bloc/parameter_chart_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'dart:math' as math;

// ==================== ЦВЕТА ====================

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFE53E3E);
  static const warning = Color(0xFFFF8C00);
  static const success = Color(0xFF38A169);
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const chartPrimary = Color(0xFF2E7D32);
  static const chartSecondary = Color(0xFF81C784);
}

const List<Color> _multiColors = [
  Color(0xFF2E7D32),
  Color(0xFFFF5722),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFFFF9800),
  Color(0xFF00BCD4),
  Color(0xFFE91E63),
  Color(0xFF607D8B),
];

// ==================== МОДЕЛИ ====================

enum ChartDataType { numeric, boolean, unknown }

class ChartValue {
  final double numericValue;
  final String displayValue;
  final String originalValue;
  final ChartDataType type;
  final DateTime timestamp;

  ChartValue({
    required this.numericValue,
    required this.displayValue,
    required this.originalValue,
    required this.type,
    required this.timestamp,
  });
}

enum TimePeriod { hour, day, week, month, custom }

extension TimePeriodExtension on TimePeriod {
  String get displayName {
    switch (this) {
      case TimePeriod.hour:
        return '1 час';
      case TimePeriod.day:
        return '1 день';
      case TimePeriod.week:
        return '1 неделя';
      case TimePeriod.month:
        return '1 месяц';
      case TimePeriod.custom:
        return 'Период';
    }
  }

  Duration get duration {
    switch (this) {
      case TimePeriod.hour:
        return const Duration(hours: 1);
      case TimePeriod.day:
        return const Duration(days: 1);
      case TimePeriod.week:
        return const Duration(days: 7);
      case TimePeriod.month:
        return const Duration(days: 30);
      case TimePeriod.custom:
        return const Duration(days: 7);
    }
  }

  int get interval {
    switch (this) {
      case TimePeriod.hour:
        return 5;
      case TimePeriod.day:
        return 60;
      case TimePeriod.week:
        return 480;
      case TimePeriod.month:
        return 1440;
      case TimePeriod.custom:
        return 60;
    }
  }

  IconData get icon {
    switch (this) {
      case TimePeriod.hour:
        return Icons.access_time;
      case TimePeriod.day:
        return Icons.today;
      case TimePeriod.week:
        return Icons.date_range;
      case TimePeriod.month:
        return Icons.calendar_month;
      case TimePeriod.custom:
        return Icons.tune;
    }
  }
}

class IntervalOption {
  final String title;
  final String subtitle;
  final int interval;
  final IconData icon;

  IntervalOption({
    required this.title,
    required this.subtitle,
    required this.interval,
    required this.icon,
  });
}

// ==================== ЭКРАН ====================

class ParameterChartScreen extends StatefulWidget {
  final int boilerId;
  final String boilerName;
  final BoilerParameter parameter;
  final List<BoilerParameter>? additionalParameters;

  const ParameterChartScreen({
    super.key,
    required this.boilerId,
    required this.boilerName,
    required this.parameter,
    this.additionalParameters,
  });

  @override
  State<ParameterChartScreen> createState() => _ParameterChartScreenState();
}

class _ParameterChartScreenState extends State<ParameterChartScreen>
    with TickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.day;
  List<BoilerParameterValue> _chartData = [];
  List<ChartValue> _processedData = [];
  Map<int, List<ChartValue>> _processedMultiData = {};
  ChartDataType _dataType = ChartDataType.unknown;
  bool _isLoading = false;

  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int _customInterval = 60;

  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  late ParameterChartBloc _parameterChartBloc;

  // Зум
  double _zoomLevel = 1.0;
  double _zoomOffset = 0.0; // 0..1 — позиция центра зума
  bool get _isZoomed => _zoomLevel > 1.05;

  List<BoilerParameter> get _allParameters {
    final list = [widget.parameter];
    if (widget.additionalParameters != null) {
      list.addAll(widget.additionalParameters!);
    }
    return list;
  }

  bool get _isMultiParam => _allParameters.length > 1;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    _parameterChartBloc = ParameterChartBloc(
      apiService: context.read<ApiService>(),
      storageService: context.read<StorageService>(),
    );

    _loadChartData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _parameterChartBloc.close();
    super.dispose();
  }

  // ==================== ОБРАБОТКА ДАННЫХ ====================

  List<ChartValue> _processChartData(List<BoilerParameterValue> rawData) {
    if (rawData.isEmpty) return [];

    bool hasNumeric = false;
    bool hasBoolean = false;

    for (var item in rawData) {
      final v = item.value.trim().toLowerCase();
      if (v == 'true' || v == 'false') hasBoolean = true;
      if (double.tryParse(item.value) != null) hasNumeric = true;
    }

    ChartDataType detectedType;
    if (hasBoolean && !hasNumeric) {
      detectedType = ChartDataType.boolean;
    } else if (hasNumeric) {
      detectedType = ChartDataType.numeric;
    } else {
      detectedType = ChartDataType.unknown;
    }

    _dataType = detectedType;

    return rawData.map((item) {
      final v = item.value.trim().toLowerCase();
      double numericValue = 0;
      String displayValue = item.value;

      switch (detectedType) {
        case ChartDataType.boolean:
          final isTrue = v == 'true' || v == '1';
          numericValue = isTrue ? 1.0 : 0.0;
          displayValue = isTrue ? 'Да' : 'Нет';
          break;
        case ChartDataType.numeric:
        case ChartDataType.unknown:
          final parsed = double.tryParse(item.value);
          if (parsed != null) {
            numericValue = parsed;
            displayValue = _formatNumericValue(parsed);
          }
          break;
      }

      return ChartValue(
        numericValue: numericValue,
        displayValue: displayValue,
        originalValue: item.value,
        type: detectedType,
        timestamp: item.receiptDate,
      );
    }).toList();
  }

  String _formatNumericValue(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  // ==================== ЗАГРУЗКА ====================

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    _refreshController.forward().then((_) => _refreshController.reverse());

    // Сброс зума
    _zoomLevel = 1.0;
    _zoomOffset = 0.5;

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    int interval;

    if (_selectedPeriod == TimePeriod.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      startDate = _customStartDate!;
      endDate = _customEndDate!;
      interval = _customInterval;
    } else {
      startDate = now.subtract(_selectedPeriod.duration);
      endDate = now;
      interval = _selectedPeriod.interval;
    }

    if (_isMultiParam) {
      _parameterChartBloc.add(LoadMultipleParameterValues(
        boilerId: widget.boilerId,
        parameterIds: _allParameters.map((p) => p.id).toList(),
        startDate: startDate,
        endDate: endDate,
        interval: interval,
      ));
    } else {
      _parameterChartBloc.add(LoadParameterValues(
        boilerId: widget.boilerId,
        parameterId: widget.parameter.id,
        startDate: startDate,
        endDate: endDate,
        interval: interval,
      ));
    }
  }

  // ==================== КАСТОМНЫЙ ДИАПАЗОН ====================

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final selectedInterval = await _showIntervalDialog(picked);
      if (selectedInterval != null) {
        setState(() {
          _customStartDate = picked.start;
          _customEndDate = picked.end
              .add(const Duration(hours: 23, minutes: 59, seconds: 59));
          _customInterval = selectedInterval;
          _selectedPeriod = TimePeriod.custom;
        });
        _loadChartData();
      }
    }
  }

  Future<int?> _showIntervalDialog(DateTimeRange dateRange) async {
    final duration =
        dateRange.end.difference(dateRange.start) + const Duration(days: 1);
    final intervals = _getIntervalOptions(duration);
    final recommended = _getRecommendedInterval(duration);
    int selected = recommended;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text('Настройка интервала',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Период: ${DateFormat('dd.MM.yyyy').format(dateRange.start)} - ${DateFormat('dd.MM.yyyy').format(dateRange.end)}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Длительность: ${duration.inDays} дн.',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Выберите интервал сбора данных:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    ...intervals.map((opt) {
                      final isRec = opt.interval == recommended;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isRec
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.transparent,
                          ),
                          color: isRec
                              ? AppColors.primary.withOpacity(0.05)
                              : null,
                        ),
                        child: RadioListTile<int>(
                          title: Row(
                            children: [
                              Icon(opt.icon,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(opt.title),
                              if (isRec) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Рекомендуется',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${opt.subtitle}\n≈ ${_estimateDataPoints(duration, opt.interval)} точек данных',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          value: opt.interval,
                          groupValue: selected,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setDialogState(() => selected = v!),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Применить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<IntervalOption> _getIntervalOptions(Duration duration) {
    if (duration.inHours <= 24) {
      return [
        IntervalOption(title: 'Каждые 5 минут', subtitle: 'Высокая детализация', interval: 5, icon: Icons.schedule),
        IntervalOption(title: 'Каждые 15 минут', subtitle: 'Средняя детализация', interval: 15, icon: Icons.access_time),
        IntervalOption(title: 'Каждые 30 минут', subtitle: 'Низкая детализация', interval: 30, icon: Icons.hourglass_empty),
        IntervalOption(title: 'Каждый час', subtitle: 'Минимальная детализация', interval: 60, icon: Icons.watch_later),
      ];
    } else if (duration.inDays <= 7) {
      return [
        IntervalOption(title: 'Каждые 5 минут', subtitle: 'Максимальная детализация', interval: 5, icon: Icons.timer),
        IntervalOption(title: 'Каждые 15 минут', subtitle: 'Высокая детализация', interval: 15, icon: Icons.schedule),
        IntervalOption(title: 'Каждые 30 минут', subtitle: 'Средняя детализация', interval: 30, icon: Icons.access_time),
        IntervalOption(title: 'Каждый час', subtitle: 'Низкая детализация', interval: 60, icon: Icons.watch_later),
        IntervalOption(title: 'Каждые 4 часа', subtitle: 'Минимальная детализация', interval: 240, icon: Icons.hourglass_full),
      ];
    } else if (duration.inDays <= 30) {
      return [
        IntervalOption(title: 'Каждые 30 минут', subtitle: 'Максимальная детализация', interval: 30, icon: Icons.timer),
        IntervalOption(title: 'Каждый час', subtitle: 'Высокая детализация', interval: 60, icon: Icons.schedule),
        IntervalOption(title: 'Каждые 4 часа', subtitle: 'Средняя детализация', interval: 240, icon: Icons.access_time),
        IntervalOption(title: 'Каждые 12 часов', subtitle: 'Низкая детализация', interval: 720, icon: Icons.watch_later),
        IntervalOption(title: 'Каждый день', subtitle: 'Минимальная детализация', interval: 1440, icon: Icons.today),
      ];
    } else {
      return [
        IntervalOption(title: 'Каждый час', subtitle: 'Максимальная детализация', interval: 60, icon: Icons.timer),
        IntervalOption(title: 'Каждые 4 часа', subtitle: 'Высокая детализация', interval: 240, icon: Icons.schedule),
        IntervalOption(title: 'Каждые 12 часов', subtitle: 'Средняя детализация', interval: 720, icon: Icons.access_time),
        IntervalOption(title: 'Каждый день', subtitle: 'Низкая детализация', interval: 1440, icon: Icons.today),
        IntervalOption(title: 'Каждые 3 дня', subtitle: 'Минимальная детализация', interval: 4320, icon: Icons.date_range),
      ];
    }
  }

  int _getRecommendedInterval(Duration duration) {
    if (duration.inHours <= 4) return 5;
    if (duration.inHours <= 24) return 15;
    if (duration.inDays <= 7) return 60;
    if (duration.inDays <= 30) return 240;
    return 1440;
  }

  int _estimateDataPoints(Duration duration, int intervalMinutes) {
    return (duration.inMinutes / intervalMinutes).ceil();
  }

  // ==================== ФОРМАТИРОВАНИЕ ====================

  String _formatDateLabel(DateTime date) {
    final duration = _selectedPeriod == TimePeriod.custom &&
            _customStartDate != null &&
            _customEndDate != null
        ? _customEndDate!.difference(_customStartDate!)
        : _selectedPeriod.duration;

    if (duration.inHours <= 24) {
      return DateFormat('HH:mm').format(date.toLocal());
    }
    return DateFormat('dd.MM').format(date.toLocal());
  }

  String _formatYLabel(double value) {
    if (_dataType == ChartDataType.boolean) {
      if ((value - 1.0).abs() < 0.01) return 'Да';
      if (value.abs() < 0.01) return 'Нет';
      return '';
    }
    if (value.abs() >= 10000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  double _calculateOptimalYInterval(double minY, double maxY) {
    if (_dataType == ChartDataType.boolean) return 0.5;
    final range = (maxY - minY).abs();
    if (range == 0) return 1.0;

    const targetDivisions = 5;
    var interval = range / targetDivisions;
    final magnitude = math.pow(10, (math.log(interval) / math.ln10).floor());
    final normalized = interval / magnitude;

    if (normalized <= 1.5) {
      interval = magnitude.toDouble();
    } else if (normalized <= 3) {
      interval = 2 * magnitude.toDouble();
    } else if (normalized <= 7) {
      interval = 5 * magnitude.toDouble();
    } else {
      interval = 10 * magnitude.toDouble();
    }
    return interval;
  }

  double _getXInterval(double xRangeMs) {
    if (xRangeMs <= 3600000) return 600000; // 10 мин
    if (xRangeMs <= 21600000) return 3600000; // 1 час
    if (xRangeMs <= 86400000) return 14400000; // 4 часа
    if (xRangeMs <= 604800000) return 86400000; // 1 день
    return 432000000; // 5 дней
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.parameter.name.isNotEmpty
                  ? widget.parameter.name
                  : 'Параметр ${widget.parameter.id}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            Text(
              widget.boilerName,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return IconButton(
                icon: Transform.rotate(
                  angle: _refreshAnimation.value * 2 * math.pi,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
                onPressed: _loadChartData,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChartData,
        color: AppColors.primary,
        child: BlocProvider.value(
          value: _parameterChartBloc,
          child: BlocListener<ParameterChartBloc, ParameterChartState>(
            listener: (context, state) {
              if (state is ParameterChartLoaded) {
                setState(() {
                  _chartData = state.values;
                  _processedData = _processChartData(_chartData);
                  if (_isMultiParam) {
                    _processedMultiData = {};
                    for (final entry in state.parameterValues.entries) {
                      _processedMultiData[entry.key] =
                          _processChartData(entry.value);
                    }
                  } else {
                    _processedMultiData = {
                      widget.parameter.id: _processedData
                    };
                  }
                  _isLoading = false;
                });
              } else if (state is ParameterChartLoadFailure) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.isAuthError
                        ? 'Необходима авторизация'
                        : 'Ошибка: ${state.error}'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    action: SnackBarAction(
                      label: 'Повторить',
                      textColor: Colors.white,
                      onPressed: _loadChartData,
                    ),
                  ),
                );
              } else if (state is ParameterChartEmpty) {
                setState(() {
                  _processedData = [];
                  _processedMultiData = {};
                  _isLoading = false;
                });
              }
            },
            child: BlocBuilder<ParameterChartBloc, ParameterChartState>(
              builder: (context, state) {
                if (_isLoading || state is ParameterChartLoadInProgress) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Загрузка данных...',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildPeriodSelector(),
                      if (_isMultiParam && state is ParameterChartLoaded)
                        _buildLegend(state),
                      _buildChart(),
                      if (_isZoomed) _buildZoomResetButton(),
                      _buildStatistics(),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ПРЕСЕТЫ ====================

  Widget _buildPeriodSelector() {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: TimePeriod.values.length,
        itemBuilder: (context, index) {
          final period = TimePeriod.values[index];
          final isSelected = period == _selectedPeriod;

          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                if (period == TimePeriod.custom) {
                  await _selectCustomDateRange();
                } else if (_selectedPeriod != period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  _loadChartData();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(isSelected ? 0.15 : 0.08),
                      blurRadius: isSelected ? 8 : 4,
                      offset: Offset(0, isSelected ? 4 : 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(period.icon,
                        color:
                            isSelected ? Colors.white : AppColors.primary,
                        size: 24),
                    const SizedBox(height: 8),
                    Text(
                      period.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (period == TimePeriod.custom &&
                        isSelected &&
                        _customStartDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd.MM').format(_customStartDate!)} - ${DateFormat('dd.MM').format(_customEndDate!)}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== ЛЕГЕНДА ====================

  Widget _buildLegend(ParameterChartLoaded state) {
    int colorIdx = 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: state.parameters.entries.map((entry) {
          final color = _multiColors[colorIdx % _multiColors.length];
          colorIdx++;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 6),
              Text(entry.value.name,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ==================== ГРАФИК ====================

  Widget _buildChart() {
    if (_processedMultiData.isEmpty ||
        _processedMultiData.values.every((v) => v.isEmpty)) {
      return _buildEmptyChart();
    }

    // Собираем линии
    final lineBars = <LineChartBarData>[];
    double globalMinY = double.infinity;
    double globalMaxY = double.negativeInfinity;
    double globalMinX = double.infinity;
    double globalMaxX = double.negativeInfinity;

    int colorIdx = 0;
    for (final entry in _processedMultiData.entries) {
      final values = entry.value;
      final color = _isMultiParam
          ? _multiColors[colorIdx % _multiColors.length]
          : AppColors.chartPrimary;
      colorIdx++;

      final spots = <FlSpot>[];
      for (final v in values) {
        final x = v.timestamp.millisecondsSinceEpoch.toDouble();
        final y = v.numericValue;
        spots.add(FlSpot(x, y));
        if (y < globalMinY) globalMinY = y;
        if (y > globalMaxY) globalMaxY = y;
        if (x < globalMinX) globalMinX = x;
        if (x > globalMaxX) globalMaxX = x;
      }

      if (spots.isEmpty) continue;

      lineBars.add(LineChartBarData(
        spots: spots,
        isCurved: _dataType != ChartDataType.boolean,
        curveSmoothness: 0.2,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: _dataType == ChartDataType.boolean || spots.length < 40,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 3,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: color,
          ),
        ),
        belowBarData: BarAreaData(
          show: !_isMultiParam,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.chartSecondary.withOpacity(0.3),
              AppColors.chartSecondary.withOpacity(0.05),
            ],
          ),
        ),
      ));
    }

    if (lineBars.isEmpty) return _buildEmptyChart();

    // Границы Y
    double minY, maxY;
    if (_dataType == ChartDataType.boolean) {
      minY = -0.1;
      maxY = 1.1;
    } else if (globalMinY == globalMaxY) {
      final padding = math.max(globalMinY.abs() * 0.1, 1.0);
      minY = globalMinY - padding;
      maxY = globalMaxY + padding;
    } else {
      final range = globalMaxY - globalMinY;
      minY = globalMinY - range * 0.1;
      maxY = globalMaxY + range * 0.1;
    }

    // Зум по X
    final fullRangeX = globalMaxX - globalMinX;
    final visibleRange = fullRangeX / _zoomLevel;
    final centerX = globalMinX + fullRangeX * _zoomOffset;
    final displayMinX = math.max(globalMinX, centerX - visibleRange / 2);
    final displayMaxX = math.min(globalMaxX, centerX + visibleRange / 2);
    final xRange = displayMaxX - displayMinX;
    final xInterval = _getXInterval(xRange);

    return GestureDetector(
      onScaleUpdate: (details) {
        if (details.pointerCount < 2) return;
        setState(() {
          // Зум
          _zoomLevel = (_zoomLevel * details.scale).clamp(1.0, 20.0);
          // Панорамирование
          final delta = details.focalPointDelta.dx;
          if (delta.abs() > 0.5) {
            _zoomOffset = (_zoomOffset - delta / 500).clamp(0.0, 1.0);
          }
        });
      },
      // Панорамирование одним пальцем при зуме
      onHorizontalDragUpdate: _isZoomed
          ? (details) {
              setState(() {
                _zoomOffset = (_zoomOffset - details.delta.dx / 500)
                    .clamp(0.0, 1.0);
              });
            }
          : null,
      child: Container(
        height: 350,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LineChart(
          LineChartData(
            lineBarsData: lineBars,
            minX: displayMinX,
            maxX: displayMaxX,
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _calculateOptimalYInterval(minY, maxY),
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.textSecondary.withOpacity(0.15),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.3)),
                left: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.3)),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: xInterval,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime.fromMillisecondsSinceEpoch(
                        value.toInt());
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatDateLabel(date),
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  interval: _dataType == ChartDataType.boolean
                      ? 1
                      : _calculateOptimalYInterval(minY, maxY),
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _formatYLabel(value),
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                getTooltipColor: (_) => AppColors.textPrimary,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                        spot.x.toInt());
                    final dateStr = DateFormat('dd.MM.yyyy HH:mm')
                        .format(date.toLocal());
                    final color = spot.bar.color ?? Colors.white;

                    String prefix = '';
                    if (_isMultiParam) {
                      final paramId = _processedMultiData.keys
                          .elementAt(spot.barIndex);
                      final bloc = _parameterChartBloc.state;
                      if (bloc is ParameterChartLoaded) {
                        prefix =
                            '${bloc.parameters[paramId]?.name ?? ''}\n';
                      }
                    }

                    final valueStr = _dataType == ChartDataType.boolean
                        ? (spot.y == 1.0 ? 'Да' : 'Нет')
                        : _formatNumericValue(spot.y);

                    return LineTooltipItem(
                      '$prefix$valueStr\n$dateStr',
                      TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  Widget _buildZoomResetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _zoomLevel = 1.0;
            _zoomOffset = 0.5;
          }),
          icon: const Icon(Icons.zoom_out_map, size: 16),
          label: const Text('Сбросить зум', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 350,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Нет данных для отображения',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Попробуйте выбрать другой период',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  // ==================== СТАТИСТИКА ====================

  Widget _buildStatistics() {
    if (_processedMultiData.isEmpty ||
        _processedMultiData.values.every((v) => v.isEmpty)) {
      return const SizedBox.shrink();
    }

    if (_isMultiParam) return _buildMultiParamStatistics();
    if (_processedData.isEmpty) return const SizedBox.shrink();
    if (_dataType == ChartDataType.boolean) return _buildBooleanStatistics();
    return _buildNumericStatistics();
  }

  Widget _buildMultiParamStatistics() {
    final bloc = _parameterChartBloc.state;
    if (bloc is! ParameterChartLoaded) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_getPeriodTitle(),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._processedMultiData.entries.map((entry) {
            final paramId = entry.key;
            final values = entry.value;
            final paramName =
                bloc.parameters[paramId]?.name ?? 'Параметр';
            final numericValues = values
                .map((v) => v.numericValue)
                .where((v) => v.isFinite)
                .toList();

            if (numericValues.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('$paramName: нет данных',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              );
            }

            final min = numericValues.reduce(math.min);
            final max = numericValues.reduce(math.max);
            final avg = numericValues.reduce((a, b) => a + b) /
                numericValues.length;
            final sorted = [...numericValues]..sort();
            final median = sorted.length.isOdd
                ? sorted[sorted.length ~/ 2]
                : (sorted[sorted.length ~/ 2 - 1] +
                        sorted[sorted.length ~/ 2]) /
                    2;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paramName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatItem('Мин',
                              _formatNumericValue(min), AppColors.success, Icons.south)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildStatItem('Макс',
                              _formatNumericValue(max), AppColors.error, Icons.north)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildStatItem('Среднее',
                              _formatNumericValue(avg), AppColors.warning, Icons.show_chart)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildStatItem('Медиана',
                              _formatNumericValue(median), AppColors.primary, Icons.linear_scale)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNumericStatistics() {
    final numericValues = _processedData
        .map((v) => v.numericValue)
        .where((v) => v.isFinite)
        .toList();

    if (numericValues.isEmpty) return const SizedBox.shrink();

    final min = numericValues.reduce(math.min);
    final max = numericValues.reduce(math.max);
    final avg = numericValues.reduce((a, b) => a + b) / numericValues.length;
    final current = numericValues.last;
    final sorted = [...numericValues]..sort();
    final median = sorted.length.isOdd
        ? sorted[sorted.length ~/ 2]
        : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_getPeriodTitle(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem('Текущее',
                      _formatNumericValue(current), AppColors.primary, Icons.trending_up)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatItem('Среднее',
                      _formatNumericValue(avg), AppColors.warning, Icons.show_chart)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem('Минимум',
                      _formatNumericValue(min), AppColors.success, Icons.south)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatItem('Максимум',
                      _formatNumericValue(max), AppColors.error, Icons.north)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem('Медиана',
                      _formatNumericValue(median), AppColors.primary, Icons.linear_scale)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatItem('Точек',
                      '${numericValues.length}', AppColors.textSecondary, Icons.data_usage)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanStatistics() {
    final trueCount =
        _processedData.where((v) => v.numericValue == 1.0).length;
    final falseCount =
        _processedData.where((v) => v.numericValue == 0.0).length;
    final totalCount = _processedData.length;
    final current = _processedData.isNotEmpty
        ? (_processedData.last.numericValue == 1.0 ? 'Да' : 'Нет')
        : 'Нет данных';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_getPeriodTitle(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                      'Текущее', current, AppColors.primary, Icons.info)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatItem('Всего записей',
                      totalCount.toString(), AppColors.warning, Icons.data_usage)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                      'Да',
                      totalCount > 0
                          ? '$trueCount (${(trueCount / totalCount * 100).round()}%)'
                          : '0',
                      AppColors.success,
                      Icons.check_circle)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatItem(
                      'Нет',
                      totalCount > 0
                          ? '$falseCount (${(falseCount / totalCount * 100).round()}%)'
                          : '0',
                      AppColors.error,
                      Icons.cancel)),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodTitle() {
    if (_selectedPeriod == TimePeriod.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      return 'Статистика за ${DateFormat('dd.MM.yyyy').format(_customStartDate!)} - ${DateFormat('dd.MM.yyyy').format(_customEndDate!)}';
    }
    return 'Статистика за ${_selectedPeriod.displayName.toLowerCase()}';
  }

  Widget _buildStatItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}