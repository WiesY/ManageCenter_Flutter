import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/screens/parameter_chart_screen.dart';

// Упрощенные константы
class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const background = Color(0xFFF5F5F5);
  static const error = Colors.red;
  static const warning = Colors.orange;
}

// Модель для группы параметров
class ParameterGroup {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<int> parameterIds;
  bool isVisible;
  bool isExpanded;

  ParameterGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.parameterIds,
    this.isVisible = true,
    this.isExpanded = true,
  });
}

// Статус котельной
enum BoilerStatus { normal, warning, error }

// Основной экран с группировкой
class BoilerDetailScreen extends StatefulWidget {
  final int boilerId;
  final String boilerName;
  final String? districtName;

  const BoilerDetailScreen({
    Key? key,
    required this.boilerId,
    required this.boilerName,
    this.districtName,
  }) : super(key: key);

  @override
  _BoilerDetailScreenState createState() => _BoilerDetailScreenState();
}

class _BoilerDetailScreenState extends State<BoilerDetailScreen> {
  List<BoilerParameter> _allParameters = [];
  List<BoilerParameterValue> _currentValues = [];
  Map<int, BoilerParameterValue> _parameterValueMap = {};
  BoilerStatus _boilerStatus = BoilerStatus.normal;

  // Предустановленные группы параметров
  late List<ParameterGroup> _parameterGroups;

  @override
  void initState() {
    super.initState();
    _initializeGroups();
    _loadParameters();
  }

  void _initializeGroups() {
    _parameterGroups = [
      ParameterGroup(
        id: 'temperature',
        name: 'Температура',
        description: 'Показатели температуры',
        icon: Icons.thermostat,
        color: Colors.red,
        parameterIds: [], // Будем заполнять автоматически
      ),
      ParameterGroup(
        id: 'pressure',
        name: 'Давление',
        description: 'Показатели давления',
        icon: Icons.speed,
        color: Colors.blue,
        parameterIds: [],
      ),
      ParameterGroup(
        id: 'flow',
        name: 'Расход',
        description: 'Показатели расхода',
        icon: Icons.water_drop,
        color: Colors.cyan,
        parameterIds: [],
      ),
      ParameterGroup(
        id: 'level',
        name: 'Уровень',
        description: 'Показатели уровня',
        icon: Icons.height,
        color: Colors.green,
        parameterIds: [],
      ),
      ParameterGroup(
        id: 'power',
        name: 'Мощность',
        description: 'Показатели мощности',
        icon: Icons.bolt,
        color: Colors.orange,
        parameterIds: [],
      ),
      ParameterGroup(
        id: 'other',
        name: 'Прочее',
        description: 'Остальные параметры',
        icon: Icons.more_horiz,
        color: Colors.grey,
        parameterIds: [],
      ),
    ];
  }

  void _loadParameters() {
    context.read<BoilerDetailBloc>().add(LoadBoilerParameters(widget.boilerId));
  }

