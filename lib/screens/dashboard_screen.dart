// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/screens/boiler_detail_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/theme/app_theme.dart';
import 'package:manage_center/widgets/blinking_dot.dart';
import 'package:manage_center/widgets/logout_confirmation_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  String _statusFilter = 'all'; // all | online | alarm | offline

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showLogoutConfirmationDialog(context);
  }

  List<BoilerListItem> _filterBoilers(List<BoilerListItem> boilers) {
    var result = boilers;

    // Фильтр по статусу
    switch (_statusFilter) {
      case 'online':
        result =
            result.where((b) => b.hasConnection && !b.isEmergency).toList();
        break;
      case 'alarm':
        result = result.where((b) => b.isEmergency).toList();
        break;
      case 'offline':
        result = result.where((b) => !b.hasConnection).toList();
        break;
    }

    if (_searchQuery.isEmpty) return result;

    return result.where((boiler) {
      return boiler.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          boiler.district.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          boiler.boilerType.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final appColors = context.appColors;

    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Header with search
            _buildHeader(context),

            // Content
            Expanded(
              child: BlocBuilder<BoilersBloc, BoilersState>(
                builder: (context, state) {
                  if (state is BoilersLoadInProgress) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(strokeWidth: 3),
                          const SizedBox(height: 16),
                          Text(
                            'Загрузка данных...',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is BoilersLoadFailure) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colors.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ошибка загрузки',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.error,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onErrorContainer),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context
                                  .read<BoilersBloc>()
                                  .add(FetchBoilers()),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Попробовать снова'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.error,
                                foregroundColor: colors.onError,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is BoilersLoadSuccess) {
                    // Считаем статистику
                    final totalCount = state.boilers.length;
                    final alarmCount =
                        state.boilers.where((b) => b.isEmergency).length;
                    final onlineCount = state.boilers
                        .where((b) => b.hasConnection && !b.isEmergency)
                        .length;
                    final offlineCount =
                        state.boilers.where((b) => !b.hasConnection).length;

                    final filteredBoilers = _filterBoilers(state.boilers);

                    if (state.boilers.isEmpty) {
                      return const Center(child: Text('Список объектов пуст'));
                    }

                    return RefreshIndicator(
                      color: colors.primary,
                      onRefresh: () async {
                        await Future.delayed(Durations.short2);
                        context.read<BoilersBloc>().add(FetchBoilers());
                        await context
                            .read<BoilersBloc>()
                            .stream
                            .firstWhere((s) => s is! BoilersLoadInProgress);
                      },
                      child: Column(
                        children: [
                          // --- ВСТАВЛЕНО: Блок статистики ---
                          _buildStatsBar(totalCount, alarmCount, onlineCount,
                              offlineCount),

                          // Search results info
                          if (_searchQuery.isNotEmpty || _statusFilter != 'all')
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8), // уменьшил отступ
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: appColors.infoContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: appColors.info.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: appColors.info,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Найдено: ${filteredBoilers.length} из ${state.boilers.length}',
                                    style: TextStyle(
                                      color: appColors.onInfoContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (filteredBoilers.isEmpty &&
                              (_searchQuery.isNotEmpty ||
                                  _statusFilter != 'all'))
                            const Expanded(
                              child: Center(child: Text("Ничего не найдено")),
                            )
                          else
                            Expanded(
                              child: _buildBoilerList(context, filteredBoilers),
                            ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Загрузка...',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- НОВЫЙ МЕТОД: Строка статистики (активная панель с фильтрами) ---
  Widget _buildStatsBar(int total, int alarm, int online, int offline) {
    final colors = context.colors;
    final appColors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.isDark ? colors.surfaceContainer : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            context.isDark ? Border.all(color: colors.outlineVariant) : null,
        boxShadow: [
          BoxShadow(
            color: appColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Всего', total, colors.primary, 'all'),
          _buildStatItem('Норма', online, appColors.success, 'online'),
          _buildStatItem('Внимание', alarm, colors.error, 'alarm'),
          _buildStatItem('Нет связи', offline, appColors.archived, 'offline'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, String filter) {
    final bool isSelected = _statusFilter == filter;
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Повторное нажатие на активный фильтр сбрасывает его
            _statusFilter = isSelected ? 'all' : filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : colors.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? color : colors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ДАЛЕЕ ВЕСЬ ТВОЙ СТАРЫЙ КОД БЕЗ ИЗМЕНЕНИЙ ---

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    // Ночью шапка тёмная — синяя плашка во весь экран слепит.
    final headerGradient = isDark
        ? [colors.surfaceContainer, colors.surfaceContainerHigh]
        : [colors.primary, Color.lerp(colors.primary, Colors.black, 0.22)!];
    final onHeader = isDark ? colors.onSurface : colors.onPrimary;

    // Экран без AppBar, поэтому иконки статус-бара задаём сами —
    // шапка тёмная в обеих темах, значит иконки светлые.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: headerGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: context.appColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              // Экран без AppBar, поэтому заголовок центрируем сами: Stack
              // держит надпись по центру шапки независимо от того, сколько
              // кнопок стоит по краям — как centerTitle у AppBar.
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Диспетчерская',
                    style: TextStyle(
                      color: onHeader,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: onHeader,
                        size: 28,
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: onHeader.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isSearchActive ? Icons.close : Icons.search,
                            color: onHeader,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearchActive = !_isSearchActive;
                              if (!_isSearchActive) {
                                _searchController.clear();
                                _searchQuery = '';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: onHeader.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.logout, color: onHeader),
                          onPressed: () => _showLogoutDialog(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isSearchActive ? 60 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isSearchActive ? 1.0 : 0.0,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isDark ? colors.surfaceContainerHigh : colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.cardShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: _isSearchActive,
                    decoration: InputDecoration(
                      hintText: 'Поиск по названию, району или типу...',
                      hintStyle: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: colors.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: colors.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoilerList(BuildContext context, List<BoilerListItem> boilers) {
    final boilersByDistrict = <int, List<BoilerListItem>>{};
    for (var boiler in boilers) {
      boilersByDistrict.putIfAbsent(boiler.district.id, () => []).add(boiler);
    }

    final sortedDistrictIds = boilersByDistrict.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 92),
      itemCount: sortedDistrictIds.length,
      itemBuilder: (context, index) {
        final districtId = sortedDistrictIds[index];
        final districtBoilers = boilersByDistrict[districtId]!;
        final districtName = districtBoilers.first.district.name;
        return _buildDistrictSection(context, districtName, districtBoilers);
      },
    );
  }

  Widget _buildDistrictSection(
      BuildContext context, String title, List<BoilerListItem> boilers) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primaryContainer,
                colors.primaryContainer.withValues(alpha: 0.45),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_city,
                color: colors.onPrimaryContainer,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${boilers.length}',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            const cardWidth = 76.0;
            const spacing = 6.0;
            const horizontalPadding = 4.0;

            final availableWidth = screenWidth - horizontalPadding;
            int crossAxisCount =
                ((availableWidth + spacing) / (cardWidth + spacing)).floor();
            crossAxisCount = crossAxisCount.clamp(2, 20);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: boilers.length,
              itemBuilder: (context, index) =>
                  _buildBoilerCard(context, boilers[index]),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBoilerCard(BuildContext context, BoilerListItem boiler) {
    final colors = context.colors;
    final appColors = context.appColors;
    final isDark = context.isDark;
    final cardBase = isDark ? colors.surfaceContainer : colors.surface;

    final isHighlighted = _searchQuery.isNotEmpty &&
        (boiler.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            boiler.district.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            boiler.boilerType.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()));

    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => BoilerDetailBloc(
                  apiService: context.read<ApiService>(),
                  storageService: context.read<StorageService>(),
                ),
                child: BoilerDetailScreen(
                  boilerId: boiler.id,
                  boilerName: boiler.name,
                  districtName: boiler.district.name,
                ),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHighlighted
                  ? [
                      appColors.warningContainer,
                      appColors.warning.withValues(alpha: 0.45),
                    ]
                  : [
                      cardBase,
                      colors.primary.withValues(alpha: isDark ? 0.28 : 0.34),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? appColors.warning
                  : colors.primary.withValues(alpha: 0.28),
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: appColors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color:
                            boiler.isEmergency ? colors.error : colors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: boiler.isEmergency
                            ? colors.onError
                            : colors.onPrimary,
                        size: 10,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        boiler.boilerType.name,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: boiler.hasConnection
                            ? appColors.successContainer
                            : colors.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: BlinkingDot(
                          color: boiler.hasConnection
                              ? appColors.success
                              : colors.error,
                          size: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Text(
                    boiler.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.onSurface,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
