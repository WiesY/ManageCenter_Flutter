import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/screens/parameter_chart_screen.dart';
import 'package:manage_center/widgets/blinking_dot.dart';

// Упрощенные константы
class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const background = Color(0xFFF5F5F5);
  static const error = Colors.red;
  static const warning = Colors.orange;
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
  List<Group> _allGroups = [];
  List<BoilerParameterValue> _currentValues = [];
  Map<int, BoilerParameterValue> _parameterValueMap = {};
  Map<int, bool> _groupVisibility = {}; // Видимость групп
  Map<int, bool> _groupExpansion = {}; // Развернутость групп
  BoilerStatus _boilerStatus = BoilerStatus.normal;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  void _loadConfiguration() {
    context.read<BoilerDetailBloc>().add(LoadBoilerConfiguration(widget.boilerId));
  }

  void _loadCurrentValues() {
    final now = DateTime.now().toUtc();
    context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
      boilerId: widget.boilerId,
      startDate: now.subtract(const Duration(minutes: 5)),
      endDate: now,
      selectedParameterIds: _allParameters.map((p) => p.id).toList(),
      interval: 1,
    ));
  }

  void _buildParameterValueMap() {
    _parameterValueMap.clear();
    for (var value in _currentValues) {
      _parameterValueMap[value.parameter.id] = value;
    }
  }

  void _initializeGroupSettings() {
    for (var group in _allGroups) {
      _groupVisibility[group.id] ??= true; // По умолчанию все группы видимы
      _groupExpansion[group.id] ??= group.isExpanded; // Используем настройку из модели
    }
  }

Group get _otherGroup => const Group(
  id: -1, // Специальный ID
  name: 'Другие',
  color: 'grey', 
  iconFileName: 'other',
  isExpanded: false,
);

List<BoilerParameter> _getParametersWithoutGroup() {
  return _allParameters.where((param) => param.groupId == null).toList();
}

List<BoilerParameter> _getParametersForGroup(int? groupId) {
  if (groupId == null || groupId == -1) {
    return _getParametersWithoutGroup();
  }
  return _allParameters.where((param) => param.groupId == groupId).toList();
}


  //IconData _getGroupIcon(String iconFileName) {
    // Маппинг имен файлов иконок на IconData
    // switch (iconFileName.toLowerCase()) {
    //   case 'temperature':
    //   case 'temp':
    //     return Icons.thermostat;
    //   case 'pressure':
    //     return Icons.speed;
    //   case 'flow':
    //   case 'water':
    //     return Icons.water_drop;
    //   case 'level':
    //     return Icons.height;
    //   case 'power':
    //   case 'energy':
    //     return Icons.bolt;
    //   case 'valve':
    //     return Icons.tune;
    //   case 'pump':
    //     return Icons.settings_input_component;
    //   default:
    //     return Icons.sensors;
    // }
  //}

  Color _parseGroupColor(String colorString) {
    // Парсинг цвета из строки (например, "#FF0000" или "red")
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      // Можно добавить обработку именованных цветов
      switch (colorString.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'cyan':
          return Colors.cyan;
        default:
          return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time.toLocal());
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
        return valueType;
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
          if (_allGroups.isNotEmpty) _buildGroupFilterChips(),
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
          BlinkingDot(color: _statusColor, size: 12,),
          // Container(
          //   width: 12,
          //   height: 12,
          //   decoration: BoxDecoration(
          //     color: _statusColor,
          //     shape: BoxShape.circle,
          //   ),
          //),
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
    final visibleGroups = _allGroups.where((group) {
      final parametersInGroup = _getParametersForGroup(group.id);
      return parametersInGroup.isNotEmpty;
    }).toList();

    if (visibleGroups.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: visibleGroups.length,
        itemBuilder: (context, index) {
          final group = visibleGroups[index];
          final parametersInGroup = _getParametersForGroup(group.id);
          final isVisible = _groupVisibility[group.id] ?? true;
          final groupColor = _parseGroupColor(group.color);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    //_getGroupIcon(group.iconFileName),
                    Icons.folder,
                    size: 16,
                    color: isVisible ? Colors.white : groupColor,
                  ),
                  const SizedBox(width: 4),
                  Text(group.name),
                  if (parametersInGroup.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVisible ? Colors.white24 : groupColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${parametersInGroup.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isVisible ? Colors.white : groupColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              selected: isVisible,
              selectedColor: groupColor,
              backgroundColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  _groupVisibility[group.id] = selected;
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
                  onPressed: _loadConfiguration,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        if (state is BoilerDetailConfigurationLoaded) {
          _allParameters = state.parameters;
          _allGroups = state.groups;
          _initializeGroupSettings();
          // Автоматически загружаем текущие значения
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadCurrentValues();
          });
          return _buildGroupsList();
        }

        if (state is BoilerDetailValuesLoaded) {
          _currentValues = state.values;
          _allParameters = state.parameters;
          _allGroups = state.groups;
          _buildParameterValueMap();
          _initializeGroupSettings();
          return _buildGroupsList();
        }

        // Поддержка старого состояния для совместимости
        if (state is BoilerDetailParametersLoaded) {
          _allParameters = state.parameters;
          _allGroups = state.groups;
          _initializeGroupSettings();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadCurrentValues();
          });
          return _buildGroupsList();
        }

        return const Center(child: Text('Инициализация...'));
      },
    );
  }

  Widget _buildGroupsList() {
  final parametersWithoutGroup = _getParametersWithoutGroup();
  
  // Получаем видимые реальные группы
  final visibleRealGroups = _allGroups.where((group) {
    final isVisible = _groupVisibility[group.id] ?? true;
    final parametersInGroup = _getParametersForGroup(group.id);
    return isVisible && parametersInGroup.isNotEmpty;
  }).toList();

  // Создаем список всех видимых групп
  List<Group> allVisibleGroups = [...visibleRealGroups];

  // Добавляем виртуальную группу "Другие" если есть параметры без группы
  if (parametersWithoutGroup.isNotEmpty) {
    final isOtherGroupVisible = _groupVisibility[-1] ?? true;
    if (isOtherGroupVisible) {
      allVisibleGroups.add(_otherGroup);
    }
  }

  if (allVisibleGroups.isEmpty) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Нет доступных групп параметров'),
          SizedBox(height: 8),
          Text(
            'Выберите группы для отображения или обновите данные',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(8),
    itemCount: allVisibleGroups.length,
    itemBuilder: (context, index) {
      return _buildGroupCard(allVisibleGroups[index]);
    },
  );
}

  Widget _buildGroupCard(Group group) {
    final parametersInGroup = _getParametersForGroup(group.id);
    if (parametersInGroup.isEmpty) return const SizedBox.shrink();

    final groupColor = _parseGroupColor(group.color);
    final isExpanded = _groupExpansion[group.id] ?? group.isExpanded;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _groupExpansion[group.id] = expanded;
          });
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: groupColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            //_getGroupIcon(group.iconFileName),
            Icons.folder,
            color: groupColor,
            size: 24,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${parametersInGroup.length} параметров • Нажмите на параметр для просмотра графика'),
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
            'ID: ${parameter.id} • Группа: ${parameter.groupId}',
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
            itemCount: _allGroups.length,
            itemBuilder: (context, index) {
              final group = _allGroups[index];
              final parametersInGroup = _getParametersForGroup(group.id);
              final isVisible = _groupVisibility[group.id] ?? true;
              final groupColor = _parseGroupColor(group.color);

              return CheckboxListTile(
                title: Row(
                  children: [
                    Icon(
                      //_getGroupIcon(group.iconFileName),
                      Icons.folder,
                      color: groupColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(group.name)),
                  ],
                ),
                subtitle: Text('${parametersInGroup.length} параметров'),
                value: isVisible,
                onChanged: parametersInGroup.isEmpty ? null : (value) {
                  setState(() {
                    _groupVisibility[group.id] = value ?? false;
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