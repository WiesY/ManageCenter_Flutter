import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'dart:math' as math;

// Класс для опций интервала
class IntervalOption {
  final String title;
  final String subtitle;
  final int interval;

  IntervalOption({
    required this.title,
    required this.subtitle,
    required this.interval,
  });
}

// Модель для периода времени
enum TimePeriod {
  hour,
  day,
  week,
  month,
  custom, // добавляем произвольный период
}

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
        return const Duration(hours: 4);
      case TimePeriod.day:
        return const Duration(days: 1);
      case TimePeriod.week:
        return const Duration(days: 7);
      case TimePeriod.month:
        return const Duration(days: 30);
      case TimePeriod.custom:
        return const Duration(days: 7); // дефолт для custom
    }
  }

  int get interval {
    switch (this) {
      case TimePeriod.hour:
        return 5; // Каждую минуту
      case TimePeriod.day:
        return 60; // Каждые 5 минут
      case TimePeriod.week:
        return 240; // Каждые 30 минут
      case TimePeriod.month:
        return 1440; // Каждый час
      case TimePeriod.custom:
        return 60; // дефолт для custom
    }
  }
}

class ParameterChartScreen extends StatefulWidget {
  final int boilerId;
  final String boilerName;
  final BoilerParameter parameter;

  const ParameterChartScreen({
    Key? key,
    required this.boilerId,
    required this.boilerName,
    required this.parameter,
  }) : super(key: key);

  @override
  _ParameterChartScreenState createState() => _ParameterChartScreenState();
}

class _ParameterChartScreenState extends State<ParameterChartScreen> {
  TimePeriod _selectedPeriod = TimePeriod.day;
  List<BoilerParameterValue> _chartData = [];
  bool _isLoading = false;
  
  // Добавляем поля для произвольного диапазона
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int _customInterval = 60;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  void _loadChartData() {
    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    int interval;

    if (_selectedPeriod == TimePeriod.custom) {
      // Для произвольного периода используем выбранные даты
      if (_customStartDate == null || _customEndDate == null) {
        // Если даты не выбраны, используем последнюю неделю
        startDate = now.subtract(const Duration(days: 7));
        endDate = now;
        interval = 240;
      } else {
        startDate = _customStartDate!;
        endDate = _customEndDate!;
        interval = _customInterval;
      }
    } else {
      // Для предустановленных периодов
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

  // Метод для выбора произвольного диапазона
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
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[600]!,
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
      // После выбора дат показываем диалог выбора интервала
      final selectedInterval = await _showIntervalDialog(picked);
      
      if (selectedInterval != null) {
        setState(() {
          _customStartDate = picked.start;
          _customEndDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
          _customInterval = selectedInterval;
        });
        
        _loadChartData();
      }
    }
  }

