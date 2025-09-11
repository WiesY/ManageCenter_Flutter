// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:manage_center/bloc/boiler_detail_bloc.dart';
// import 'package:manage_center/models/boiler_parameter_model.dart';
// import 'package:manage_center/models/boiler_parameter_value_model.dart';

// // Константы для приложения
// class AppConstants {
//   // Цвета
//   static const primary = Color(0xFF2E7D32);
//   static const primaryLight = Color(0xFF4CAF50);
//   static const primaryBackground = Color(0xFFE8F5E9);
//   static const error = Colors.red;
//   static const warning = Colors.orange;
//   static const background = Color(0xFFF5F5F5);
  
//   // Тексты
//   static const statusNormal = 'В работе';
//   static const statusWarning = 'Внимание';
//   static const statusError = 'Авария';
//   static const noParameters = 'Параметры не найдены';
//   static const selectParameters = 'Выберите параметры для мониторинга';
//   static const noData = 'Нет данных за выбранное время';
//   static const tryOtherTime = 'Попробуйте выбрать другое время или параметры';
//   static const loading = 'Загрузка данных...';
//   static const initialization = 'Инициализация...';
//   static const errorLoading = 'Ошибка загрузки данных';
// }

// /// Перечисление для статусов котельной
// enum BoilerStatus { normal, warning, error }

// /// Класс для хранения состояния котельной
// class BoilerState {
//   final BoilerStatus status;
//   final String statusText;
//   final String lastUpdate;
//   final Color statusColor;
//   final Color textColor;

//   BoilerState({
//     required this.status,
//     required this.statusText,
//     required this.lastUpdate,
//     required this.statusColor,
//     required this.textColor,
//   });

//   /// Фабричный метод для создания нормального состояния
//   factory BoilerState.normal() {
//     final moscowTime = DateTime.now().add(const Duration(hours: 3));
//     return BoilerState(
//       status: BoilerStatus.normal,
//       statusText: AppConstants.statusNormal,
//       lastUpdate: DateFormat('HH:mm').format(moscowTime),
//       statusColor: AppConstants.primaryLight,
//       textColor: AppConstants.primary,
//     );
//   }

//   /// Фабричный метод для создания состояния предупреждения
//   factory BoilerState.warning() {
//     final moscowTime = DateTime.now().add(const Duration(hours: 3));
//     return BoilerState(
//       status: BoilerStatus.warning,
//       statusText: AppConstants.statusWarning,
//       lastUpdate: DateFormat('HH:mm').format(moscowTime),
//       statusColor: AppConstants.warning,
//       textColor: Colors.orange[800]!,
//     );
//   }

//   /// Фабричный метод для создания состояния ошибки
//   factory BoilerState.error() {
//     final moscowTime = DateTime.now().add(const Duration(hours: 3));
//     return BoilerState(
//       status: BoilerStatus.error,
//       statusText: AppConstants.statusError,
//       lastUpdate: DateFormat('HH:mm').format(moscowTime),
//       statusColor: AppConstants.error,
//       textColor: Colors.red[800]!,
//     );
//   }
// }

// /// Утилиты для работы с датой и временем
// class DateTimeUtils {
//   static final DateFormat timeFormatter = DateFormat('HH:mm:ss');
//   static final DateFormat dateTimeFormatter = DateFormat('dd.MM.yyyy HH:mm');
//   static final DateFormat dateRangeFormatter = DateFormat('dd.MM HH:mm');
  
//   /// Конвертирует время UTC в московское время (+3 часа)
//   static DateTime toMoscowTime(DateTime utcTime) {
//     return utcTime.add(const Duration(hours: 3));
//   }

//   /// Конвертирует московское время в UTC для отправки на сервер
//   static DateTime toUtcTime(DateTime moscowTime) {
//     return moscowTime.subtract(const Duration(hours: 3));
//   }

//   /// Форматирует время для отображения (в московском времени)
//   static String formatTime(DateTime utcTime) {
//     final moscowTime = toMoscowTime(utcTime);
//     return timeFormatter.format(moscowTime);
//   }

//   /// Форматирует дату и время для отображения (в московском времени)
//   static String formatDateTime(DateTime utcTime) {
//     final moscowTime = toMoscowTime(utcTime);
//     return dateTimeFormatter.format(moscowTime);
//   }

