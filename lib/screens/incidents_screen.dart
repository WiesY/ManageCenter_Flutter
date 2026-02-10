// incidents_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/incidents_bloc.dart';
import 'package:manage_center/models/incident_model.dart';

class AppColors {
  static const primary = Colors.blue;
  static const primaryLight = Colors.lightBlue;
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFE53E3E);
  static const warning = Color(0xFFFF8C00);
  static const success = Colors.green;
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const archived = Color(0xFF9E9E9E);
}

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ВАЖНО:
    // IncidentsBloc должен быть предоставлен выше по дереву (в MainNavigationScreen),
    // чтобы экран и бейдж в навигации использовали один и тот же bloc.
    return const _IncidentsScreenContent();
  }
}

class _IncidentsScreenContent extends StatefulWidget {
  const _IncidentsScreenContent();

  @override
  State<_IncidentsScreenContent> createState() => _IncidentsScreenContentState();
}

class _IncidentsScreenContentState extends State<_IncidentsScreenContent> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showFloatingSearch) {
      setState(() {
        _showFloatingSearch = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: BlocBuilder<IncidentsBloc, IncidentsState>(
        builder: (context, state) {
          if (state is IncidentsInitialState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is IncidentsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is IncidentsLoadedState) {
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<IncidentsBloc>().add(IncidentsRefreshEvent());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    thickness: 6,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildActiveIncidentsCounter(context, state),
                          const SizedBox(height: 6),
                          _buildStatusToggle(context, state),
                          const SizedBox(height: 16),
                          _buildBoilerFilter(context, state),
                          const SizedBox(height: 16),
                          _buildIncidentsList(context, state),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showFloatingSearch) _buildFloatingSearch(context, state),
              ],
            );
          } else if (state is IncidentsErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Ошибка',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<IncidentsBloc>().add(IncidentsInitEvent());
                    },
                    child: const Text('Назад'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFloatingSearch(BuildContext context, IncidentsLoadedState state) {
    final controller = TextEditingController(text: state.boilerSearchQuery);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withOpacity(0.95),
              AppColors.background.withOpacity(0.8),
              AppColors.background.withOpacity(0.0),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: controller,
            onChanged: (value) {
              context
                  .read<IncidentsBloc>()
                  .add(IncidentsSearchBoilerEvent(value));
            },
            decoration: InputDecoration(
              hintText: 'Введите название объекта...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: state.boilerSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textSecondary),
                      onPressed: () {
                        controller.clear();
                        context
                            .read<IncidentsBloc>()
                            .add(IncidentsSearchBoilerEvent(''));
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_upward,
                          color: AppColors.primary),
                      onPressed: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Журнал аварий'),
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(0, 255, 255, 255),
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          tooltip: 'Обновить',
          onPressed: () {
            context.read<IncidentsBloc>().add(IncidentsRefreshEvent());
          },
        ),
        IconButton(
          icon: const Icon(Icons.date_range, color: Colors.black),
          tooltip: 'Фильтр по дате',
          onPressed: () => _selectDateRange(context),
        ),
      ],
    );
  }