  // Диалог выбора интервала
  Future<int?> _showIntervalDialog(DateTimeRange dateRange) async {
    final duration = dateRange.end.difference(dateRange.start) + const Duration(days: 1);
    
    // Предлагаем интервалы в зависимости от длительности периода
    List<IntervalOption> intervals = _getIntervalOptions(duration);
    
    // Автоматически выбираем рекомендуемый интервал
    int recommendedInterval = _getRecommendedInterval(duration);
    int selectedInterval = recommendedInterval;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Настройка интервала'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Период: ${DateFormat('dd.MM.yyyy').format(dateRange.start)} - ${DateFormat('dd.MM.yyyy').format(dateRange.end)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Длительность: ${duration.inDays} дн.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Выберите интервал сбора данных:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...intervals.map((option) {
                    return RadioListTile<int>(
                      title: Text(option.title),
                      subtitle: Text(
                        '${option.subtitle}\n≈ ${_estimateDataPoints(duration, option.interval)} точек данных',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      value: option.interval,
                      groupValue: selectedInterval,
                      activeColor: Colors.green[600],
                      onChanged: (value) {
                        setState(() {
                          selectedInterval = value!;
                        });
                      },
                      // Выделяем рекомендуемый вариант
                      secondary: option.interval == recommendedInterval
                          ? Icon(Icons.recommend, color: Colors.green[600], size: 20)
                          : null,
                    );
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selectedInterval),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
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

  // Получаем доступные интервалы в зависимости от длительности
  List<IntervalOption> _getIntervalOptions(Duration duration) {
    List<IntervalOption> options = [];

    if (duration.inHours <= 24) {
      // Для периода до суток
      options.addAll([
        IntervalOption(title: 'Каждую минуту', subtitle: 'Максимальная детализация', interval: 1),
        IntervalOption(title: 'Каждые 5 минут', subtitle: 'Высокая детализация', interval: 5),
        IntervalOption(title: 'Каждые 15 минут', subtitle: 'Средняя детализация', interval: 15),
        IntervalOption(title: 'Каждые 30 минут', subtitle: 'Низкая детализация', interval: 30),
        IntervalOption(title: 'Каждый час', subtitle: 'Минимальная детализация', interval: 60),
      ]);
    } else if (duration.inDays <= 7) {
      // Для периода до недели
      options.addAll([
        IntervalOption(title: 'Каждые 5 минут', subtitle: 'Максимальная детализация', interval: 5),
        IntervalOption(title: 'Каждые 15 минут', subtitle: 'Высокая детализация', interval: 15),
        IntervalOption(title: 'Каждые 30 минут', subtitle: 'Средняя детализация', interval: 30),
        IntervalOption(title: 'Каждый час', subtitle: 'Низкая детализация', interval: 60),
        IntervalOption(title: 'Каждые 4 часа', subtitle: 'Минимальная детализация', interval: 240),
      ]);
    } else if (duration.inDays <= 30) {
      // Для периода до месяца
      options.addAll([
        IntervalOption(title: 'Каждые 30 минут', subtitle: 'Максимальная детализация', interval: 30),
        IntervalOption(title: 'Каждый час', subtitle: 'Высокая детализация', interval: 60),
        IntervalOption(title: 'Каждые 4 часа', subtitle: 'Средняя детализация', interval: 240),
        IntervalOption(title: 'Каждые 12 часов', subtitle: 'Низкая детализация', interval: 720),
        IntervalOption(title: 'Каждый день', subtitle: 'Минимальная детализация', interval: 1440),
      ]);
    } else {
      // Для периода больше месяца
      options.addAll([
        IntervalOption(title: 'Каждый час', subtitle: 'Максимальная детализация', interval: 60),
        IntervalOption(title: 'Каждые 4 часа', subtitle: 'Высокая детализация', interval: 240),
        IntervalOption(title: 'Каждые 12 часов', subtitle: 'Средняя детализация', interval: 720),
        IntervalOption(title: 'Каждый день', subtitle: 'Низкая детализация', interval: 1440),
        IntervalOption(title: 'Каждые 3 дня', subtitle: 'Минимальная детализация', interval: 4320),
      ]);
    }

    return options;
  }

  // Получаем рекомендуемый интервал
  int _getRecommendedInterval(Duration duration) {
    if (duration.inHours <= 4) {
      return 5; // каждые 5 минут
    } else if (duration.inHours <= 24) {
      return 15; // каждые 15 минут
    } else if (duration.inDays <= 7) {
      return 60; // каждый час
    } else if (duration.inDays <= 30) {
      return 240; // каждые 4 часа
    } else {
      return 1440; // каждый день
    }
  }

  // Оценка количества точек данных
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
        return DateFormat('dd.MM HH:mm').format(dateTime.toLocal());
      case TimePeriod.month:
        return DateFormat('dd.MM').format(dateTime.toLocal());
      case TimePeriod.custom:
        // Для произвольного периода выбираем формат в зависимости от длительности
        if (_customStartDate != null && _customEndDate != null) {
          final duration = _customEndDate!.difference(_customStartDate!);
          if (duration.inDays <= 1) {
            return DateFormat('HH:mm').format(dateTime.toLocal());
          } else if (duration.inDays <= 7) {
            return DateFormat('dd.MM HH:mm').format(dateTime.toLocal());
          } else {
            return DateFormat('dd.MM').format(dateTime.toLocal());
          }
        }
        return DateFormat('dd.MM HH:mm').format(dateTime.toLocal());
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
      height: 50,
      margin: const EdgeInsets.all(16),
      child: Row(
        children: TimePeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                if (period == TimePeriod.custom) {
                  // Для произвольного периода открываем календарь
                  await _selectCustomDateRange();
                  if (_customStartDate != null && _customEndDate != null) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  }
                } else {
                  // Для предустановленных периодов
                  if (_selectedPeriod != period) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _loadChartData();
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[600] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        period.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                      // Показываем выбранный диапазон для произвольного периода
                      if (period == TimePeriod.custom && isSelected && _customStartDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('dd.MM').format(_customStartDate!)} - ${DateFormat('dd.MM').format(_customEndDate!)}',
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.black54,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    if (_chartData.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final spots = _getChartSpots();
    if (spots.isEmpty) return const Center(child: Text('Нет данных'));

    final minYVal = spots.map((s) => s.y).reduce(math.min);
    final maxYVal = spots.map((s) => s.y).reduce(math.max);
    final rangeY = (maxYVal - minYVal).abs();
    final padY = rangeY == 0 ? (maxYVal.abs() * 0.1 + 1) : rangeY * 0.1;

    final minXVal = 0.0;
    final maxXVal = (spots.length - 1).toDouble();

    // Увеличиваем интервал для подписей времени, чтобы не накладывались
    final bottomInterval = math.max(1, ((spots.length - 1) / 4).floor()).toDouble();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
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
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[300], strokeWidth: 0.5),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[300], strokeWidth: 0.5),
          ),
          
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // увеличили с 30 до 40
                interval: bottomInterval,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index >= 0 && index < _chartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: -0.3, // небольшой поворот для экономии места
                        child: Text(
                          _formatDateTime(_chartData[index].receiptDate),
                          style: const TextStyle(fontSize: 9), // уменьшили шрифт
                          textAlign: TextAlign.center,
                        ),
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
                reservedSize: 50, // уменьшили с 60 до 50
                interval: rangeY > 0 ? rangeY / 4 : null, // автоматический интервал
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8), // отступ от графика
                    child: Text(
                      value.toStringAsFixed(0), // убрали дробную часть для компактности
                      style: const TextStyle(fontSize: 9),
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
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.15,
              color: Colors.green[600],
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green[100]!.withOpacity(0.3),
              ),
            ),
          ],
          
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (touchedSpot) => Colors.black87,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < _chartData.length) {
                    final data = _chartData[index];
                    return LineTooltipItem(
                      '${data.displayValue}\n${_formatDateTime(data.receiptDate)}',
                      const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
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

    // Определяем заголовок статистики
    String periodTitle;
    if (_selectedPeriod == TimePeriod.custom && _customStartDate != null && _customEndDate != null) {
      periodTitle = 'Статистика за ${DateFormat('dd.MM.yyyy').format(_customStartDate!)} - ${DateFormat('dd.MM.yyyy').format(_customEndDate!)}';
    } else {
      periodTitle = 'Статистика за ${_selectedPeriod.displayName.toLowerCase()}';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Текущее', current.toStringAsFixed(2), Colors.blue),
              ),
              Expanded(
                child: _buildStatItem('Среднее', avg.toStringAsFixed(2), Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Минимум', min.toStringAsFixed(2), Colors.green),
              ),
              Expanded(
                child: _buildStatItem('Максимум', max.toStringAsFixed(2), Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.parameter.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.boilerName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChartData,
          ),
        ],
      ),
      body: BlocListener<BoilerDetailBloc, BoilerDetailState>(
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
              SnackBar(content: Text('Ошибка: ${state.error}')),
            );
          }
        },
        child: Column(
          children: [
            _buildPeriodSelector(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildChart(),
                          _buildStatistics(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}