  void _loadCurrentValues() {
    final now = DateTime.now();
    context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
      boilerId: widget.boilerId,
      startDate: now.subtract(const Duration(minutes: 5)),
      endDate: now,
      selectedParameterIds: _allParameters.map((p) => p.id).toList(),
      interval: 1,
    ));
  }

  void _categorizeParameters() {
    for (var parameter in _allParameters) {
      final description = parameter.paramDescription.toLowerCase();

      if (description.contains('темп') || description.contains('°c')) {
        _parameterGroups[0].parameterIds.add(parameter.id);
      } else if (description.contains('давл') || description.contains('бар') || description.contains('па')) {
        _parameterGroups[1].parameterIds.add(parameter.id);
      } else if (description.contains('расход') || description.contains('поток')) {
        _parameterGroups[2].parameterIds.add(parameter.id);
      } else if (description.contains('уровень')) {
        _parameterGroups[3].parameterIds.add(parameter.id);
      } else if (description.contains('мощн') || description.contains('кВт') || description.contains('вт')) {
        _parameterGroups[4].parameterIds.add(parameter.id);
      } else {
        _parameterGroups[5].parameterIds.add(parameter.id);
      }
    }

    // Убираем пустые группы
    _parameterGroups.removeWhere((group) => group.parameterIds.isEmpty);
  }

  void _buildParameterValueMap() {
    _parameterValueMap.clear();
    for (var value in _currentValues) {
      _parameterValueMap[value.parameter.id] = value;
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time.add(const Duration(hours: 3)));
  }

  String _translateParameterType(String valueType) {
    final type = valueType.toLowerCase();
    switch (type) {
      case 'float':
      case 'double':
        return 'дробное';
      case 'int':
      case 'integer':
        return 'целое';
      case 'bool':
      case 'boolean':
        return 'логическое';
      case 'string':
      case 'text':
        return 'текстовое';
      case 'byte':
        return 'байт';
      case 'decimal':
        return 'десятичное';
      case 'long':
        return 'длинное целое';
      case 'short':
        return 'короткое целое';
      default:
        return valueType; // Если тип неизвестен, оставляем как есть
    }
  }

  Color get _statusColor {
    switch (_boilerStatus) {
      case BoilerStatus.normal:
        return AppColors.primaryLight;
      case BoilerStatus.warning:
        return AppColors.warning;
      case BoilerStatus.error:
        return AppColors.error;
    }
  }

  String get _statusText {
    switch (_boilerStatus) {
      case BoilerStatus.normal:
        return 'В работе';
      case BoilerStatus.warning:
        return 'Внимание';
      case BoilerStatus.error:
        return 'Авария';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusHeader(),
          _buildGroupFilterChips(),
          Expanded(child: _buildParameterGroups()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCurrentValues,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        children: [
          Text(
            widget.boilerName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.districtName != null)
            Text(
              widget.districtName!,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
        ],
      ),
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showGroupManagementDialog,
        ),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
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
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _statusColor,
            ),
          ),
          const Spacer(),
          Text(
            'Обновлено: ${_formatTime(DateTime.now())}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _parameterGroups.length,
        itemBuilder: (context, index) {
          final group = _parameterGroups[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(group.icon, size: 16, color: group.isVisible ? Colors.white : group.color),
                  const SizedBox(width: 4),
                  Text(group.name),
                  if (group.parameterIds.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: group.isVisible ? Colors.white24 : group.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${group.parameterIds.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: group.isVisible ? Colors.white : group.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              selected: group.isVisible,
              selectedColor: group.color,
              backgroundColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  group.isVisible = selected;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildParameterGroups() {
    return BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
      builder: (context, state) {
        if (state is BoilerDetailLoadInProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BoilerDetailLoadFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Ошибка загрузки: ${state.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadParameters,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        if (state is BoilerDetailParametersLoaded) {
          _allParameters = state.parameters;
          _categorizeParameters();
          // Автоматически загружаем текущие значения
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadCurrentValues();
          });
          return _buildGroupsList();
        }

        if (state is BoilerDetailValuesLoaded) {
          _currentValues = state.values;
          _buildParameterValueMap();
          return _buildGroupsList();
        }

        return const Center(child: Text('Инициализация...'));
      },
    );
  }

  Widget _buildGroupsList() {
    final visibleGroups = _parameterGroups.where((g) => g.isVisible).toList();

    if (visibleGroups.isEmpty) {
      return const Center(
        child: Text('Выберите группы для отображения'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: visibleGroups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(visibleGroups[index]);
      },
    );
  }

  Widget _buildGroupCard(ParameterGroup group) {
    final parametersInGroup = _allParameters.where((p) => group.parameterIds.contains(p.id)).toList();

    if (parametersInGroup.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: group.isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            group.isExpanded = expanded;
          });
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: group.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(group.icon, color: group.color, size: 24),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${parametersInGroup.length} параметров • Нажмите для просмотра графика'),
        children: parametersInGroup.map((parameter) {
          final value = _parameterValueMap[parameter.id];
          return _buildParameterTile(parameter, value);
        }).toList(),
      ),
    );
  }

  void _openParameterChart(BoilerParameter parameter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<BoilerDetailBloc>(),
          child: ParameterChartScreen(
            boilerId: widget.boilerId,
            boilerName: widget.boilerName,
            parameter: parameter,
          ),
        ),
      ),
    );
  }

  Widget _buildParameterTile(BoilerParameter parameter, BoilerParameterValue? value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: () => _openParameterChart(parameter),
      title: Text(
        parameter.paramDescription.isNotEmpty
          ? parameter.paramDescription
          : 'Параметр ID: ${parameter.id}',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _translateParameterType(parameter.valueType),
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ID: ${parameter.id}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: value != null ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value != null ? Colors.green[200]! : Colors.grey[300]!,
              ),
            ),
            child: Text(
              value?.displayValue ?? 'Нет данных',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: value != null ? AppColors.primary : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.show_chart,
            size: 20,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  void _showGroupManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Управление группами'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _parameterGroups.length,
            itemBuilder: (context, index) {
              final group = _parameterGroups[index];
              return CheckboxListTile(
                title: Row(
                  children: [
                    Icon(group.icon, color: group.color, size: 20),
                    const SizedBox(width: 8),
                    Text(group.name),
                  ],
                ),
                subtitle: Text('${group.parameterIds.length} параметров'),
                value: group.isVisible,
                onChanged: (value) {
                  setState(() {
                    group.isVisible = value ?? false;
                  });
                  Navigator.pop(context);
                  _showGroupManagementDialog();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}