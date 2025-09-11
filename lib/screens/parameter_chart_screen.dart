import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';

// Модель для периода времени
enum TimePeriod {
  hour,
  day,
  week,
  month,
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
    }
  }

  int get interval {
    switch (this) {
      case TimePeriod.hour:
        return 30; // Каждую минуту
      case TimePeriod.day:
        return 60; // Каждые 5 минут
      case TimePeriod.week:
        return 240; // Каждые 30 минут
      case TimePeriod.month:
        return 1440; // Каждый час
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
    final startDate = now.subtract(_selectedPeriod.duration);
    
    context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
      boilerId: widget.boilerId,
      startDate: startDate,
      endDate: now,
      selectedParameterIds: [widget.parameter.id],
      interval: _selectedPeriod.interval,
    ));
  }

  String _formatDateTime(DateTime dateTime) {
    switch (_selectedPeriod) {
      case TimePeriod.hour:
        return DateFormat('HH:mm').format(dateTime);
      case TimePeriod.day:
        return DateFormat('HH:mm').format(dateTime);
      case TimePeriod.week:
        return DateFormat('dd.MM HH:mm').format(dateTime);
      case TimePeriod.month:
        return DateFormat('dd.MM').format(dateTime);
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
              onTap: () {
                if (_selectedPeriod != period) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                  _loadChartData();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[600] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    period.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
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
      return const Center(
        child: Text('Нет данных для отображения'),
      );
    }

    final spots = _getChartSpots();
    if (spots.isEmpty) return const Center(child: Text('Нет данных'));

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: null,
            verticalInterval: null,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 0.5,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (spots.length / 6).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _chartData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatDateTime(_chartData[index].receiptDate),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
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
              getTooltipColor: (touchedSpot) => Colors.black87,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  if (index >= 0 && index < _chartData.length) {
                    final data = _chartData[index];
                    return LineTooltipItem(
                      '${data.displayValue}\n${_formatDateTime(data.receiptDate)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
            'Статистика за ${_selectedPeriod.displayName.toLowerCase()}',
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
              widget.parameter.paramDescription,
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