  Widget _buildActiveIncidentsCounter(
      BuildContext context, IncidentsLoadedState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: state.activeIncidentsCount > 0
            ? AppColors.error.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.activeIncidentsCount > 0
              ? AppColors.error.withOpacity(0.2)
              : AppColors.success.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.activeIncidentsCount > 0 ? Icons.warning : Icons.check_circle,
            color: state.activeIncidentsCount > 0
                ? AppColors.error
                : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Активных аварий: ${state.activeIncidentsCount}',
            style: TextStyle(
              color: state.activeIncidentsCount > 0
                  ? AppColors.error
                  : AppColors.success,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(BuildContext context, IncidentsLoadedState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Статус',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 18,
                        color: state.showActive ? Colors.white : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Активные',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color:
                              state.showActive ? Colors.white : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  selected: state.showActive,
                  selectedColor: AppColors.error,
                  backgroundColor: AppColors.surface,
                  elevation: state.showActive ? 4 : 2,
                  onSelected: (selected) {
                    if (selected) {
                      context
                          .read<IncidentsBloc>()
                          .add(IncidentsToggleStatusEvent(true));
                    }
                  },
                ),
              ),
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.archive,
                      size: 18,
                      color: !state.showActive
                          ? Colors.white
                          : AppColors.archived,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Архивные',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: !state.showActive
                            ? Colors.white
                            : AppColors.archived,
                      ),
                    ),
                  ],
                ),
                selected: !state.showActive,
                selectedColor: AppColors.archived,
                backgroundColor: AppColors.surface,
                elevation: !state.showActive ? 4 : 2,
                onSelected: (selected) {
                  if (selected) {
                    context
                        .read<IncidentsBloc>()
                        .add(IncidentsToggleStatusEvent(false));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoilerFilter(BuildContext context, IncidentsLoadedState state) {
    if (_showFloatingSearch) {
      return const SizedBox.shrink();
    }

    final controller = TextEditingController(text: state.boilerSearchQuery);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Поиск по объекту',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            onChanged: (value) {
              context
                  .read<IncidentsBloc>()
                  .add(IncidentsSearchBoilerEvent(value));
            },
            decoration: InputDecoration(
              hintText: 'Введите название объекта...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: state.boilerSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textSecondary),
                      onPressed: () {
                        controller.clear();
                        context
                            .read<IncidentsBloc>()
                            .add(IncidentsSearchBoilerEvent(''));
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentsList(BuildContext context, IncidentsLoadedState state) {
    final filteredIncidents = state.boilerSearchQuery.isEmpty
        ? state.incidents
        : state.incidents.where((incident) {
            return incident.boilerName
                .toLowerCase()
                .startsWith(state.boilerSearchQuery.toLowerCase());
          }).toList();

    if (filteredIncidents.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
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
          children: [
            Icon(
              state.boilerSearchQuery.isEmpty
                  ? Icons.check_circle_outline
                  : Icons.search_off,
              size: 64,
              color: AppColors.success.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              state.boilerSearchQuery.isEmpty
                  ? (state.showActive
                      ? 'Нет активных аварий'
                      : 'Нет архивных аварий')
                  : 'Ничего не найдено',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.boilerSearchQuery.isEmpty
                  ? (state.showActive
                      ? 'Все системы работают в штатном режиме'
                      : 'Архив аварий пуст')
                  : 'Попробуйте изменить поисковый запрос',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Найдено: ${filteredIncidents.length}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...filteredIncidents.map(
            (incident) =>
                _buildIncidentCard(context, incident, state.showActive),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(
      BuildContext context, IncidentModel incident, bool isActive) {
    final cardColor = isActive ? AppColors.error : AppColors.archived;

    final authState = context.read<AuthBloc>().state;
    final int? roleID =
        authState is AuthSuccess ? authState.userInfo.role?.id : null;

    final bool canResetIncident = roleID == 1 || roleID == 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.3),
          width: 2,
        ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive ? Icons.warning : Icons.archive,
                    color: cardColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.boilerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'ID: ${incident.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'АКТИВНА' : 'АРХИВ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.settings,
                  'Параметр',
                  incident.parameterName,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.description,
                  'Описание',
                  incident.description,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'Время начала',
                  DateFormat('dd.MM.yyyy HH:mm')
                      .format(incident.startTime.toLocal()),
                ),
                if (!isActive && incident.resetTime != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.check_circle,
                    'Время сброса',
                    DateFormat('dd.MM.yyyy HH:mm')
                        .format(incident.resetTime!.toLocal()),
                  ),
                ],
                if (!isActive && incident.resetUserName != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.person,
                    'Сброшено пользователем',
                    incident.resetUserName!,
                  ),
                ],
                if (isActive && canResetIncident) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showResetConfirmation(context, incident),
                      icon: const Icon(Icons.archive),
                      label: const Text('Сбросить аварию'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (isActive && !canResetIncident) ...[
                  const SizedBox.shrink()
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showResetConfirmation(
      BuildContext context, IncidentModel incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text(
          'Вы уверены, что хотите сбросить аварию "${incident.description}" в архив?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<IncidentsBloc>().add(IncidentsResetEvent(incident.id));
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final state = context.read<IncidentsBloc>().state;
    if (state is! IncidentsLoadedState) return;

    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: state.fromDate != null && state.toDate != null
          ? DateTimeRange(start: state.fromDate!, end: state.toDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      final fromDate = DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day,
        0,
        0,
        0,
      );

      final toDate = DateTime(
        dateRange.end.year,
        dateRange.end.month,
        dateRange.end.day,
        23,
        59,
        59,
        999,
      );

      context.read<IncidentsBloc>().add(
            IncidentsSelectDateRangeEvent(
              fromDate: fromDate,
              toDate: toDate,
            ),
          );
    }
  }
}