//   /// Форматирует дату и время для диапазона (в московском времени)
//   static String formatDateRange(DateTime utcTime) {
//     final moscowTime = toMoscowTime(utcTime);
//     return dateRangeFormatter.format(moscowTime);
//   }
// }

// /// Главный экран детальной информации о котельной
// class BoilerDetailScreen extends StatefulWidget {
//   final int boilerId;
//   final String boilerName;
//   final String? districtName;

//   const BoilerDetailScreen({
//     Key? key,
//     required this.boilerId,
//     required this.boilerName,
//     this.districtName,
//   }) : super(key: key);

//   @override
//   _BoilerDetailScreenState createState() => _BoilerDetailScreenState();
// }

// class _BoilerDetailScreenState extends State<BoilerDetailScreen> {
//   BoilerState _boilerState = BoilerState.normal();

//   // Для управления выбранными параметрами
//   List<BoilerParameter> _allParameters = [];
//   Set<int> _selectedParameterIds = {};

//   // Для выбора даты и времени
//   DateTime _selectedDateTime = DateTime.now();
//   DateTime _startDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
//   DateTime _endDate = DateTime.now();
//   String _selectedInterval = '60';

//   // Для поиска параметров
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     _selectedDateTime = DateTime(
//       DateTime.now().year,
//       DateTime.now().month,
//       DateTime.now().day,
//       DateTime.now().hour,
//       DateTime.now().minute,
//     );
//     _loadParameters();
//   }

//   void _loadParameters() {
//     context.read<BoilerDetailBloc>().add(LoadBoilerParameters(widget.boilerId));
//   }

//   void _loadDataForSelectedParameters() {
//     if (_selectedParameterIds.isNotEmpty) {
//       context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
//         boilerId: widget.boilerId,
//         startDate: _startDate,
//         endDate: _endDate,
//         selectedParameterIds: _selectedParameterIds.toList(),
//         interval: int.parse(_selectedInterval),
//       ));
//     }
//   }

//   // Методы для выбора даты и времени
//   Future<void> _selectDateTime(BuildContext context) async {
//     final moscowDateTime = DateTimeUtils.toMoscowTime(_selectedDateTime);
    
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: moscowDateTime,
//       firstDate: DateTime(2020),
//       lastDate: DateTimeUtils.toMoscowTime(DateTime.now()),
//       locale: const Locale('ru', 'RU'),
//       builder: (context, child) => _timePickerTheme(child!),
//     );

//     if (pickedDate != null) {
//       final TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(moscowDateTime),
//         builder: (context, child) => _timePickerTheme(child!),
//       );

//       if (pickedTime != null) {
//         final selectedMoscowTime = DateTime(
//           pickedDate.year,
//           pickedDate.month,
//           pickedDate.day,
//           pickedTime.hour,
//           pickedTime.minute,
//         );
        
//         setState(() {
//           _selectedDateTime = DateTimeUtils.toUtcTime(selectedMoscowTime);
//         });

//         if (_selectedParameterIds.isNotEmpty) {
//           _loadDataForSelectedParameters();
//         }
//       }
//     }
//   }

//   Future<void> _selectDateRange(BuildContext context) async {
//     final moscowStartDate = DateTimeUtils.toMoscowTime(_startDate);
//     final moscowEndDate = DateTimeUtils.toMoscowTime(_endDate);
    
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTimeUtils.toMoscowTime(DateTime.now()),
//       initialDateRange: DateTimeRange(start: moscowStartDate, end: moscowEndDate),
//       locale: const Locale('ru', 'RU'),
//       builder: (context, child) => Theme(
//         data: Theme.of(context).copyWith(
//           colorScheme: const ColorScheme.light(
//             primary: AppConstants.primary,
//             onPrimary: Colors.white,
//           ),
//         ),
//         child: child!,
//       ),
//     );

//     if (picked != null) {
//       final TimeOfDay? startTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(moscowStartDate),
//         builder: (context, child) => _timePickerTheme(child!),
//       );

//       if (startTime != null) {
//         final TimeOfDay? endTime = await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.fromDateTime(moscowEndDate),
//           builder: (context, child) => _timePickerTheme(child!),
//         );

//         if (endTime != null) {
//           final selectedMoscowStartDate = DateTime(
//             picked.start.year,
//             picked.start.month,
//             picked.start.day,
//             startTime.hour,
//             startTime.minute,
//           );
          
//           final selectedMoscowEndDate = DateTime(
//             picked.end.year,
//             picked.end.month,
//             picked.end.day,
//             endTime.hour,
//             endTime.minute,
//           );
          
//           setState(() {
//             _startDate = DateTimeUtils.toUtcTime(selectedMoscowStartDate);
//             _endDate = DateTimeUtils.toUtcTime(selectedMoscowEndDate);
//           });

//           if (_selectedParameterIds.isNotEmpty) {
//             _loadDataForSelectedParameters();
//           }
//         }
//       }
//     }
//   }

//   // Методы для работы с интервалами
//   void _showIntervalDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _IntervalSelectionDialog(
//         selectedInterval: _selectedInterval,
//         onIntervalSelected: (value) {
//           setState(() => _selectedInterval = value);
//           if (_selectedParameterIds.isNotEmpty) {
//             _loadDataForSelectedParameters();
//           }
//         },
//       ),
//     );
//   }

//   String _getIntervalText() {
//     switch (_selectedInterval) {
//       case '1': return '1 мин';
//       case '5': return '5 мин';
//       case '15': return '15 мин';
//       case '60': return '1 час';
//       default: return '1 час';
//     }
//   }

//   // Вспомогательные методы для UI
//   Widget _timePickerTheme(Widget child) {
//     return Theme(
//       data: Theme.of(context).copyWith(
//         colorScheme: const ColorScheme.light(
//           primary: AppConstants.primary,
//           onPrimary: Colors.white,
//         ),
//       ),
//       child: MediaQuery(
//         data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
//         child: child,
//       ),
//     );
//   }

//   // Методы для отображения диалогов
//   void _showParameterSelectionDialog() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (dialogContext) => ParameterSelectionDialog(
//         allParameters: _allParameters,
//         selectedParameterIds: _selectedParameterIds,
//         searchQuery: _searchQuery,
//         onSearchChanged: (value) => _searchQuery = value,
//         onSelectionChanged: (newSelection) {
//           setState(() {
//             _selectedParameterIds = newSelection;
//             _searchQuery = '';
//           });
//           _loadDataForSelectedParameters();
//         },
//       ),
//     );
//   }

//   void _showStatusDetails() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => StatusDetailsDialog(
//         boilerState: _boilerState,
//         boilerName: widget.boilerName,
//         districtName: widget.districtName,
//         selectedParameterIds: _selectedParameterIds,
//         startDate: _startDate,
//         endDate: _endDate,
//         selectedInterval: _selectedInterval,
//         onSelectDateRange: () {
//           Navigator.pop(context);
//           _selectDateRange(context);
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppConstants.background,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Column(
//           children: [
//             Text(
//               widget.boilerName,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             if (widget.districtName != null)
//               Text(
//                 widget.districtName!,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.white70,
//                 ),
//               ),
//           ],
//         ),
//         centerTitle: true,
//         backgroundColor: AppConstants.primary,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.tune, color: Colors.white),
//             onPressed: _allParameters.isNotEmpty
//                 ? _showParameterSelectionDialog
//                 : null,
//             tooltip: 'Выбрать параметры',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildTimeSelectionPanel(),
//           _buildStatusPanel(),
//           _buildMainContent(),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeSelectionPanel() {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppConstants.primary,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: InkWell(
//               onTap: () => _selectDateRange(context),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.date_range, color: Colors.white, size: 18),
//                     const SizedBox(width: 8),
//                     Flexible(
//                       child: Text(
//                         '${DateTimeUtils.formatDateRange(_startDate)} - ${DateTimeUtils.formatDateRange(_endDate)}',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           Container(width: 1, height: 32, color: Colors.white24),
//           InkWell(
//             onTap: _showIntervalDialog,
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               child: Row(
//                 children: [
//                   const Icon(Icons.schedule, color: Colors.white, size: 18),
//                   const SizedBox(width: 8),
//                   Text(
//                     _getIntervalText(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusPanel() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: InkWell(
//               onTap: _showStatusDetails,
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[200]!),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 12,
//                       height: 12,
//                       decoration: BoxDecoration(
//                         color: _boilerState.statusColor,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: _boilerState.statusColor.withOpacity(0.4),
//                             blurRadius: 8,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       _boilerState.statusText,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: _boilerState.textColor,
//                       ),
//                     ),
//                     const Spacer(),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: Colors.blue[100]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.settings, size: 14, color: Colors.blue[700]),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${_selectedParameterIds.length}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.blue[50],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.blue[100]!),
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.refresh),
//               color: Colors.blue[700],
//               tooltip: 'Обновить данные',
//               onPressed: _loadDataForSelectedParameters,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainContent() {
//     return Expanded(
//       child: BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
//         builder: (context, state) {
//           if (state is BoilerDetailLoadInProgress) {
//             return const LoadingStateWidget();
//           }

//           if (state is BoilerDetailLoadFailure) {
//             return ErrorStateWidget(
//               error: state.error,
//               onRetry: _loadDataForSelectedParameters,
//             );
//           }

//           if (state is BoilerDetailParametersLoaded) {
//             _allParameters = state.parameters;
//             return ParameterSelectionStateWidget(
//               parametersCount: _allParameters.length,
//               selectedDateTime: _selectedDateTime,
//               onSelectParameters: _showParameterSelectionDialog,
//               onChangeTime: () => _selectDateTime(context),
//             );
//           }

//           if (state is BoilerDetailValuesLoaded) {
//             if (state.values.isEmpty) {
//               return EmptyDataStateWidget(
//                 onRefresh: _loadDataForSelectedParameters,
//                 onChangeTime: () => _selectDateTime(context),
//               );
//             }
//             return ParameterValuesListWidget(
//               values: state.values,
//               selectedParameterIds: _selectedParameterIds,
//               onRefresh: _loadDataForSelectedParameters,
//             );
//           }

//           return const Center(child: Text(AppConstants.initialization));
//         },
//       ),
//     );
//   }
// }

// // Вспомогательные виджеты

// /// Виджет для отображения загрузки
// class LoadingStateWidget extends StatelessWidget {
//   const LoadingStateWidget({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primary)),
//           SizedBox(height: 16),
//           Text(AppConstants.loading),
//         ],
//       ),
//     );
//   }
// }

// /// Виджет для отображения ошибки
// class ErrorStateWidget extends StatelessWidget {
//   final String error;
//   final VoidCallback onRetry;

//   const ErrorStateWidget({
//     Key? key,
//     required this.error,
//     required this.onRetry,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, size: 64, color: AppConstants.error),
//           const SizedBox(height: 16),
//           const Text(
//             AppConstants.errorLoading,
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Text(
//               error,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton.icon(
//             onPressed: onRetry,
//             icon: const Icon(Icons.refresh),
//             label: const Text('Попробовать снова'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppConstants.primary,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Виджет для отображения состояния выбора параметров
// class ParameterSelectionStateWidget extends StatelessWidget {
//   final int parametersCount;
//   final DateTime selectedDateTime;
//   final VoidCallback onSelectParameters;
//   final VoidCallback onChangeTime;

//   const ParameterSelectionStateWidget({
//     Key? key,
//     required this.parametersCount,
//     required this.selectedDateTime,
//     required this.onSelectParameters,
//     required this.onChangeTime,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: Colors.green[50],
//               shape: BoxShape.circle,
//             ),
//             child: Icon(Icons.tune, size: 40, color: Colors.green[700]),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             AppConstants.selectParameters,
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.green[50],
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               'Доступно $parametersCount параметров',
//               style: TextStyle(
//                   color: Colors.green[700], fontWeight: FontWeight.w500),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 32),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue[50],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.blue[200]!),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.access_time, color: Colors.blue[700], size: 18),
//                 const SizedBox(width: 8),
//                 Text(
//                   DateTimeUtils.formatDateTime(selectedDateTime),
//                   style: TextStyle(
//                     color: Colors.blue[700],
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: onSelectParameters,
//                     icon: const Icon(Icons.settings),
//                     label: const Text('Выбрать параметры'),
//                     style: ElevatedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       backgroundColor: AppConstants.primary,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: onChangeTime,
//                     icon: const Icon(Icons.access_time),
//                     label: const Text('Изменить время'),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.blue[700],
//                       side: BorderSide(color: Colors.blue[300]!),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Виджет для отображения пустых данных
// class EmptyDataStateWidget extends StatelessWidget {
//   final VoidCallback onRefresh;
//   final VoidCallback onChangeTime;

//   const EmptyDataStateWidget({
//     Key? key,
//     required this.onRefresh,
//     required this.onChangeTime,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: Colors.orange[50],
//               shape: BoxShape.circle,
//             ),
//             child: Icon(Icons.info_outline, size: 40, color: Colors.orange[700]),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             AppConstants.noData,
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Text(
//               AppConstants.tryOtherTime,
//               style: TextStyle(color: Colors.grey[600]),
//               textAlign: TextAlign.center,
//             ),
//           ),
//           const SizedBox(height: 32),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: onRefresh,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('Обновить'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppConstants.primary,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: onChangeTime,
//                     icon: const Icon(Icons.access_time),
//                     label: const Text('Другое время'),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.blue[700],
//                       side: BorderSide(color: Colors.blue[300]!),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Виджет для отображения списка значений параметров
// class ParameterValuesListWidget extends StatelessWidget {
//   final List<BoilerParameterValue> values;
//   final Set<int> selectedParameterIds;
//   final VoidCallback onRefresh;

//   const ParameterValuesListWidget({
//     Key? key,
//     required this.values,
//     required this.selectedParameterIds,
//     required this.onRefresh,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Группируем значения по времени
//     final Map<DateTime, List<BoilerParameterValue>> groupedValues = {};

//     for (var value in values) {
//       final timeKey = DateTime(
//         value.receiptDate.year,
//         value.receiptDate.month,
//         value.receiptDate.day,
//         value.receiptDate.hour,
//         value.receiptDate.minute,
//         value.receiptDate.second,
//       );

//       groupedValues.putIfAbsent(timeKey, () => []).add(value);
//     }

//     final sortedTimes = groupedValues.keys.toList()
//       ..sort((a, b) => b.compareTo(a));

//     return RefreshIndicator(
//       onRefresh: () async {
//         onRefresh();
//         await context
//             .read<BoilerDetailBloc>()
//             .stream
//             .firstWhere((state) => state is! BoilerDetailLoadInProgress);
//       },
//       child: Column(
//         children: [
//           // Заголовок со статистикой
//           _buildStatisticsHeader(sortedTimes.length, values.length),

//           // Список данных
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               itemCount: sortedTimes.length,
//               itemBuilder: (context, index) {
//                 final time = sortedTimes[index];
//                 final timeValues = groupedValues[time]!;

//                 return _buildTimeCard(context, time, timeValues, index);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatisticsHeader(int recordsCount, int valuesCount) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatItem('Записей', '$recordsCount', Icons.timeline),
//           _buildStatItem('Параметров', '${selectedParameterIds.length}', Icons.settings),
//           _buildStatItem('Значений', '$valuesCount', Icons.data_usage),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String value, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.green[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.green[100]!),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: AppConstants.primary, size: 24),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: AppConstants.primary,
//             ),
//           ),
//           Text(
//             label,
//             style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeCard(BuildContext context, DateTime time, List<BoilerParameterValue> timeValues, int index) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Theme(
//         data: Theme.of(context).copyWith(
//           dividerColor: Colors.transparent,
//         ),
//         child: ExpansionTile(
//           tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           childrenPadding: EdgeInsets.zero,
//           title: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: AppConstants.primary,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   DateTimeUtils.formatTime(time),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 'Запись ${index + 1}',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w500,
//                   color: AppConstants.primary,
//                   fontSize: 16,
//                 ),
//               ),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[100],
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   '${timeValues.length} парам.',
//                   style: TextStyle(
//                     color: Colors.blue[700],
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           children: [
//             Container(
//               constraints: const BoxConstraints(maxHeight: 400),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: const BorderRadius.only(
//                   bottomLeft: Radius.circular(16),
//                   bottomRight: Radius.circular(16),
//                 ),
//               ),
//               child: Scrollbar(
//                 child: ListView.separated(
//                   shrinkWrap: true,
//                   itemCount: timeValues.length,
//                   separatorBuilder: (context, index) => Divider(
//                     color: Colors.grey[200],
//                     height: 1,
//                   ),
//                   itemBuilder: (context, paramIndex) {
//                     final value = timeValues[paramIndex];
//                     return Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       child: _buildParameterRow(
//                         value.parameter.paramDescription.isEmpty
//                             ? 'Параметр ID: ${value.parameter.id}'
//                             : value.parameter.paramDescription,
//                         value.displayValue,
//                         value.parameter.valueType,
//                         value.parameter.id,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildParameterRow(String label, String value, String valueType, int parameterId) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           flex: 3,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 14,
//                 ),
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 4),
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[100],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       valueType,
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.blue[700],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       'ID: $parameterId',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           flex: 1,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.green[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.green[200]!),
//             ),
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: AppConstants.primary,
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// /// Диалог для выбора интервала
// class _IntervalSelectionDialog extends StatelessWidget {
//   final String selectedInterval;
//   final Function(String) onIntervalSelected;

//   const _IntervalSelectionDialog({
//     Key? key,
//     required this.selectedInterval,
//     required this.onIntervalSelected,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Выберите интервал',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildIntervalOption(context, '1', 'Каждую минуту'),
//           _buildIntervalOption(context, '5', 'Каждые 5 минут'),
//           _buildIntervalOption(context, '15', 'Каждые 15 минут'),
//           _buildIntervalOption(context, '60', 'Каждый час'),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   Widget _buildIntervalOption(BuildContext context, String value, String label) {
//     final isSelected = selectedInterval == value;
//     return InkWell(
//       onTap: () {
//         onIntervalSelected(value);
//         Navigator.pop(context);
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//         margin: const EdgeInsets.only(bottom: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? AppConstants.primaryBackground : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? AppConstants.primary : Colors.grey[300]!,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
//               color: isSelected ? AppConstants.primary : Colors.grey[600],
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
//                 color: isSelected ? AppConstants.primary : Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Виджет для отображения строки детали статуса
// class _StatusDetailRow extends StatelessWidget {
//   final String label;
//   final String value;

//   const _StatusDetailRow({
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 16,
//             ),
//           ),
//           Flexible(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 fontSize: 16,
//               ),
//               textAlign: TextAlign.end,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Диалог для отображения деталей статуса
// class StatusDetailsDialog extends StatelessWidget {
//   final BoilerState boilerState;
//   final String boilerName;
//   final String? districtName;
//   final Set<int> selectedParameterIds;
//   final DateTime startDate;
//   final DateTime endDate;
//   final String selectedInterval;
//   final VoidCallback onSelectDateRange;

//   const StatusDetailsDialog({
//     Key? key,
//     required this.boilerState,
//     required this.boilerName,
//     this.districtName,
//     required this.selectedParameterIds,
//     required this.startDate,
//     required this.endDate,
//     required this.selectedInterval,
//     required this.onSelectDateRange,
//   }) : super(key: key);

//   String _getIntervalText() {
//     switch (selectedInterval) {
//       case '1': return '1 мин';
//       case '5': return '5 мин';
//       case '15': return '15 мин';
//       case '60': return '1 час';
//       default: return '1 час';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 12,
//                 height: 12,
//                 decoration: BoxDecoration(
//                   color: boilerState.statusColor,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 'Информация о мониторинге',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: boilerState.textColor,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           _StatusDetailRow(label: 'Статус', value: boilerState.statusText),
//           _StatusDetailRow(label: 'Объект', value: boilerName),
//           if (districtName != null)
//             _StatusDetailRow(label: 'Район', value: districtName!),
//           _StatusDetailRow(
//               label: 'Выбрано параметров', value: '${selectedParameterIds.length}'),
//           _StatusDetailRow(
//               label: 'Диапазон времени',
//               value: '${DateTimeUtils.formatDateRange(startDate)} - ${DateTimeUtils.formatDateRange(endDate)}'),
//           _StatusDetailRow(label: 'Интервал', value: _getIntervalText()),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: InkWell(
//                   onTap: onSelectDateRange,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.date_range, color: Colors.white, size: 18),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Изменить диапазон',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: AppConstants.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                   ),
//                   child: const Text('Закрыть'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Диалог для выбора параметров
// class ParameterSelectionDialog extends StatefulWidget {
//   final List<BoilerParameter> allParameters;
//   final Set<int> selectedParameterIds;
//   final String searchQuery;
//   final Function(String) onSearchChanged;
//   final Function(Set<int>) onSelectionChanged;

//   const ParameterSelectionDialog({
//     Key? key,
//     required this.allParameters,
//     required this.selectedParameterIds,
//     required this.searchQuery,
//     required this.onSearchChanged,
//     required this.onSelectionChanged,
//   }) : super(key: key);

//   @override
//   _ParameterSelectionDialogState createState() => _ParameterSelectionDialogState();
// }

// class _ParameterSelectionDialogState extends State<ParameterSelectionDialog> {
//   late Set<int> _localSelectedParameterIds;
//   late String _localSearchQuery;

//   @override
//   void initState() {
//     super.initState();
//     _localSelectedParameterIds = Set.from(widget.selectedParameterIds);
//     _localSearchQuery = widget.searchQuery;
//   }

//   List<BoilerParameter> _getFilteredParameters() {
//     if (_localSearchQuery.isEmpty) {
//       return widget.allParameters;
//     }

//     return widget.allParameters.where((parameter) {
//       return parameter.paramDescription
//           .toLowerCase()
//           .contains(_localSearchQuery.toLowerCase());
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredParameters = _getFilteredParameters();

//     return Container(
//       height: MediaQuery.of(context).size.height * 0.85,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         children: [
//           // Заголовок с ручкой для перетаскивания
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             child: Column(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Выберите параметры',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(),
          
//           // Поле поиска
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Поиск параметров...',
//                 prefixIcon: const Icon(Icons.search, size: 20),
//                 suffixIcon: _localSearchQuery.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear, size: 20),
//                         onPressed: () {
//                           setState(() {
//                             _localSearchQuery = '';
//                           });
//                           widget.onSearchChanged('');
//                         },
//                       )
//                     : null,
//                 filled: true,
//                 fillColor: Colors.grey[100],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 12, vertical: 12),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _localSearchQuery = value;
//                 });
//                 widget.onSearchChanged(value);
//               },
//             ),
//           ),
          
//           // Кнопки быстрого выбора
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         _localSelectedParameterIds =
//                             filteredParameters.map((p) => p.id).toSet();
//                       });
//                     },
//                     icon: const Icon(Icons.select_all, size: 16),
//                     label: const Text('Выбрать все'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppConstants.primary,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         _localSelectedParameterIds.clear();
//                       });
//                     },
//                     icon: const Icon(Icons.clear_all, size: 16),
//                     label: const Text('Очистить'),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.red[700],
//                       side: BorderSide(color: Colors.red[300]!),
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Счетчик параметров
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Доступно: ${filteredParameters.length}',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: _localSelectedParameterIds.isEmpty
//                         ? Colors.red[50]
//                         : Colors.green[50],
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: _localSelectedParameterIds.isEmpty
//                           ? Colors.red[300]!
//                           : Colors.green[300]!,
//                     ),
//                   ),
//                   child: Text(
//                     'Выбрано: ${_localSelectedParameterIds.length}',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: _localSelectedParameterIds.isEmpty
//                           ? Colors.red[700]
//                           : Colors.green[700],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Список параметров
//           Expanded(
//             child: filteredParameters.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.search_off,
//                             size: 48, color: Colors.grey[400]),
//                         const SizedBox(height: 8),
//                         Text(
//                           AppConstants.noParameters,
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: filteredParameters.length,
//                     itemBuilder: (context, index) {
//                       final parameter = filteredParameters[index];
//                       final isSelected = _localSelectedParameterIds
//                           .contains(parameter.id);

//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         decoration: BoxDecoration(
//                           color: isSelected ? Colors.green[50] : Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: isSelected
//                                 ? Colors.green[300]!
//                                 : Colors.grey[300]!,
//                             width: isSelected ? 2 : 1,
//                           ),
//                         ),
//                         child: CheckboxListTile(
//                           title: Text(
//                             parameter.paramDescription,
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: isSelected
//                                   ? FontWeight.w500
//                                   : FontWeight.normal,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           subtitle: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 6, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[100],
//                                   borderRadius:
//                                       BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   parameter.valueType,
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     color: Colors.blue[700],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 'ID: ${parameter.id}',
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           value: isSelected,
//                           dense: true,
//                           activeColor: Colors.green[700],
//                           checkColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           onChanged: (bool? value) {
//                             setState(() {
//                               if (value == true) {
//                                 _localSelectedParameterIds
//                                     .add(parameter.id);
//                               } else {
//                                 _localSelectedParameterIds
//                                     .remove(parameter.id);
//                               }
//                             });
//                           },
//                         ),
//                       );
//                     },
//                   ),
//           ),
          
//           // Кнопки действий
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Отмена'),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: _localSelectedParameterIds.isEmpty
//                         ? null
//                         : () {
//                             widget.onSelectionChanged(_localSelectedParameterIds);
//                             Navigator.pop(context);
//                           },
//                     icon: const Icon(Icons.check),
//                     label: Text('Применить (${_localSelectedParameterIds.length})'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppConstants.primary,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }