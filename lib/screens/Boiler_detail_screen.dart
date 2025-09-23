import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/screens/parameter_chart_screen.dart';
import 'package:manage_center/widgets/blinking_dot.dart';

class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF4CAF50);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFE53E3E);
  static const warning = Color(0xFFFF8C00);
  static const success = Colors.green;
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
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

class _BoilerDetailScreenState extends State<BoilerDetailScreen>
    with TickerProviderStateMixin {
  List<BoilerParameter> _allParameters = [];
  List<Group> _allGroups = [];
  Map<int, BoilerParameterValue> _parameterValueMap = {};
  Map<int, bool> _groupVisibility = {};
  Map<int, bool> _groupExpansion = {};
  BoilerStatus _boilerStatus = BoilerStatus.normal;
  bool _canManageParameters = false;
  String _searchQuery = '';
  
  // Переменные для диалога изменения группы
  Map<int, bool> _selectedParameters = {};
  int? _selectedGroupId;

  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  static const _otherGroup = Group(
    id: -1,
    name: 'Другие',
    color: '#9E9E9E',
    iconFileName: 'other',
    isExpanded: false,
  );

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
    _loadConfiguration();
    _checkPermissions();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _checkPermissions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      setState(() {
        _canManageParameters = authState.userInfo.role?.canManageParameters ?? false;
      });
    }
  }

  Future<void> _loadConfiguration() async {
    context.read<BoilerDetailBloc>().add(LoadBoilerConfiguration(widget.boilerId));
  }

  Future<void> _loadCurrentValues() async {
    _refreshController.forward().then((_) => _refreshController.reverse());
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
        String hexColor = colorString.substring(1, 7);
        return Color(int.parse(hexColor, radix: 16) + 0xFF000000);
      }
      return AppColors.textSecondary;
    } catch (e) {
      return AppColors.textSecondary;
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
    BoilerStatus.normal => AppColors.success,
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
      body: RefreshIndicator(
        onRefresh: _loadCurrentValues,
        color: AppColors.primary,
        child: BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildStatusHeader()),
                if (_allGroups.isNotEmpty)
                  SliverToBoxAdapter(child: _buildGroupFilterChips()),
                SliverFillRemaining(
                  child: _buildParameterGroupsContent(state),
                ),
              ],
            );
          },
        ),
      ),
      // floatingActionButton: AnimatedBuilder(
      //   animation: _refreshAnimation,
      //   builder: (context, child) {
      //     return FloatingActionButton(
      //       onPressed: _loadCurrentValues,
      //       backgroundColor: AppColors.primary,
      //       elevation: 8,
      //       child: Transform.rotate(
      //         angle: _refreshAnimation.value * 2 * 3.14159,
      //         child: const Icon(Icons.refresh, color: Colors.white),
      //       ),
      //     );
      //   },
      // ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.boilerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (widget.districtName != null)
            Text(
              widget.districtName!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      centerTitle: true,
      backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,

      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          tooltip: 'Управление группами',
          onPressed: _showGroupManagementDialog,
        ),
        if (_canManageParameters)
          IconButton(
            icon: const Icon(Icons.edit_attributes, color: Colors.white),
            tooltip: 'Изменить группу параметров',
            onPressed: _showChangeGroupDialog,
          ),
      ],
    );
  }

  Widget _buildParameterGroupsContent(BoilerDetailState state) {
    return switch (state) {
      BoilerDetailLoadInProgress() => _buildLoadingWidget(),
      BoilerDetailLoadFailure() => _buildErrorWidget(state.error),
      BoilerDetailConfigurationLoaded() => _handleConfigurationLoaded(state),
      BoilerDetailValuesLoaded() => _handleValuesLoaded(state),
      BoilerDetailParametersLoaded() => _handleParametersLoaded(state),
      _ => _buildLoadingWidget(),
    };
  }

  Widget _buildLoadingWidget() {
    return const Center(
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
    );
  }

  Widget _buildStatusHeader() {
    // Получаем общее количество параметров
    final totalParametersCount = _allParameters.length;
    
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: BlinkingDot(color: _statusColor, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Обновлено: ${DateFormat('HH:mm:ss').format(DateTime.now().toLocal())}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Всего параметров: $totalParametersCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips() {
    if (_allGroups.isEmpty) return const SizedBox.shrink();

    final allGroupsWithOther = <Group>[..._allGroups];
    final parametersWithoutGroup = _getParametersForGroup(-1);
    if (parametersWithoutGroup.isNotEmpty) {
      allGroupsWithOther.add(_otherGroup);
    }

    return Container(
      height: 60,
      //margin: const EdgeInsets.only(bottom: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allGroupsWithOther.length,
        itemBuilder: (context, index) {
          final group = allGroupsWithOther[index];
          final parametersCount = _getParametersForGroup(group.id).length;
          final isVisible = _groupVisibility[group.id] ?? true;
          final groupColor = _parseGroupColor(group.color);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 18,
                    color: isVisible ? Colors.white : groupColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isVisible ? Colors.white : groupColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVisible ? Colors.white24 : groupColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$parametersCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: isVisible ? Colors.white : groupColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isVisible,
              selectedColor: groupColor,
              backgroundColor: AppColors.surface,
              elevation: isVisible ? 4 : 2,
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadConfiguration,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
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
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleGroups.length,
      itemBuilder: (context, index) => _buildGroupCard(visibleGroups[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет доступных групп параметров',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите группы для отображения или обновите данные',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    final parametersInGroup = _getParametersForGroup(group.id);
    final groupColor = _parseGroupColor(group.color);
    final isExpanded = _groupExpansion[group.id] ?? group.isExpanded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _groupExpansion[group.id] = expanded;
          });
        },
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: groupColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder_rounded,
            color: groupColor,
            size: 24,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          parametersInGroup.isEmpty
              ? 'Нет параметров в группе'
              : '${parametersInGroup.length} параметров • Нажмите для просмотра графика',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        children: parametersInGroup.isEmpty
            ? [_buildEmptyGroupMessage()]
            : parametersInGroup
                .map((parameter) => _buildParameterTile(
                    parameter, _parameterValueMap[parameter.id]))
                .toList(),
      ),
    );
  }

  Widget _buildEmptyGroupMessage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'В данной группе пока нет параметров',
        style: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildParameterTile(BoilerParameter parameter, BoilerParameterValue? value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openParameterChart(parameter),
        title: Text(
          parameter.name.isNotEmpty
              ? parameter.name
              : 'Параметр ID: ${parameter.id}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _translateParameterType(parameter.valueType),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ID: ${parameter.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: value != null ? AppColors.success.withOpacity(0.1) : AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: value != null ? AppColors.success.withOpacity(0.3) : AppColors.textSecondary.withOpacity(0.3),
                ),
              ),
              child: Text(
                value?.displayValue ?? 'Нет данных',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: value != null ? AppColors.success : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.trending_up_rounded,
              size: 20,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ],
        ),
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
    final allGroupsWithOther = <Group>[..._allGroups];
    final parametersWithoutGroup = _getParametersForGroup(-1);
    if (parametersWithoutGroup.isNotEmpty) {
      allGroupsWithOther.add(_otherGroup);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Управление группами',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                    Icon(Icons.folder_rounded, color: groupColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(group.name)),
                  ],
                ),
                subtitle: Text('$parametersCount параметров'),
                value: isVisible,
                activeColor: AppColors.primary,
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

  void _showChangeGroupDialog() {
    setState(() {
      _selectedParameters = {};
      _selectedGroupId = null;
      _searchQuery = '';
    });
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredParameters = _searchQuery.isEmpty
              ? _allParameters
              : _allParameters.where((param) => 
                  param.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          
          bool areAllSelected = filteredParameters.isNotEmpty && 
              filteredParameters.every((param) => _selectedParameters[param.id] == true);
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Изменение группы параметров',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 600,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Поиск параметров...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Найдено: ${filteredParameters.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (filteredParameters.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
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
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: filteredParameters.isEmpty
                        ? const Center(
                            child: Text(
                              'Параметры не найдены',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
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
                                activeColor: AppColors.primary,
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Выберите новую группу:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
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
                      _updateParametersGroup();
                      Navigator.pop(context);
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Изменить группу'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getGroupName(int? groupId) {
    if (groupId == null) return 'Без группы';
    try {
      return _allGroups.firstWhere((g) => g.id == groupId).name;
    } catch (e) {
      return 'Группа $groupId';
    }
  }

  List<int> _getSelectedParameterIds() {
    return _selectedParameters.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();
  }

  void _updateParametersGroup() {
    final selectedIds = _getSelectedParameterIds();
    if (selectedIds.isEmpty || _selectedGroupId == null) return;
    
    context.read<BoilerDetailBloc>().add(
      UpdateParametersGroup(
        groupId: _selectedGroupId!,
        parameterIds: selectedIds,
      )
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Группа параметров обновляется...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}