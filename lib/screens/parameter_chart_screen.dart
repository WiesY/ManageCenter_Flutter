import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'dart:math' as math;

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

enum TimePeriod {
  hour,
  day,
  week,
  month,
  custom,
}

extension TimePeriodExtension on TimePeriod {
  String get displayName {
    switch (this) {
      case TimePeriod.hour:
        return '4 часа';
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
        return const Duration(hours: 4);
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
        return 5; // каждые 5 минут
      case TimePeriod.day:
        return 30; // каждые 30 минут
      case TimePeriod.week:
        return 240; // каждые 4 часа
      case TimePeriod.month:
        return 1440; // каждый день
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

class ParameterChartScreen extends StatefulWidget {
  final int boilerId;
  final String boilerName;
  final BoilerParameter parameter;

  const ParameterChartScreen({
    super.key,
    required this.boilerId,
    required this.boilerName,
    required this.parameter,
  });

  @override
  State<ParameterChartScreen> createState() => _ParameterChartScreenState();
}

class _ParameterChartScreenState extends State<ParameterChartScreen>
    with TickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.day;
  List<BoilerParameterValue> _chartData = [];
  bool _isLoading = false;

  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int _customInterval = 60;

  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

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
    _loadChartData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    _refreshController.forward().then((_) => _refreshController.reverse());

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    int interval;

    if (_selectedPeriod == TimePeriod.custom) {
      if (_customStartDate == null || _customEndDate == null) {
        startDate = now.subtract(const Duration(days: 7));
        endDate = now;
        interval = 240;
      } else {
        startDate = _customStartDate!;
        endDate = _customEndDate!;
        interval = _customInterval;
      }
    } else {
      startDate = now.subtract(_selectedPeriod.duration);
      endDate = now;
      interval = _selectedPeriod.interval;
    }

    context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
          boilerId: widget.boilerId,
          startDate: startDate,
          endDate: endDate,
          selectedParameterIds: [widget.parameter.id],
          interval: interval,
        ));
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
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
            colorScheme: ColorScheme.light(
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
        });

        _loadChartData();
      }
    }
  }

  Future<int?> _showIntervalDialog(DateTimeRange dateRange) async {
    final duration =
        dateRange.end.difference(dateRange.start) + const Duration(days: 1);
    List<IntervalOption> intervals = _getIntervalOptions(duration);
    int recommendedInterval = _getRecommendedInterval(duration);
    int selectedInterval = recommendedInterval;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Настройка интервала',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Длительность: ${duration.inDays} дн.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Выберите интервал сбора данных:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...intervals.map((option) {
                      final isRecommended =
                          option.interval == recommendedInterval;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isRecommended
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.transparent,
                          ),
                          color: isRecommended
                              ? AppColors.primary.withOpacity(0.05)
                              : null,
                        ),
                        child: RadioListTile<int>(
                          title: Row(
                            children: [
                              Icon(option.icon,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(option.title),
                              if (isRecommended) ...[
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
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${option.subtitle}\n≈ ${_estimateDataPoints(duration, option.interval)} точек данных',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          value: option.interval,
                          groupValue: selectedInterval,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              selectedInterval = value!;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selectedInterval),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
    List<IntervalOption> options = [];

    if (duration.inHours <= 24) {
      options.addAll([
        IntervalOption(
            title: 'Каждую минуту',
            subtitle: 'Максимальная детализация',
            interval: 1,
            icon: Icons.timer),
        IntervalOption(
            title: 'Каждые 5 минут',
            subtitle: 'Высокая детализация',
            interval: 5,
            icon: Icons.schedule),
        IntervalOption(
            title: 'Каждые 15 минут',
            subtitle: 'Средняя детализация',
            interval: 15,
            icon: Icons.access_time),
        IntervalOption(
            title: 'Каждые 30 минут',
            subtitle: 'Низкая детализация',
            interval: 30,
            icon: Icons.hourglass_empty),
        IntervalOption(
            title: 'Каждый час',
            subtitle: 'Минимальная детализация',
            interval: 60,
            icon: Icons.watch_later),
      ]);
    } else if (duration.inDays <= 7) {
      options.addAll([
        IntervalOption(
            title: 'Каждые 5 минут',
            subtitle: 'Максимальная детализация',
            interval: 5,
            icon: Icons.timer),
        IntervalOption(
            title: 'Каждые 15 минут',
            subtitle: 'Высокая детализация',
            interval: 15,
            icon: Icons.schedule),
        IntervalOption(
            title: 'Каждые 30 минут',
            subtitle: 'Средняя детализация',
            interval: 30,
            icon: Icons.access_time),
        IntervalOption(
            title: 'Каждый час',
            subtitle: 'Низкая детализация',
            interval: 60,
            icon: Icons.watch_later),
        IntervalOption(
            title: 'Каждые 4 часа',
            subtitle: 'Минимальная детализация',
            interval: 240,
            icon: Icons.hourglass_full),
      ]);
    } else if (duration.inDays <= 30) {
      options.addAll([
        IntervalOption(
            title: 'Каждые 30 минут',
            subtitle: 'Максимальная детализация',
            interval: 30,
            icon: Icons.timer),
        IntervalOption(
            title: 'Каждый час',
            subtitle: 'Высокая детализация',
            interval: 60,
            icon: Icons.schedule),
        IntervalOption(
            title: 'Каждые 4 часа',
            subtitle: 'Средняя детализация',
            interval: 240,
            icon: Icons.access_time),
        IntervalOption(
            title: 'Каждые 12 часов',
            subtitle: 'Низкая детализация',
            interval: 720,
            icon: Icons.watch_later),
        IntervalOption(
            title: 'Каждый день',
            subtitle: 'Минимальная детализация',
            interval: 1440,
            icon: Icons.today),
      ]);
    } else {
      options.addAll([
        IntervalOption(
            title: 'Каждый час',
            subtitle: 'Максимальная детализация',
            interval: 60,
            icon: Icons.timer),
        IntervalOption(
            title: 'Каждые 4 часа',
            subtitle: 'Высокая детализация',
            interval: 240,
            icon: Icons.schedule),
        IntervalOption(
            title: 'Каждые 12 часов',
            subtitle: 'Средняя детализация',
            interval: 720,
            icon: Icons.access_time),
        IntervalOption(
            title: 'Каждый день',
            subtitle: 'Низкая детализация',
            interval: 1440,
            icon: Icons.today),
        IntervalOption(
            title: 'Каждые 3 дня',
            subtitle: 'Минимальная детализация',
            interval: 4320,
            icon: Icons.date_range),
      ]);
    }

    return options;
  }

  int _getRecommendedInterval(Duration duration) {
    if (duration.inHours <= 4) {
      return 5;
    } else if (duration.inHours <= 24) {
      return 15;
    } else if (duration.inDays <= 7) {
      return 60;
    } else if (duration.inDays <= 30) {
      return 240;
    } else {
      return 1440;
    }
  }

  int _estimateDataPoints(Duration duration, int intervalMinutes) {
    final totalMinutes = duration.inMinutes;
    return (totalMinutes / intervalMinutes).ceil();
  }

  String _formatDateTime(DateTime dateTime) {
    switch (_selectedPeriod) {
      case TimePeriod.hour:
        return DateFormat('HH:mm').format(dateTime.toLocal());
      case TimePeriod.day:
        return DateFormat('HH:mm').format(dateTime.toLocal());
      case TimePeriod.week:
        return DateFormat('dd.MM').format(dateTime.toLocal());
      case TimePeriod.month:
        return DateFormat('dd.MM').format(dateTime.toLocal());
      case TimePeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          final duration = _customEndDate!.difference(_customStartDate!);
          if (duration.inDays <= 1) {
            return DateFormat('HH:mm').format(dateTime.toLocal());
          } else {
            return DateFormat('dd.MM').format(dateTime.toLocal());
          }
        }
        return DateFormat('dd.MM').format(dateTime.toLocal());
    }
  }

  List<FlSpot> _getChartSpots() {
    if (_chartData.isEmpty) return [];

    return _chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      final numericValue = double.tryParse(value.value) ?? 0.0;
      return FlSpot(index.toDouble(), numericValue);
    }).toList();
  }

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
                  if (_customStartDate != null && _customEndDate != null) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  }
                } else {
                  if (_selectedPeriod != period) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _loadChartData();
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
                      blurRadius: isSelected ? 8 : 4,
                      offset: Offset(0, isSelected ? 4 : 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      period.icon,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      period.displayName,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
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
                          fontSize: 9,
                        ),
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

  Widget _buildChart() {
  if (_chartData.isEmpty) {
    return _buildEmptyChart();
  }

  final spots = _getChartSpots();
  if (spots.isEmpty) return _buildEmptyChart();

  final minYVal = spots.map((s) => s.y).reduce(math.min);
  final maxYVal = spots.map((s) => s.y).reduce(math.max);
  final rangeY = (maxYVal - minYVal).abs();
  final padY = rangeY == 0 ? (maxYVal.abs() * 0.1 + 1) : rangeY * 0.15;

  final minXVal = 0.0;
  final maxXVal = (spots.length - 1).toDouble();

  // Увеличиваем интервал для подписей времени, чтобы избежать наслаивания
  final bottomInterval = math.max(1, (spots.length / 4).ceil()).toDouble();

  // Рассчитываем оптимальный интервал для левой оси
  double calculateLeftInterval() {
    if (rangeY == 0) return 1;
    
    // Целимся на 4-5 меток
    const targetTicks = 4;
    var interval = rangeY / targetTicks;
    
    // Округляем до красивого числа
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

  final leftInterval = calculateLeftInterval();

  return Container(
    height: 350,
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
    child: LineChart(
      LineChartData(
        minX: minXVal,
        maxX: maxXVal,
        minY: minYVal - padY,
        maxY: maxYVal + padY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: leftInterval, // Добавляем интервал для горизонтальных линий
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.textSecondary.withOpacity(0.2),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: AppColors.textSecondary.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                final index = value.round();
                if (index >= 0 && index < _chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDateTime(_chartData[index].receiptDate),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
         leftTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 65,
    interval: leftInterval, // Используем рассчитанный интервал
    getTitlesWidget: (value, meta) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        ),
      );
    },
  ),
),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: AppColors.chartPrimary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.chartSecondary.withOpacity(0.3),
                  AppColors.chartSecondary.withOpacity(0.1),
                  AppColors.chartSecondary.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (touchedSpot) => AppColors.textPrimary,
            tooltipBorderRadius: BorderRadius.circular(12),
            tooltipPadding: const EdgeInsets.all(12),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < _chartData.length) {
                  final data = _chartData[index];
                  return LineTooltipItem(
                    '${data.displayValue}\n${_formatDateTime(data.receiptDate)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            // Добавляем тактильную обратную связь при касании
            if (event is FlTapUpEvent &&
                touchResponse?.lineBarSpots?.isNotEmpty == true) {
              // HapticFeedback.lightImpact();
            }
          },
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
            Icon(
              Icons.show_chart,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных для отображения',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте выбрать другой период',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    if (_chartData.isEmpty) return const SizedBox.shrink();

    final numericValues = _chartData
        .map((v) => double.tryParse(v.value))
        .where((v) => v != null)
        .cast<double>()
        .toList();

    if (numericValues.isEmpty) return const SizedBox.shrink();

    final min = numericValues.reduce((a, b) => a < b ? a : b);
    final max = numericValues.reduce((a, b) => a > b ? a : b);
    final avg = numericValues.reduce((a, b) => a + b) / numericValues.length;
    final current = numericValues.isNotEmpty ? numericValues.last : 0.0;

    String periodTitle;
    if (_selectedPeriod == TimePeriod.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      periodTitle =
          'Статистика за ${DateFormat('dd.MM.yyyy').format(_customStartDate!)} - ${DateFormat('dd.MM.yyyy').format(_customEndDate!)}';
    } else {
      periodTitle =
          'Статистика за ${_selectedPeriod.displayName.toLowerCase()}';
    }

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
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  periodTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Текущее',
                  current.toStringAsFixed(2),
                  AppColors.primary,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Среднее',
                  avg.toStringAsFixed(2),
                  AppColors.warning,
                  Icons.show_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Минимум',
                  min.toStringAsFixed(2),
                  AppColors.success,
                  Icons.south,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Максимум',
                  max.toStringAsFixed(2),
                  AppColors.error,
                  Icons.north,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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
                color: Colors.white,
              ),
            ),
            Text(
              widget.boilerName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        //elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return IconButton(
                icon: Transform.rotate(
                  angle: _refreshAnimation.value * 2 * 3.14159,
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
        child: BlocListener<BoilerDetailBloc, BoilerDetailState>(
          listener: (context, state) {
            if (state is BoilerDetailValuesLoaded) {
              setState(() {
                _chartData = state.values
                    .where((v) => v.parameter.id == widget.parameter.id)
                    .toList();
                _isLoading = false;
              });
            } else if (state is BoilerDetailLoadFailure) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка: ${state.error}'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          },
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Загрузка данных...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildPeriodSelector(),
                      _buildChart(),
                      _buildStatistics(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
