import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/screens/parameter_chart_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/widgets/blinking_dot.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const background = Color(0xFFF5F5F5);
  static const error = Colors.red;
  static const warning = Colors.orange;
}

enum BoilerStatus { normal, warning, error }

class BoilerDetailScreen extends StatefulWidget {
  final int boilerId;
  final String boilerName;
  final String? districtName;

  const BoilerDetailScreen({
    super.key,
    required this.boilerId,
    required this.boilerName,
    this.districtName,
  });

  @override
  State<BoilerDetailScreen> createState() => _BoilerDetailScreenState();
}

class _BoilerDetailScreenState extends State<BoilerDetailScreen> {
  List<BoilerParameter> _allParameters = [];
  List<Group> _allGroups = [];
  Map<int, BoilerParameterValue> _parameterValueMap = {};
  Map<int, bool> _groupVisibility = {};
  Map<int, bool> _groupExpansion = {};
  BoilerStatus _boilerStatus = BoilerStatus.normal;
  
  // Переменные для управления группами параметров
  Map<int, bool> _selectedParameters = {};
  int? _selectedGroupId;
  bool _canManageParameters = false;

  static const _otherGroup = Group(
    id: -1,
    name: 'Другие',
    color: 'grey',
    iconFileName: 'other',
    isExpanded: false,
  );

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
    _checkPermissions();
  }

  void _checkPermissions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      setState(() {
        _canManageParameters = authState.userInfo.role?.canManageParameters ?? false;
      });
    }
  }

  void _loadConfiguration() {
    context
        .read<BoilerDetailBloc>()
        .add(LoadBoilerConfiguration(widget.boilerId));
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

  void _buildParameterValueMap(List<BoilerParameterValue> values) {
    _parameterValueMap.clear();
    for (var value in values) {
      _parameterValueMap[value.parameter.id] = value;
    }
  }

  void _initializeGroupSettings() {
    for (var group in _allGroups) {
      _groupVisibility[group.id] ??= true;
      _groupExpansion[group.id] ??= group.isExpanded;
    }

    // Инициализируем настройки для группы "Другие"
    _groupVisibility[-1] ??= true;
    _groupExpansion[-1] ??= _otherGroup.isExpanded;
  }

  List<BoilerParameter> _getParametersForGroup(int? groupId) {
    if (groupId == null || groupId == -1) {
      return _allParameters.where((param) => param.groupId == null).toList();
    }
    return _allParameters.where((param) => param.groupId == groupId).toList();
  }

  Color _parseGroupColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
            int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return switch (colorString.toLowerCase()) {
        'red' => Colors.red,
        'blue' => Colors.blue,
        'green' => Colors.green,
        'orange' => Colors.orange,
        'purple' => Colors.purple,
        'cyan' => Colors.cyan,
        _ => Colors.grey,
      };
    } catch (e) {
      return Colors.grey;
    }
  }

  String _translateParameterType(String valueType) {
    return switch (valueType.toLowerCase()) {
      'float' || 'double' => 'дробное',
      'int' || 'integer' => 'целое',
      'bool' || 'boolean' => 'логическое',
      'string' || 'text' => 'текстовое',
      'byte' => 'байт',
      'decimal' => 'десятичное',
      'long' => 'длинное целое',
      'short' => 'короткое целое',
      _ => valueType,
    };
  }

  Color get _statusColor => switch (_boilerStatus) {
        BoilerStatus.normal => AppColors.primaryLight,
        BoilerStatus.warning => AppColors.warning,
        BoilerStatus.error => AppColors.error,
      };

  String get _statusText => switch (_boilerStatus) {
        BoilerStatus.normal => 'В работе',
        BoilerStatus.warning => 'Внимание',
        BoilerStatus.error => 'Авария',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildStatusHeader(),
              // Показываем чипы только когда группы загружены
              if (_allGroups.isNotEmpty) _buildGroupFilterChips(),
              Expanded(child: _buildParameterGroupsContent(state)),
            ],
          );
        },
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
        // Показываем кнопку изменения группы только если есть права
        if (_canManageParameters)
          IconButton(
            icon: const Icon(Icons.add_to_photos),
            tooltip: 'Изменить группу параметров',
            onPressed: _showChangeGroupDialog,
          ),
      ],
    );
  }

  Widget _buildParameterGroupsContent(BoilerDetailState state) {
    return switch (state) {
      BoilerDetailLoadInProgress() =>
        const Center(child: CircularProgressIndicator()),
      BoilerDetailLoadFailure() => _buildErrorWidget(state.error),
      BoilerDetailConfigurationLoaded() => _handleConfigurationLoaded(state),
      BoilerDetailValuesLoaded() => _handleValuesLoaded(state),
      BoilerDetailParametersLoaded() => _handleParametersLoaded(state),
      _ => const Center(child: Text('Инициализация...')),
    };
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
          BlinkingDot(color: _statusColor, size: 12),
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
            'Обновлено: ${DateFormat('HH:mm:ss').format(DateTime.now().toLocal())}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips() {
    if (_allGroups.isEmpty) return const SizedBox.shrink();

    // Создаем список всех групп включая "Другие"
    final allGroupsWithOther = <Group>[..._allGroups];

    // Добавляем группу "Другие" только если есть параметры без группы
    final parametersWithoutGroup = _getParametersForGroup(-1);
    if (parametersWithoutGroup.isNotEmpty) {
      allGroupsWithOther.add(_otherGroup);
    }

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: allGroupsWithOther.length,
        itemBuilder: (context, index) {
          final group = allGroupsWithOther[index];
          final parametersCount = _getParametersForGroup(group.id).length;
          final isVisible = _groupVisibility[group.id] ?? true;
          final groupColor = _parseGroupColor(group.color);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder,
                    size: 16,
                    color: isVisible ? Colors.white : groupColor,
                  ),
                  const SizedBox(width: 4),
                  Text(group.name),
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVisible
                          ? Colors.white24
                          : groupColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$parametersCount',
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
        return switch (state) {
          BoilerDetailLoadInProgress() =>
            const Center(child: CircularProgressIndicator()),
          BoilerDetailLoadFailure() => _buildErrorWidget(state.error),
          BoilerDetailConfigurationLoaded() =>
            _handleConfigurationLoaded(state),
          BoilerDetailValuesLoaded() => _handleValuesLoaded(state),
          BoilerDetailParametersLoaded() => _handleParametersLoaded(state),
          _ => const Center(child: Text('Инициализация...')),
        };
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Ошибка загрузки: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConfiguration,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _handleConfigurationLoaded(BoilerDetailConfigurationLoaded state) {
    _allParameters = state.parameters;
    _allGroups = state.groups;
    _initializeGroupSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentValues());
    return _buildGroupsList();
  }

  Widget _handleValuesLoaded(BoilerDetailValuesLoaded state) {
    _allParameters = state.parameters;
    _allGroups = state.groups;
    _buildParameterValueMap(state.values);
    _initializeGroupSettings();
    return _buildGroupsList();
  }

  Widget _handleParametersLoaded(BoilerDetailParametersLoaded state) {
    _allParameters = state.parameters;
    _allGroups = state.groups;
    _initializeGroupSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentValues());
    return _buildGroupsList();
  }

  Widget _buildGroupsList() {
    final parametersWithoutGroup = _getParametersForGroup(-1);
    final visibleGroups = _allGroups
        .where((group) => _groupVisibility[group.id] ?? true)
        .toList();

    if (parametersWithoutGroup.isNotEmpty && (_groupVisibility[-1] ?? true)) {
      visibleGroups.add(_otherGroup);
    }

    if (visibleGroups.isEmpty) {
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
      itemCount: visibleGroups.length,
      itemBuilder: (context, index) => _buildGroupCard(visibleGroups[index]),
    );
  }

  Widget _buildGroupCard(Group group) {
    final parametersInGroup = _getParametersForGroup(group.id);
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
          child: Icon(Icons.folder, color: groupColor, size: 24),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          parametersInGroup.isEmpty
              ? 'Нет параметров в группе'
              : '${parametersInGroup.length} параметров • Нажмите на параметр для просмотра графика',
        ),
        children: parametersInGroup.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'В данной группе пока нет параметров',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              ]
            : parametersInGroup
                .map((parameter) => _buildParameterTile(
                    parameter, _parameterValueMap[parameter.id]))
                .toList(),
      ),
    );
  }

  Widget _buildParameterTile(
      BoilerParameter parameter, BoilerParameterValue? value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: () => _openParameterChart(parameter),
      title: Text(
        parameter.name.isNotEmpty
            ? parameter.name
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
            'ID: ${parameter.id} • Группа: ${parameter.groupId ?? "Нет"}',
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
          Icon(Icons.show_chart, size: 20, color: Colors.grey[400]),
        ],
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

  void _showGroupManagementDialog() {
    // Создаем список всех групп включая "Другие"
    final allGroupsWithOther = <Group>[..._allGroups];
    final parametersWithoutGroup = _getParametersForGroup(-1);
    if (parametersWithoutGroup.isNotEmpty) {
      allGroupsWithOther.add(_otherGroup);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Управление группами'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allGroupsWithOther.length,
            itemBuilder: (context, index) {
              final group = allGroupsWithOther[index];
              final parametersCount = _getParametersForGroup(group.id).length;
              final isVisible = _groupVisibility[group.id] ?? true;
              final groupColor = _parseGroupColor(group.color);

              return CheckboxListTile(
                title: Row(
                  children: [
                    Icon(Icons.folder, color: groupColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(group.name)),
                  ],
                ),
                subtitle: Text('$parametersCount параметров'),
                value: isVisible,
                onChanged: (value) {
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

  // Новый метод для отображения диалога изменения группы параметров
  // Добавим переменную для хранения текста поиска

String _searchQuery = '';
// Обновленный метод для отображения диалога изменения группы параметров
// Обновленный метод для отображения диалога изменения группы параметров
void _showChangeGroupDialog() {
  // Сбрасываем выбранные параметры, группу и поисковый запрос
  setState(() {
    _selectedParameters = {};
    _selectedGroupId = null;
    _searchQuery = '';
  });
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        // Фильтруем параметры по поисковому запросу
        final filteredParameters = _searchQuery.isEmpty
            ? _allParameters
            : _allParameters.where((param) => 
                param.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
        // Проверяем, все ли отфильтрованные параметры выбраны
        bool areAllSelected = filteredParameters.isNotEmpty && 
            filteredParameters.every((param) => _selectedParameters[param.id] == true);
        
        return AlertDialog(
          title: const Text('Изменение группы параметров'),
          content: SizedBox(
            width: double.maxFinite,
            height: 800,
            child: Column(
              children: [
                // Добавляем строку поиска
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск параметров...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Строка с информацией о количестве и кнопкой "Выбрать все"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Найдено параметров: ${filteredParameters.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (filteredParameters.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            // Если все выбраны - снимаем выбор, иначе - выбираем все
                            final newValue = !areAllSelected;
                            for (var param in filteredParameters) {
                              _selectedParameters[param.id] = newValue;
                            }
                          });
                        },
                        icon: Icon(
                          areAllSelected ? Icons.deselect : Icons.select_all,
                          size: 18,
                        ),
                        label: Text(areAllSelected ? 'Снять выбор' : 'Выбрать все'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Список параметров
                Expanded(
                  child: filteredParameters.isEmpty
                      ? Center(
                          child: Text(
                            'Параметры не найдены',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredParameters.length,
                          itemBuilder: (context, index) {
                            final parameter = filteredParameters[index];
                            final isSelected = _selectedParameters[parameter.id] ?? false;
                            
                            return CheckboxListTile(
                              title: Text(parameter.name.isNotEmpty 
                                ? parameter.name 
                                : 'Параметр ID: ${parameter.id}'),
                              subtitle: Text('Группа: ${_getGroupName(parameter.groupId)}'),
                              value: isSelected,
                              onChanged: (value) {
                                setDialogState(() {
                                  _selectedParameters[parameter.id] = value ?? false;
                                });
                              },
                            );
                          },
                        ),
                ),
                
                const SizedBox(height: 16),
                const Text('Выберите новую группу:'),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  isExpanded: true,
                  hint: const Text('Выберите группу'),
                  value: _selectedGroupId,
                  items: _allGroups.map((group) {
                    return DropdownMenuItem<int>(
                      value: group.id,
                      child: Text(group.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedGroupId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: _getSelectedParameterIds().isEmpty || _selectedGroupId == null
                ? null
                : () {
                  print('==== onPressed ${_getSelectedParameterIds()}');
                    _updateParametersGroup();
                    Navigator.pop(context);
                  },
              child: const Text('Изменить группу'),
            ),
          ],
        );
      },
    ),
  );
}

  // Метод для получения имени группы по ID
  String _getGroupName(int? groupId) {
    if (groupId == null) return 'Без группы';
    
    try {
      return _allGroups.firstWhere((g) => g.id == groupId).name;
    } catch (e) {
      return 'Группа $groupId';
    }
  }

  // Метод для получения списка ID выбранных параметров
  List<int> _getSelectedParameterIds() {
    return _selectedParameters.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  }

  // Метод для вызова обновления группы параметров
  void _updateParametersGroup() {
    final selectedIds = _getSelectedParameterIds();
    if (selectedIds.isEmpty || _selectedGroupId == null) return;

    print('==== в блоке  selectedIds = ${selectedIds}, _selectedGroupId = ${_selectedGroupId}');
    
    // Добавляем новое событие в блок
    context.read<BoilerDetailBloc>().add(
      UpdateParametersGroup(
        groupId: _selectedGroupId!,
        parameterIds: selectedIds,
      )
    );
    
    // Показываем сообщение
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Группа параметров обновляется...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}