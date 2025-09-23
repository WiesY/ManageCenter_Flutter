// analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/analytics_bloc.dart';
import 'package:manage_center/models/BoilerTypeCompareValues.dart';
import 'package:manage_center/models/boiler_list_item_model.dart';
import 'package:manage_center/models/boiler_type_model.dart';
import 'package:manage_center/models/groups_model.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'dart:math' as math;

class AppColors {
  // static const primary = Color(0xFF2E7D32);
  // static const primaryLight = Color(0xFF4CAF50);
  static const primary = Colors.blue;
  static const primaryLight = Colors.lightBlue;
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFE53E3E);
  static const warning = Color(0xFFFF8C00);
  static const success = Colors.green;
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
}

enum SortDirection { asc, desc, none }

class ColumnSortData {
  final String name;
  SortDirection direction;
  
  ColumnSortData(this.name, {this.direction = SortDirection.none});
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем существующие сервисы из контекста
    final apiService = context.read<ApiService>();
    final storageService = context.read<StorageService>();
    
    return BlocProvider(
      create: (context) => AnalyticsBloc(
        apiService: apiService,
        storageService: storageService,
      )..add(AnalyticsInitEvent()),
      child: const _AnalyticsScreenContent(),
    );
  }
}

class _AnalyticsScreenContent extends StatefulWidget {
  const _AnalyticsScreenContent();

  @override
  State<_AnalyticsScreenContent> createState() => _AnalyticsScreenContentState();
}

