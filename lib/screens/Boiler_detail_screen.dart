import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/screens/parameter_chart_screen.dart';
import 'package:manage_center/services/signalr_service.dart';
import 'package:manage_center/theme/app_theme.dart';
import 'package:manage_center/utils/parameter_utils.dart';
import 'package:manage_center/widgets/blinking_dot.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/widgets/detailed_screen/boiler_status_header.dart';

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

  // Инциденты: id аварийных параметров и групп
  Set<int> _incidentParameterIds = {};
  Set<int> _incidentGroupIds = {};

  // Переменные для диалога изменения группы
  Map<int, bool> _selectedParameters = {};
  int? _selectedGroupId;

  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  late final VoidCallback _signalRListener;

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

    _signalRListener = () {
      final updatedBoilerId = boilerParamsUpdateNotifier.value;
      if (updatedBoilerId == widget.boilerId && mounted) {
        context.read<BoilerDetailBloc>().add(
              SignalRParametersUpdated(updatedBoilerId!, {}),
            );
      }
    };
    boilerParamsUpdateNotifier.addListener(_signalRListener);

    _updateBoilerStatusFromBoilersBloc();
    _refreshRealtimeStatus();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    boilerParamsUpdateNotifier.removeListener(_signalRListener);
    super.dispose();
  }

  Future<void> _refreshRealtimeStatus() async {
    try {
      final details =
          await context.read<ApiService>().getBoilerById(widget.boilerId);

      if (mounted) {
        setState(() {
          if (details.isEmergency) {
            _boilerStatus = BoilerStatus.error;
          } else if (!details.hasConnection) {
            _boilerStatus = BoilerStatus.warning;
          } else {
            _boilerStatus = BoilerStatus.normal;
          }
        });
      }
    } catch (e) {
      print('Не удалось обновить статус котельной: $e');
    }
  }

  void _checkPermissions() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      setState(() {
        _canManageParameters =
            authState.userInfo.role?.canManageParameters ?? false;
      });
    }
  }

  Future<void> _loadConfiguration() async {
    context
        .read<BoilerDetailBloc>()
        .add(LoadBoilerConfiguration(widget.boilerId));
  }

  Future<void> _loadCurrentValues() async {
    await _refreshRealtimeStatus();

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

  void _updateBoilerStatusFromBoilersBloc() {
    final boilersState = context.read<BoilersBloc>().state;
    if (boilersState is BoilersLoadSuccess) {
      try {
        final boiler =
            boilersState.boilers.firstWhere((b) => b.id == widget.boilerId);
        setState(() {
          if (boiler.isEmergency) {
            _boilerStatus = BoilerStatus.error;
          } else if (!boiler.hasConnection) {
            _boilerStatus = BoilerStatus.warning;
          } else {
            _boilerStatus = BoilerStatus.normal;
          }
        });
      } catch (e) {
        // Котельная не найдена в списке
      }
    }
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

  Color get _statusColor => switch (_boilerStatus) {
        BoilerStatus.normal => context.appColors.success,
        BoilerStatus.warning => context.appColors.warning,
        BoilerStatus.error => context.colors.error,
      };

  String get _statusText => switch (_boilerStatus) {
        BoilerStatus.normal => 'В работе',
        BoilerStatus.warning => 'Нет связи',
        BoilerStatus.error => 'Требуется внимание',
      };

  bool _hasEmergencyInGroup(Group group) {
    // Подсветка через инциденты (любая группа)
    if (_incidentGroupIds.contains(group.id)) return true;

    // Старая логика для группы "авария" через значения параметров
    if (group.name.toLowerCase() == 'авария') {
      final parametersInGroup = _getParametersForGroup(group.id);
      for (var parameter in parametersInGroup) {
        final value = _parameterValueMap[parameter.id];
        if (value != null && value.displayValue.toLowerCase() == 'да') {
          return true;
        }
      }
    }
    return false;
  }

  bool _isEmergencyParameter(BoilerParameter parameter) {
    // Подсветка через инциденты (любой параметр)
    if (_incidentParameterIds.contains(parameter.id)) return true;

    // Старая логика для группы "авария" через значения параметров
    final group = _allGroups.firstWhere(
      (g) => g.id == parameter.groupId,
      orElse: () => _otherGroup,
    );
    if (group.name.toLowerCase() != 'авария') return false;
    final value = _parameterValueMap[parameter.id];
    return value != null && value.displayValue.toLowerCase() == 'да';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadCurrentValues,
        color: context.colors.primary,
        child: BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: BoilerStatusHeader(
                    statusColor: _statusColor,
                    statusText: _statusText,
                    parametersCount: _allParameters.length,
                  ),
                ),
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Шапка красится в цвет статуса. Жёлтое «нет связи» под белым текстом
    // нечитаемо, поэтому затемняем саму подложку, а не меняем цвет надписи.
    final background = AppTheme.solidAccent(_statusColor);

    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.boilerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSolidAccent,
            ),
          ),
          if (widget.districtName != null)
            Text(
              widget.districtName!,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.onSolidAccent.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      centerTitle: true,
      backgroundColor: background,
      foregroundColor: AppTheme.onSolidAccent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune, color: AppTheme.onSolidAccent),
          tooltip: 'Управление группами',
          onPressed: _showGroupManagementDialog,
        ),
        if (_canManageParameters)
          IconButton(
            icon: const Icon(Icons.edit_attributes,
                color: AppTheme.onSolidAccent),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Загрузка данных...',
            style: TextStyle(color: context.colors.onSurfaceVariant),
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
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allGroupsWithOther.length,
        itemBuilder: (context, index) {
          final group = allGroupsWithOther[index];
          final parametersCount = _getParametersForGroup(group.id).length;
          final isVisible = _groupVisibility[group.id] ?? true;
          // Цвет группы приходит из API и может быть каким угодно —
          // приводим его к читаемому на текущей теме варианту.
          final rawColor = ParameterUtils.parseGroupColor(
            group.color,
            fallback: context.colors.onSurfaceVariant,
          );
          final groupColor =
              AppTheme.accentOnSurface(rawColor, Theme.of(context).brightness);
          final selectedColor = AppTheme.solidAccent(rawColor);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 18,
                    color: isVisible ? AppTheme.onSolidAccent : groupColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isVisible ? AppTheme.onSolidAccent : groupColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVisible
                          ? AppTheme.onSolidAccent.withValues(alpha: 0.24)
                          : groupColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$parametersCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: isVisible ? AppTheme.onSolidAccent : groupColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              selected: isVisible,
              showCheckmark: false,
              selectedColor: selectedColor,
              backgroundColor: context.isDark
                  ? context.colors.surfaceContainerHigh
                  : context.colors.surface,
              side: BorderSide(color: context.colors.outlineVariant),
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
    final colors = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.isDark ? colors.surfaceContainer : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: context.isDark
              ? Border.all(color: colors.outlineVariant)
              : null,
          boxShadow: [
            BoxShadow(
              color: context.appColors.cardShadow,
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
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: colors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadConfiguration,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    _incidentParameterIds = state.incidentParameterIds;
    _incidentGroupIds = state.incidentGroupIds;
    _initializeGroupSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentValues());
    return _buildGroupsList();
  }

  Widget _handleValuesLoaded(BoilerDetailValuesLoaded state) {
    _allParameters = state.parameters;
    _allGroups = state.groups;
    _incidentParameterIds = state.incidentParameterIds;
    _incidentGroupIds = state.incidentGroupIds;
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 86),
      itemCount: visibleGroups.length,
      itemBuilder: (context, index) => _buildGroupCard(visibleGroups[index]),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.isDark ? colors.surfaceContainer : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: context.isDark
              ? Border.all(color: colors.outlineVariant)
              : null,
          boxShadow: [
            BoxShadow(
              color: context.appColors.cardShadow,
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
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет доступных групп параметров',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите группы для отображения или обновите данные',
              style: TextStyle(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    final colors = context.colors;
    final parametersInGroup = _getParametersForGroup(group.id);
    final groupColor = AppTheme.accentOnSurface(
      ParameterUtils.parseGroupColor(
        group.color,
        fallback: colors.onSurfaceVariant,
      ),
      Theme.of(context).brightness,
    );
    final isExpanded = _groupExpansion[group.id] ?? group.isExpanded;
    final hasEmergency = _hasEmergencyInGroup(group);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.isDark ? colors.surfaceContainer : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: context.isDark
            ? Border.all(color: colors.outlineVariant)
            : null,
        boxShadow: [
          BoxShadow(
            color: context.appColors.cardShadow,
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
            color: groupColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.folder_rounded,
            color: groupColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (hasEmergency) ...[
              const SizedBox(width: 8),
              BlinkingDot(color: colors.error, size: 12),
            ],
          ],
        ),
        subtitle: Text(
          parametersInGroup.isEmpty
              ? 'Нет параметров в группе'
              : '${parametersInGroup.length} параметров • Нажмите для просмотра графика',
          style: TextStyle(
            color: colors.onSurfaceVariant,
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
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildParameterTile(
      BoilerParameter parameter, BoilerParameterValue? value) {
    final colors = context.colors;
    final isEmergency = _isEmergencyParameter(parameter);
    // Авария → красный, есть свежее значение → зелёный, нет данных → нейтральный.
    final valueColor = isEmergency
        ? colors.error
        : (value != null
            ? context.appColors.success
            : colors.onSurfaceVariant);
    final valueBgColor = valueColor.withValues(alpha: 0.12);
    final valueBorderColor = valueColor.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.neutralSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openParameterChart(parameter),
        title: Text(
          parameter.name.isNotEmpty
              ? parameter.name
              : 'Параметр ID: ${parameter.id}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ParameterUtils.translateParameterType(parameter.valueType),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  'ID: ${parameter.id}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
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
                color: valueBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: valueBorderColor),
              ),
              child: Text(
                value != null
                    ? ParameterUtils.formatValue(
                        value.displayValue, parameter.valueType)
                    : 'Нет данных',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.trending_up_rounded,
              size: 20,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
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
              final groupColor = AppTheme.accentOnSurface(
                ParameterUtils.parseGroupColor(
                  group.color,
                  fallback: context.colors.onSurfaceVariant,
                ),
                Theme.of(context).brightness,
              );

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
                activeColor: context.colors.primary,
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
              : _allParameters
                  .where((param) => param.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          bool areAllSelected = filteredParameters.isNotEmpty &&
              filteredParameters
                  .every((param) => _selectedParameters[param.id] == true);

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.onSurfaceVariant,
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
                          label: Text(
                              areAllSelected ? 'Снять выбор' : 'Выбрать все'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredParameters.isEmpty
                        ? Center(
                            child: Text(
                              'Параметры не найдены',
                              style: TextStyle(
                                  color: context.colors.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredParameters.length,
                            itemBuilder: (context, index) {
                              final parameter = filteredParameters[index];
                              final isSelected =
                                  _selectedParameters[parameter.id] ?? false;

                              return CheckboxListTile(
                                title: Text(parameter.name.isNotEmpty
                                    ? parameter.name
                                    : 'Параметр ID: ${parameter.id}'),
                                subtitle: Text(
                                    'Группа: ${_getGroupName(parameter.groupId)}'),
                                value: isSelected,
                                activeColor: context.colors.primary,
                                onChanged: (value) {
                                  setDialogState(() {
                                    _selectedParameters[parameter.id] =
                                        value ?? false;
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                onPressed: _getSelectedParameterIds().isEmpty ||
                        _selectedGroupId == null
                    ? null
                    : () {
                        _updateParametersGroup();
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
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

    context.read<BoilerDetailBloc>().add(UpdateParametersGroup(
          groupId: _selectedGroupId!,
          parameterIds: selectedIds,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Группа параметров обновляется...',
          style: TextStyle(color: context.colors.onPrimary),
        ),
        backgroundColor: context.colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