class _AnalyticsScreenContentState extends State<_AnalyticsScreenContent> {
  // Состояние сортировки
  List<ColumnSortData> sortColumns = [];
  int? activeSortColumnIndex;
  SortDirection sortDirection = SortDirection.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsInitialState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AnalyticsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AnalyticsLoadedState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectedDateInfo(context, state),
                  const SizedBox(height: 6),
                  _buildObjectTypeSelector(context, state),
                  const SizedBox(height: 16),
                  _buildParameterGroupSelector(context, state),
                 // const SizedBox(height: 1),
                  _buildParametersTable(context, state),
                ],
              ),
            );
          } else if (state is AnalyticsErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка',
                    //style: Theme.of(context).textTheme.headline6?.copyWith(
                    style: TextStyle(color: AppColors.error,),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    //style: Theme.of(context).textTheme.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AnalyticsBloc>().add(AnalyticsInitEvent());
                    },
                    child: const Text('Повторить'),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Аналитика',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          tooltip: 'Выбрать дату',
          onPressed: () => _selectDateTime(context),
        ),
      ],
    );
  }

  Widget _buildSelectedDateInfo(BuildContext context, AnalyticsLoadedState state) {
    return InkWell(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Выбранная дата: ${DateFormat('dd.MM.yyyy HH:mm').format(state.selectedDate.toLocal())}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      onTap:() => _selectDateTime(context),
    );
  }

  Widget _buildObjectTypeSelector(BuildContext context, AnalyticsLoadedState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '1. Выбор типа объекта',
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.boilerTypes.length,
            itemBuilder: (context, index) {
              final boilerType = state.boilerTypes[index];
              final isSelected = state.selectedBoilerTypeId == boilerType.id;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business,
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        boilerType.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  elevation: isSelected ? 4 : 2,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<AnalyticsBloc>().add(
                        AnalyticsSelectBoilerTypeEvent(boilerType.id),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParameterGroupSelector(BuildContext context, AnalyticsLoadedState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '2. Выбор группы параметров',
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
          child: state.parameterGroups.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.textSecondary),
                        SizedBox(width: 12),
                        Text(
                          'Сначала выберите тип объекта',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.parameterGroups.length,
                  itemBuilder: (context, index) {
                    final group = state.parameterGroups[index];
                    final isSelected = state.selectedGroupId == group.id;
                    final color = _parseGroupColor(group.color ?? '#4CAF50');
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_rounded,
                              size: 18,
                              color: isSelected ? Colors.white : color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              group.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : color,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: color,
                        backgroundColor: AppColors.surface,
                        elevation: isSelected ? 4 : 2,
                        onSelected: (selected) {
                          if (selected) {
                            context.read<AnalyticsBloc>().add(
                              AnalyticsSelectParameterGroupEvent(group.id),
                            );
                          } else {
                            context.read<AnalyticsBloc>().add(
                              AnalyticsSelectParameterGroupEvent(null),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildParametersTable(BuildContext context, AnalyticsLoadedState state) {
    if (state.selectedBoilerTypeId == null || state.compareValues == null) {
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
              Icons.table_chart_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Таблица параметров',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите тип объекта и группу параметров для отображения данных',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Получаем выбранную группу параметров
    Group? selectedGroup;
    try {
      if (state.selectedGroupId != null && state.parameterGroups.isNotEmpty) {
        selectedGroup = state.parameterGroups.firstWhere(
          (group) => group.id == state.selectedGroupId,
        );
      }
    } catch (_) {
      // Если группа не найдена, оставляем selectedGroup = null
    }

    // Получаем данные для таблицы
    final compareValues = state.compareValues!;
    
    // Если нет данных или группа не найдена
    if (compareValues.isEmpty || (state.selectedGroupId != null && selectedGroup == null)) {
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
              Icons.info_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет данных',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Для выбранных параметров нет данных на указанную дату',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Собираем все параметры
    final allParameters = <ParameterCompareData>[];
    
    if (selectedGroup != null && state.selectedGroupId != null) {
      // Находим все параметры выбранной группы
      for (final boiler in compareValues) {
        for (final group in boiler.groups) {
          if (group.groupId == state.selectedGroupId) {
            for (final param in group.parameters) {
              if (!allParameters.any((p) => p.parameterId == param.parameterId)) {
                allParameters.add(param);
              }
            }
          }
        }
      }
    } else {
      // Собираем все параметры всех групп
      for (final boiler in compareValues) {
        for (final group in boiler.groups) {
          for (final param in group.parameters) {
            if (!allParameters.any((p) => p.parameterId == param.parameterId)) {
              allParameters.add(param);
            }
          }
        }
      }
    }

    // Создаем заголовки таблицы (параметры)
    final columns = <DataColumn>[
      DataColumn(
        label: InkWell(
          onTap: () {
            setState(() {
              // Сортировка по имени объекта
              if (activeSortColumnIndex == 0) {
                // Циклическое изменение направления сортировки: asc -> desc -> none
                if (sortDirection == SortDirection.asc) {
                  sortDirection = SortDirection.desc;
                } else if (sortDirection == SortDirection.desc) {
                  sortDirection = SortDirection.none;
                  activeSortColumnIndex = null; // Сброс активного столбца
                } else {
                  sortDirection = SortDirection.asc;
                }
              } else {
                activeSortColumnIndex = 0;
                sortDirection = SortDirection.asc;
              }
            });
          },
          child: Row(
            children: [
              const Text(
                'Объект',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(
                sortDirection == SortDirection.asc && activeSortColumnIndex == 0
                    ? Icons.arrow_upward
                    : sortDirection == SortDirection.desc && activeSortColumnIndex == 0
                        ? Icons.arrow_downward
                        : Icons.sort,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ];
    
// Добавляем колонки для каждого параметра
for (int i = 0; i < allParameters.length; i++) {
  final param = allParameters[i];
  final columnIndex = i + 1; // +1 потому что первая колонка - это объекты
  
  columns.add(
    DataColumn(
      label: Container(
        constraints: const BoxConstraints(maxWidth: 120), // Ограничиваем ширину
        child: InkWell(
          onTap: () {
            setState(() {
              // Сортировка по параметру
              if (activeSortColumnIndex == columnIndex) {
                // Циклическое изменение направления сортировки: asc -> desc -> none
                if (sortDirection == SortDirection.asc) {
                  sortDirection = SortDirection.desc;
                } else if (sortDirection == SortDirection.desc) {
                  sortDirection = SortDirection.none;
                  activeSortColumnIndex = null; // Сброс активного столбца
                } else {
                  sortDirection = SortDirection.asc;
                }
              } else {
                activeSortColumnIndex = columnIndex;
                sortDirection = SortDirection.asc;
              }
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      param.parameterName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.visible, // Разрешаем перенос текста
                      softWrap: true, // Включаем перенос строк
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    sortDirection == SortDirection.asc && activeSortColumnIndex == columnIndex
                        ? Icons.arrow_upward
                        : sortDirection == SortDirection.desc && activeSortColumnIndex == columnIndex
                            ? Icons.arrow_downward
                            : Icons.sort,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
    
    // Создаем список объектов для строк
    List<BoilerTypeCompareValues> sortedBoilers = List.from(compareValues);
    
    // Сортируем объекты
    if (activeSortColumnIndex == null || sortDirection == SortDirection.none) {
      // Сортировка по умолчанию - по ID котельных
      sortedBoilers.sort((a, b) => a.boilerId.compareTo(b.boilerId));
    } else if (activeSortColumnIndex == 0) {
      // Сортировка по имени объекта
      sortedBoilers.sort((a, b) {
        if (sortDirection == SortDirection.asc) {
          return a.boilerName.compareTo(b.boilerName);
        } else {
          return b.boilerName.compareTo(a.boilerName);
        }
      });
    } else if (activeSortColumnIndex! > 0) {
      // Сортировка по значению параметра
      final paramIndex = activeSortColumnIndex! - 1;
      if (paramIndex < allParameters.length) {
        final paramId = allParameters[paramIndex].parameterId;
        
        sortedBoilers.sort((a, b) {
          String valueA = 'Н/Д';
          String valueB = 'Н/Д';
          
          // Ищем значение параметра для объекта A
          for (final group in a.groups) {
            final paramValue = group.parameters.firstWhere(
              (p) => p.parameterId == paramId,
              orElse: () => ParameterCompareData(
                parameterId: 0,
                parameterName: '',
                value: '',
                receiptDate: DateTime.now(),
                parameterValueType: '',
              ),
            );
            
            if (paramValue.parameterId != 0) {
              valueA = paramValue.value;
              break;
            }
          }
          
          // Ищем значение параметра для объекта B
          for (final group in b.groups) {
            final paramValue = group.parameters.firstWhere(
              (p) => p.parameterId == paramId,
              orElse: () => ParameterCompareData(
                parameterId: 0,
                parameterName: '',
                value: '',
                receiptDate: DateTime.now(),
                parameterValueType: '',
              ),
            );
            
            if (paramValue.parameterId != 0) {
              valueB = paramValue.value;
              break;
            }
          }
          
          // Сравниваем значения
          if (sortDirection == SortDirection.asc) {
            return valueA.compareTo(valueB);
          } else {
            return valueB.compareTo(valueA);
          }
        });
      }
    }
    
    // Создаем строки таблицы (объекты)
    final rows = <DataRow>[];
    
    for (final boiler in sortedBoilers) {
      final cells = <DataCell>[
        DataCell(Text(boiler.boilerName)),
      ];
      
      // Добавляем значения для каждого параметра
      for (final param in allParameters) {
        String value = 'Н/Д';
        
        // Ищем значение параметра для текущего объекта
        for (final group in boiler.groups) {
          final paramValue = group.parameters.firstWhere(
            (p) => p.parameterId == param.parameterId,
            orElse: () => ParameterCompareData(
              parameterId: 0,
              parameterName: '',
              value: '',
              receiptDate: DateTime.now(),
              parameterValueType: '',
            ),
          );
          
          if (paramValue.parameterId != 0) {
            value = paramValue.displayValue;
            break;
          }
        }
        
        cells.add(
  DataCell(
    Container(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
      ),
    )
  )
);
      }
      
      rows.add(DataRow(cells: cells));
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.table_rows,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Параметры объектов',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Тип: ${state.boilerTypes.isNotEmpty ? state.boilerTypes.firstWhere((b) => b.id == state.selectedBoilerTypeId, orElse: () => BoilerType(id: 0, name: 'Неизвестно')).name : 'Неизвестно'} • ' +
                        'Группа: ${selectedGroup?.name ?? 'Все'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildFixedColumnTable(sortedBoilers, allParameters),
//           SingleChildScrollView(
//   scrollDirection: Axis.horizontal,
//   child: DataTable(
//     headingRowColor: MaterialStateProperty.all(AppColors.background),
//     headingRowHeight: 120, // Увеличиваем высоту заголовка
//     columnSpacing: 16, // Устанавливаем отступ между колонками
//     horizontalMargin: 16, // Устанавливаем горизонтальный отступ
//     columns: columns,
//     rows: rows,
//   ),
// ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFixedColumnTable(List<BoilerTypeCompareValues> sortedBoilers, List<ParameterCompareData> allParameters) {
  const double fixedColumnWidth = 150.0;
  const double parameterColumnWidth = 120.0;
  const double rowHeight = 56.0;
  const double headerHeight = 192.0;

  return Row(
    children: [
      // Закрепленная колонка с названиями объектов
      Container(
        width: fixedColumnWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(color: AppColors.background, width: 2),
          ),
        ),
        child: Column(
          children: [
            // Заголовок закрепленной колонки
            Container(
              height: headerHeight,
              color: AppColors.background,
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (activeSortColumnIndex == 0) {
                      if (sortDirection == SortDirection.asc) {
                        sortDirection = SortDirection.desc;
                      } else if (sortDirection == SortDirection.desc) {
                        sortDirection = SortDirection.none;
                        activeSortColumnIndex = null;
                      } else {
                        sortDirection = SortDirection.asc;
                      }
                    } else {
                      activeSortColumnIndex = 0;
                      sortDirection = SortDirection.asc;
                    }
                  });
                },
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Объект',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(
                      sortDirection == SortDirection.asc && activeSortColumnIndex == 0
                          ? Icons.arrow_upward
                          : sortDirection == SortDirection.desc && activeSortColumnIndex == 0
                              ? Icons.arrow_downward
                              : Icons.sort,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            // Строки с названиями объектов
            ...sortedBoilers.map((boiler) => Container(
              height: rowHeight,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.background, width: 1),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  boiler.boilerName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )),
          ],
        ),
      ),
      // Прокручиваемая часть с параметрами
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: allParameters.length * parameterColumnWidth,
            child: Column(
              children: [
                // Заголовки параметров
                Container(
                  height: headerHeight,
                  color: AppColors.background,
                  child: Row(
                    children: allParameters.asMap().entries.map((entry) {
                      final index = entry.key;
                      final param = entry.value;
                      final columnIndex = index + 1;
                      
                      return Container(
                        width: parameterColumnWidth,
                        padding: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (activeSortColumnIndex == columnIndex) {
                                if (sortDirection == SortDirection.asc) {
                                  sortDirection = SortDirection.desc;
                                } else if (sortDirection == SortDirection.desc) {
                                  sortDirection = SortDirection.none;
                                  activeSortColumnIndex = null;
                                } else {
                                  sortDirection = SortDirection.asc;
                                }
                              } else {
                                activeSortColumnIndex = columnIndex;
                                sortDirection = SortDirection.asc;
                              }
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      param.parameterName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    sortDirection == SortDirection.asc && activeSortColumnIndex == columnIndex
                                        ? Icons.arrow_upward
                                        : sortDirection == SortDirection.desc && activeSortColumnIndex == columnIndex
                                            ? Icons.arrow_downward
                                            : Icons.sort,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Строки с данными параметров
                ...sortedBoilers.map((boiler) => Container(
                  height: rowHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.background, width: 1),
                    ),
                  ),
                  child: Row(
                    children: allParameters.map((param) {
                      String value = 'Н/Д';
                      
                      for (final group in boiler.groups) {
                        final paramValue = group.parameters.firstWhere(
                          (p) => p.parameterId == param.parameterId,
                          orElse: () => ParameterCompareData(
                            parameterId: 0,
                            parameterName: '',
                            value: '',
                            receiptDate: DateTime.now(),
                            parameterValueType: '',
                          ),
                        );
                        
                        if (paramValue.parameterId != 0) {
                          value = paramValue.displayValue;
                          break;
                        }
                      }
                      
                      return Container(
                        width: parameterColumnWidth,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Future<void> _selectDateTime(BuildContext context) async {
    final state = context.read<AnalyticsBloc>().state;
    if (state is! AnalyticsLoadedState) return;
    
    final date = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(state.selectedDate),
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

      if (time != null) {
        final newDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        context.read<AnalyticsBloc>().add(AnalyticsSelectDateEvent(newDate));
      }
    }
  }
  
  // Вспомогательный метод для преобразования HEX-цвета в Color
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
}