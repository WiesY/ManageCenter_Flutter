// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:manage_center/bloc/boiler_detail_bloc.dart';
// import 'package:manage_center/models/boiler_parameter_model.dart';
// import 'package:manage_center/models/boiler_parameter_value_model.dart';
// import 'package:manage_center/widgets/custom_bottom_navigation.dart';

// enum BoilerStatus { normal, warning, error }

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

//   factory BoilerState.normal() {
//     return BoilerState(
//       status: BoilerStatus.normal,
//       statusText: 'В работе',
//       lastUpdate: DateFormat('HH:mm').format(DateTime.now()),
//       statusColor: const Color(0xFF4CAF50),
//       textColor: const Color(0xFF2E7D32),
//     );
//   }

//   factory BoilerState.warning() {
//     return BoilerState(
//       status: BoilerStatus.warning,
//       statusText: 'Внимание',
//       lastUpdate: DateFormat('HH:mm').format(DateTime.now()),
//       statusColor: Colors.orange,
//       textColor: Colors.orange[800]!,
//     );
//   }

//   factory BoilerState.error() {
//     return BoilerState(
//       status: BoilerStatus.error,
//       statusText: 'Авария',
//       lastUpdate: DateFormat('HH:mm').format(DateTime.now()),
//       statusColor: Colors.red,
//       textColor: Colors.red[800]!,
//     );
//   }
// }

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

// class _BoilerDetailScreenState extends State<BoilerDetailScreen>
//     with TickerProviderStateMixin {
//   final DateFormat timeFormatter = DateFormat('HH:mm:ss');
//   final DateFormat dateTimeFormatter = DateFormat('dd.MM.yyyy HH:mm');
//   final DateFormat dateFormatter = DateFormat('dd.MM.yyyy');
//   BoilerState _boilerState = BoilerState.normal();

//   // Для управления выбранными параметрами
//   List<BoilerParameter> _allParameters = [];
//   Set<int> _selectedParameterIds = {};

//   // Для выбора диапазона дат - по умолчанию от 00:00 текущего дня до текущего времени (московское время)
//   DateTime _startDateTime =
//       DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
//   DateTime _endDateTime = DateTime.now();

//   // Для поиска параметров
//   String _searchQuery = '';

//   // Анимации
//   late AnimationController _statusAnimationController;
//   late AnimationController _refreshAnimationController;
//   late Animation<double> _statusPulseAnimation;
//   late Animation<double> _refreshRotationAnimation;

//   @override
//   void initState() {
//     super.initState();

//     // Инициализация анимаций
//     _statusAnimationController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );
//     _refreshAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _statusPulseAnimation = Tween<double>(
//       begin: 0.8,
//       end: 1.2,
//     ).animate(CurvedAnimation(
//       parent: _statusAnimationController,
//       curve: Curves.easeInOut,
//     ));

//     _refreshRotationAnimation = Tween<double>(
//       begin: 0,
//       end: 1,
//     ).animate(CurvedAnimation(
//       parent: _refreshAnimationController,
//       curve: Curves.easeInOut,
//     ));

//     _statusAnimationController.repeat(reverse: true);

//     // Устанавливаем дефолтный диапазон: от 00:00 текущего дня до текущего времени
//     final now = DateTime.now();
//     _startDateTime = DateTime(now.year, now.month, now.day, 0, 0, 0);
//     _endDateTime = now;

//     // Загружаем только параметры при инициализации
//     context.read<BoilerDetailBloc>().add(LoadBoilerParameters(widget.boilerId));
//   }

//   @override
//   void dispose() {
//     _statusAnimationController.dispose();
//     _refreshAnimationController.dispose();
//     super.dispose();
//   }

//   // Конвертация московского времени в UTC
//   DateTime _moscowToUtc(DateTime moscowTime) {
//     // Московское время = UTC+3
//     return moscowTime.subtract(const Duration(hours: 3));
//   }

//   // Конвертация UTC в московское время для отображения
//   DateTime _utcToMoscow(DateTime utcTime) {
//     // Московское время = UTC+3
//     return utcTime.add(const Duration(hours: 3));
//   }

//   void _loadDataForSelectedParameters() {
//     if (_selectedParameterIds.isNotEmpty) {
//       _refreshAnimationController.forward().then((_) {
//         _refreshAnimationController.reset();
//       });

//       // Конвертируем московское время в UTC перед отправкой в API
//       final startUtc = _moscowToUtc(_startDateTime);
//       final endUtc = _moscowToUtc(_endDateTime);

//       context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
//             boilerId: widget.boilerId,
//             startDate: startUtc,
//             endDate: endUtc,
//             selectedParameterIds: _selectedParameterIds.toList(),
//           ));
//     }
//   }

//   // Выбор диапазона дат
//   Future<void> _selectDateTimeRange(BuildContext context) async {
//     // Сначала выбираем диапазон дат
//     final DateTimeRange? pickedDateRange = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       initialDateRange: DateTimeRange(
//         start: DateTime(
//             _startDateTime.year, _startDateTime.month, _startDateTime.day),
//         end: DateTime(_endDateTime.year, _endDateTime.month, _endDateTime.day),
//       ),
//       locale: const Locale('ru', 'RU'),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: const Color(0xFF2E7D32),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black,
//               secondary: const Color(0xFF4CAF50),
//             ),
//             dialogBackgroundColor: Colors.white,
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (pickedDateRange != null) {
//       // Если выбран диапазон дат, выбираем время для начала
//       final TimeOfDay? startTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(_startDateTime),
//         helpText: 'Выберите время начала',
//         builder: (context, child) {
//           return Theme(
//             data: Theme.of(context).copyWith(
//               colorScheme: ColorScheme.light(
//                 primary: const Color(0xFF2E7D32),
//                 onPrimary: Colors.white,
//                 surface: Colors.white,
//                 onSurface: Colors.black,
//               ),
//               timePickerTheme: TimePickerThemeData(
//                 backgroundColor: Colors.white,
//                 hourMinuteTextStyle: const TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 dialHandColor: const Color(0xFF2E7D32),
//                 dialBackgroundColor: Colors.grey[100],
//               ),
//             ),
//             child: Localizations.override(
//               context: context,
//               locale: const Locale('ru', 'RU'),
//               child: MediaQuery(
//                 data: MediaQuery.of(context)
//                     .copyWith(alwaysUse24HourFormat: true),
//                 child: child!,
//               ),
//             ),
//           );
//         },
//       );

//       if (startTime != null) {
//         // Выбираем время для окончания
//         final TimeOfDay? endTime = await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.fromDateTime(_endDateTime),
//           helpText: 'Выберите время окончания',
//           builder: (context, child) {
//             return Theme(
//               data: Theme.of(context).copyWith(
//                 colorScheme: ColorScheme.light(
//                   primary: const Color(0xFF2E7D32),
//                   onPrimary: Colors.white,
//                   surface: Colors.white,
//                   onSurface: Colors.black,
//                 ),
//                 timePickerTheme: TimePickerThemeData(
//                   backgroundColor: Colors.white,
//                   hourMinuteTextStyle: const TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   dialHandColor: const Color(0xFF2E7D32),
//                   dialBackgroundColor: Colors.grey[100],
//                 ),
//               ),
//               child: Localizations.override(
//                 context: context,
//                 locale: const Locale('ru', 'RU'),
//                 child: MediaQuery(
//                   data: MediaQuery.of(context)
//                       .copyWith(alwaysUse24HourFormat: true),
//                   child: child!,
//                 ),
//               ),
//             );
//           },
//         );

//         if (endTime != null) {
//           final newStartDateTime = DateTime(
//             pickedDateRange.start.year,
//             pickedDateRange.start.month,
//             pickedDateRange.start.day,
//             startTime.hour,
//             startTime.minute,
//           );

//           final newEndDateTime = DateTime(
//             pickedDateRange.end.year,
//             pickedDateRange.end.month,
//             pickedDateRange.end.day,
//             endTime.hour,
//             endTime.minute,
//           );

//           // Проверяем, что время окончания не раньше времени начала
//           if (newEndDateTime.isAfter(newStartDateTime)) {
//             setState(() {
//               _startDateTime = newStartDateTime;
//               _endDateTime = newEndDateTime;
//             });

//             if (_selectedParameterIds.isNotEmpty) {
//               _loadDataForSelectedParameters();
//             }
//           } else {
//             // Показываем ошибку
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content:
//                     Text('Время окончания должно быть позже времени начала'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         }
//       }
//     }
//   }

//   // Быстрые пресеты для выбора времени
//   void _setQuickTimeRange(String preset) {
//     final now = DateTime.now();
//     DateTime start, end;

//     switch (preset) {
//       case 'current_day':
//         start = DateTime(now.year, now.month, now.day, 0, 0, 0);
//         end = now;
//         break;
//       case 'last_hour':
//         end = now;
//         start = now.subtract(const Duration(hours: 1));
//         break;
//       case 'last_3_hours':
//         end = now;
//         start = now.subtract(const Duration(hours: 3));
//         break;
//       case 'last_6_hours':
//         end = now;
//         start = now.subtract(const Duration(hours: 6));
//         break;
//       case 'last_12_hours':
//         end = now;
//         start = now.subtract(const Duration(hours: 12));
//         break;
//       case 'yesterday':
//         final yesterday = now.subtract(const Duration(days: 1));
//         start =
//             DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
//         end = DateTime(
//             yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
//         break;
//       default:
//         return;
//     }

//     setState(() {
//       _startDateTime = start;
//       _endDateTime = end;
//     });

//     if (_selectedParameterIds.isNotEmpty) {
//       _loadDataForSelectedParameters();
//     }
//   }

//   // Фильтрация параметров по поиску
//   List<BoilerParameter> _getFilteredParameters() {
//     if (_searchQuery.isEmpty) {
//       return _allParameters;
//     }

//     return _allParameters.where((parameter) {
//       return parameter.paramDescription
//           .toLowerCase()
//           .contains(_searchQuery.toLowerCase());
//     }).toList();
//   }

//   void _showParameterSelectionDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             final filteredParameters = _getFilteredParameters();

//             return Dialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Container(
//                 width: MediaQuery.of(context).size.width * 0.9,
//                 height: MediaQuery.of(context).size.height * 0.8,
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     // Заголовок с улучшенным дизайном
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             const Color(0xFF2E7D32),
//                             const Color(0xFF4CAF50),
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.tune, color: Colors.white, size: 24),
//                           const SizedBox(width: 12),
//                           const Expanded(
//                             child: Text(
//                               'Выберите параметры для мониторинга',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Информация о выбранном диапазоне времени
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.blue[50]!,
//                             Colors.blue[100]!,
//                           ],
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.blue[200]!),
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue[600],
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: const Icon(
//                                   Icons.date_range,
//                                   color: Colors.white,
//                                   size: 20,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text(
//                                       'Выбранный диапазон времени',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.blue,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       'С: ${dateTimeFormatter.format(_startDateTime)}',
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.blue[800],
//                                       ),
//                                     ),
//                                     Text(
//                                       'По: ${dateTimeFormatter.format(_endDateTime)}',
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.blue[800],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: Colors.amber[100],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(Icons.info_outline,
//                                     size: 16, color: Colors.amber[800]),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   'Время указано в московском часовом поясе',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.amber[800],
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Кнопки быстрого выбора времени
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[50],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.grey[200]!),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Быстрый выбор:',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Wrap(
//                             spacing: 8,
//                             runSpacing: 8,
//                             children: [
//                               _buildQuickTimeButton('Сегодня', 'current_day'),
//                               _buildQuickTimeButton('1 час', 'last_hour'),
//                               _buildQuickTimeButton('3 часа', 'last_3_hours'),
//                               _buildQuickTimeButton('6 часов', 'last_6_hours'),
//                               _buildQuickTimeButton(
//                                   '12 часов', 'last_12_hours'),
//                               _buildQuickTimeButton('Вчера', 'yesterday'),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Кнопки быстрого выбора параметров
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               setDialogState(() {
//                                 _selectedParameterIds =
//                                     filteredParameters.map((p) => p.id).toSet();
//                               });
//                             },
//                             icon: const Icon(Icons.select_all, size: 18),
//                             label: const Text('Выбрать все'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green[600],
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               setDialogState(() {
//                                 _selectedParameterIds.clear();
//                               });
//                             },
//                             icon: const Icon(Icons.clear_all, size: 18),
//                             label: const Text('Очистить'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.red[600],
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Счетчик параметров
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 12, horizontal: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[50],
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.grey[200]!),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(Icons.list_alt,
//                                   color: Colors.grey[600], size: 20),
//                               const SizedBox(width: 8),
//                               Text(
//                                 'Доступно: ${filteredParameters.length}',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: _selectedParameterIds.isEmpty
//                                   ? Colors.red[100]
//                                   : Colors.green[100],
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   _selectedParameterIds.isEmpty
//                                       ? Icons.error_outline
//                                       : Icons.check_circle,
//                                   size: 16,
//                                   color: _selectedParameterIds.isEmpty
//                                       ? Colors.red[700]
//                                       : Colors.green[700],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   'Выбрано: ${_selectedParameterIds.length}',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                     color: _selectedParameterIds.isEmpty
//                                         ? Colors.red[700]
//                                         : Colors.green[700],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Поле поиска
//                     Container(
//                       decoration: BoxDecoration(
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: TextField(
//                         decoration: InputDecoration(
//                           hintText: 'Поиск параметров...',
//                           prefixIcon: const Icon(Icons.search,
//                               color: Color(0xFF2E7D32)),
//                           suffixIcon: _searchQuery.isNotEmpty
//                               ? IconButton(
//                                   icon: const Icon(Icons.clear),
//                                   onPressed: () {
//                                     setDialogState(() {
//                                       _searchQuery = '';
//                                     });
//                                   },
//                                 )
//                               : null,
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: Colors.grey[300]!),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: const BorderSide(
//                                 color: Color(0xFF2E7D32), width: 2),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 12),
//                         ),
//                         onChanged: (value) {
//                           setDialogState(() {
//                             _searchQuery = value;
//                           });
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Список параметров
//                     Expanded(
//                       child: filteredParameters.isEmpty
//                           ? _buildEmptyParametersState()
//                           : Container(
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey[200]!),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: ListView.builder(
//                                 itemCount: filteredParameters.length,
//                                 itemBuilder: (context, index) {
//                                   final parameter = filteredParameters[index];
//                                   final isSelected = _selectedParameterIds
//                                       .contains(parameter.id);

//                                   return Container(
//                                     margin: const EdgeInsets.symmetric(
//                                         horizontal: 8, vertical: 4),
//                                     decoration: BoxDecoration(
//                                       color: isSelected
//                                           ? Colors.green[50]
//                                           : Colors.white,
//                                       borderRadius: BorderRadius.circular(8),
//                                       border: Border.all(
//                                         color: isSelected
//                                             ? Colors.green[300]!
//                                             : Colors.grey[200]!,
//                                         width: isSelected ? 2 : 1,
//                                       ),
//                                     ),
//                                     child: CheckboxListTile(
//                                       title: Text(
//                                         parameter.paramDescription,
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: isSelected
//                                               ? FontWeight.w600
//                                               : FontWeight.normal,
//                                           color: isSelected
//                                               ? Colors.green[800]
//                                               : Colors.black87,
//                                         ),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       subtitle: Padding(
//                                         padding: const EdgeInsets.only(top: 8),
//                                         child: Row(
//                                           children: [
//                                             Container(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                       horizontal: 8,
//                                                       vertical: 4),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.blue[100],
//                                                 borderRadius:
//                                                     BorderRadius.circular(6),
//                                               ),
//                                               child: Text(
//                                                 parameter.valueType,
//                                                 style: TextStyle(
//                                                   fontSize: 11,
//                                                   color: Colors.blue[700],
//                                                   fontWeight: FontWeight.w600,
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(width: 8),
//                                             Container(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                       horizontal: 8,
//                                                       vertical: 4),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.orange[100],
//                                                 borderRadius:
//                                                     BorderRadius.circular(6),
//                                               ),
//                                               child: Text(
//                                                 'ID: ${parameter.id}',
//                                                 style: TextStyle(
//                                                   fontSize: 11,
//                                                   color: Colors.orange[700],
//                                                   fontWeight: FontWeight.w600,
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       value: isSelected,
//                                       dense: true,
//                                       activeColor: Colors.green[600],
//                                       checkColor: Colors.white,
//                                       onChanged: (bool? value) {
//                                         setDialogState(() {
//                                           if (value == true) {
//                                             _selectedParameterIds
//                                                 .add(parameter.id);
//                                           } else {
//                                             _selectedParameterIds
//                                                 .remove(parameter.id);
//                                           }
//                                         });
//                                       },
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                     ),
//                     const SizedBox(height: 20),

//                     // Кнопки действий
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: () => Navigator.pop(dialogContext),
//                             icon: const Icon(Icons.close),
//                             label: const Text('Отмена'),
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: Colors.grey[700],
//                               side: BorderSide(color: Colors.grey[400]!),
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           flex: 2,
//                           child: ElevatedButton.icon(
//                             onPressed: _selectedParameterIds.isEmpty
//                                 ? null
//                                 : () {
//                                     Navigator.pop(dialogContext);
//                                     setState(() {
//                                       _searchQuery = '';
//                                     });
//                                     _loadDataForSelectedParameters();
//                                   },
//                             icon: const Icon(Icons.check_circle),
//                             label: Text(
//                                 'Применить (${_selectedParameterIds.length})'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF2E7D32),
//                               foregroundColor: Colors.white,
//                               disabledBackgroundColor: Colors.grey[300],
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildQuickTimeButton(String label, String preset) {
//     return ElevatedButton(
//       onPressed: () => _setQuickTimeRange(preset),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.blue[100],
//         foregroundColor: Colors.blue[700],
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//         elevation: 0,
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//       ),
//     );
//   }

//   Widget _buildEmptyParametersState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.search_off,
//               size: 48,
//               color: Colors.grey[400],
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Параметры не найдены',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Попробуйте изменить поисковый запрос',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showStatusDetails(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//           ),
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Индикатор перетаскивания
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Заголовок с иконкой
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF2E7D32).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.info_outline,
//                       color: Color(0xFF2E7D32),
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   const Expanded(
//                     child: Text(
//                       'Информация о мониторинге',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF2E7D32),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               // Информационные карточки
//               _buildInfoCard('Статус', _boilerState.statusText, Icons.circle,
//                   _boilerState.statusColor),
//               _buildInfoCard(
//                   'Котельная', widget.boilerName, Icons.factory, Colors.blue),
//               if (widget.districtName != null)
//                 _buildInfoCard('Район', widget.districtName!, Icons.location_on,
//                     Colors.orange),
//               _buildInfoCard('Выбрано параметров',
//                   '${_selectedParameterIds.length}', Icons.tune, Colors.purple),
//               _buildInfoCard(
//                   'Начало периода',
//                   dateTimeFormatter.format(_startDateTime),
//                   Icons.access_time,
//                   Colors.green),
//               _buildInfoCard(
//                   'Конец периода',
//                   dateTimeFormatter.format(_endDateTime),
//                   Icons.access_time_filled,
//                   Colors.teal),
//               _buildInfoCard(
//                   'Длительность',
//                   _formatDuration(_endDateTime.difference(_startDateTime)),
//                   Icons.timer,
//                   Colors.indigo),

//               const SizedBox(height: 24),

//               // Кнопки действий
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _selectDateTimeRange(context);
//                       },
//                       icon: const Icon(Icons.date_range),
//                       label: const Text('Изменить период'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue[600],
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.close),
//                       label: const Text('Закрыть'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF2E7D32),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   String _formatDuration(Duration duration) {
//     if (duration.inDays > 0) {
//       return '${duration.inDays} дн. ${duration.inHours % 24} ч.';
//     } else if (duration.inHours > 0) {
//       return '${duration.inHours} ч. ${duration.inMinutes % 60} мин.';
//     } else {
//       return '${duration.inMinutes} мин.';
//     }
//   }

//   Widget _buildInfoCard(
//       String label, String value, IconData icon, Color color) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, color: color, size: 20),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           _buildTimeRangeSelector(),
//           _buildStatusPanel(),
//           Expanded(
//             child: BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
//               builder: (context, state) {
//                 if (state is BoilerDetailLoadInProgress) {
//                   return _buildLoadingState();
//                 }

//                 if (state is BoilerDetailLoadFailure) {
//                   return _buildErrorState(state.error);
//                 }

//                 if (state is BoilerDetailParametersLoaded) {
//                   _allParameters = state.parameters;
//                   return _buildParameterSelectionState();
//                 }

//                 if (state is BoilerDetailValuesLoaded) {
//                   if (state.values.isEmpty) {
//                     return _buildNoDataState();
//                   }
//                   return _buildParameterValuesList(state.values);
//                 }

//                 return _buildInitialState();
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.white),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: Column(
//         children: [
//           Text(
//             widget.boilerName,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           if (widget.districtName != null)
//             Text(
//               widget.districtName!,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Colors.white70,
//               ),
//             ),
//         ],
//       ),
//       centerTitle: true,
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//       ),
//       elevation: 0,
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.tune, color: Colors.white),
//           onPressed:
//               _allParameters.isNotEmpty ? _showParameterSelectionDialog : null,
//           tooltip: 'Выбрать параметры',
//         ),
//       ],
//     );
//   }

//   Widget _buildTimeRangeSelector() {
//     return InkWell(
//       onTap: () => _selectDateTimeRange(context),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               offset: const Offset(0, 4),
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(
//                     Icons.date_range,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Выбранный период',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Icon(
//                     Icons.edit,
//                     color: Colors.white70,
//                     size: 16,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const Text(
//                         'С',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         dateTimeFormatter.format(_startDateTime),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   margin: const EdgeInsets.symmetric(horizontal: 16),
//                   child: const Icon(
//                     Icons.arrow_forward,
//                     color: Colors.white70,
//                     size: 20,
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       const Text(
//                         'По',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         dateTimeFormatter.format(_endDateTime),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusPanel() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: InkWell(
//               onTap: () => _showStatusDetails(context),
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: _boilerState.statusColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                       color: _boilerState.statusColor.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     AnimatedBuilder(
//                       animation: _statusPulseAnimation,
//                       builder: (context, child) {
//                         return Transform.scale(
//                           scale: _statusPulseAnimation.value,
//                           child: Container(
//                             width: 16,
//                             height: 16,
//                             decoration: BoxDecoration(
//                               color: _boilerState.statusColor,
//                               shape: BoxShape.circle,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color:
//                                       _boilerState.statusColor.withOpacity(0.6),
//                                   blurRadius: 12,
//                                   spreadRadius: 2,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _boilerState.statusText,
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: _boilerState.textColor,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Параметров: ${_selectedParameterIds.length}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Icon(
//                       Icons.info_outline,
//                       color: _boilerState.statusColor,
//                       size: 20,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           AnimatedBuilder(
//             animation: _refreshRotationAnimation,
//             builder: (context, child) {
//               return Transform.rotate(
//                 angle: _refreshRotationAnimation.value * 2 * 3.14159,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.blue[400]!, Colors.blue[600]!],
//                     ),
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.blue.withOpacity(0.3),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.refresh, color: Colors.white),
//                     tooltip: 'Обновить данные',
//                     onPressed: () {
//                       _loadDataForSelectedParameters();
//                     },
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 const CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
//                   strokeWidth: 3,
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Загрузка данных...',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(String error) {
//     return Center(
//       child: Container(
//         margin: const EdgeInsets.all(20),
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red[50],
//                 shape: BoxShape.circle,
//               ),
//               child:
//                   const Icon(Icons.error_outline, size: 48, color: Colors.red),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Ошибка загрузки данных',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.red,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               error,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: () => _loadDataForSelectedParameters(),
//               icon: const Icon(Icons.refresh),
//               label: const Text('Попробовать снова'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF2E7D32),
//                 foregroundColor: Colors.white,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildParameterSelectionState() {
//     return Center(
//       child: Container(
//         margin: const EdgeInsets.all(20),
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF2E7D32).withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.tune,
//                 size: 48,
//                 color: Color(0xFF2E7D32),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Выберите параметры для мониторинга',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2E7D32),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Доступно ${_allParameters.length} параметров',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.blue[50],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'Период: ${dateFormatter.format(_startDateTime)} - ${dateFormatter.format(_endDateTime)}',
//                     style: TextStyle(
//                       color: Colors.blue[700],
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   Text(
//                     '${dateTimeFormatter.format(_startDateTime)} - ${dateTimeFormatter.format(_endDateTime)}',
//                     style: TextStyle(
//                       color: Colors.blue[600],
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _showParameterSelectionDialog,
//                   icon: const Icon(Icons.settings),
//                   label: const Text('Выбрать параметры'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF2E7D32),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNoDataState() {
//     return Center(
//       child: Container(
//         margin: const EdgeInsets.all(20),
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.orange[50],
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.info_outline,
//                 size: 48,
//                 color: Colors.orange,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Нет данных за выбранный период',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.orange,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Попробуйте выбрать другой период времени или параметры',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: _loadDataForSelectedParameters,
//                   icon: const Icon(Icons.refresh),
//                   label: const Text('Обновить'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF2E7D32),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 ElevatedButton.icon(
//                   onPressed: () => _selectDateTimeRange(context),
//                   icon: const Icon(Icons.date_range),
//                   label: const Text('Другой период'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInitialState() {
//     return Center(
//       child: Container(
//         margin: const EdgeInsets.all(20),
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Инициализация...',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildParameterValuesList(List<BoilerParameterValue> values) {
//     // Группируем значения по времени (с точностью до секунды)
//     final Map<DateTime, List<BoilerParameterValue>> groupedValues = {};

//     for (var value in values) {
//       // Конвертируем UTC время в московское для отображения
//       final moscowTime = _utcToMoscow(value.receiptDate);
//       final timeKey = DateTime(
//         moscowTime.year,
//         moscowTime.month,
//         moscowTime.day,
//         moscowTime.hour,
//         moscowTime.minute,
//         moscowTime.second,
//       );

//       groupedValues.putIfAbsent(timeKey, () => []).add(value);
//     }

//     final sortedTimes = groupedValues.keys.toList()
//       ..sort((a, b) => b.compareTo(a)); // Сортируем по убыванию (новые сверху)

//     return RefreshIndicator(
//       onRefresh: () async {
//         _loadDataForSelectedParameters();
//         await context.read<BoilerDetailBloc>().stream.first;
//       },
//       color: const Color(0xFF2E7D32),
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: sortedTimes.length,
//         itemBuilder: (context, index) {
//           final timeKey = sortedTimes[index];
//           final timeValues = groupedValues[timeKey]!;

//           return Container(
//             margin: const EdgeInsets.only(bottom: 16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 12,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Заголовок с временем
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         const Color(0xFF2E7D32).withOpacity(0.1),
//                         const Color(0xFF4CAF50).withOpacity(0.05),
//                       ],
//                     ),
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(16),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2E7D32),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Icon(
//                           Icons.access_time,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               timeFormatter.format(timeKey),
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF2E7D32),
//                               ),
//                             ),
//                             Text(
//                               dateFormatter.format(timeKey),
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[100],
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           '${timeValues.length} параметр${timeValues.length == 1 ? '' : timeValues.length < 5 ? 'а' : 'ов'}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue[700],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Список параметров
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: timeValues.asMap().entries.map((entry) {
//                       final valueIndex = entry.key;
//                       final value = entry.value;
//                       final parameter = _allParameters.firstWhere(
//                         (p) => p.id == value.parameterId,
//                         orElse: () => BoilerParameter(
//                           id: value.parameterId,
//                           paramDescription: 'Неизвестный параметр',
//                           valueType: 'unknown',
//                         ),
//                       );

//                       return Container(
//                         margin: EdgeInsets.only(
//                           bottom: valueIndex < timeValues.length - 1
//                               ? 8
//                               : 0, // Уменьшить отступ
//                         ),
//                         padding: const EdgeInsets.all(
//                             12), // Уменьшить внутренние отступы
//                         decoration: BoxDecoration(
//                           color: Colors.grey[50],
//                           borderRadius:
//                               BorderRadius.circular(8), // Уменьшить радиус
//                           border: Border.all(
//                             color: Colors.grey[200]!,
//                             width: 1,
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             // Убрать иконку или сделать меньше
//                             Container(
//                               width: 6,
//                               height: 6,
//                               decoration: BoxDecoration(
//                                 color:
//                                     _getParameterTypeColor(parameter.valueType),
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 12),

//                             // Информация о параметре
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     parameter.paramDescription,
//                                     style: const TextStyle(
//                                       fontSize: 14, // Уменьшить размер шрифта
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.black87,
//                                     ),
//                                     maxLines: 1, // Ограничить одной строкой
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   const SizedBox(height: 4), // Уменьшить отступ
//                                   Row(
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 6,
//                                           vertical: 2,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.blue[100],
//                                           borderRadius:
//                                               BorderRadius.circular(4),
//                                         ),
//                                         child: Text(
//                                           'ID: ${parameter.id}',
//                                           style: TextStyle(
//                                             fontSize: 10,
//                                             fontWeight: FontWeight.w600,
//                                             color: Colors.blue[700],
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 4),
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 6,
//                                           vertical: 2,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.orange[100],
//                                           borderRadius:
//                                               BorderRadius.circular(4),
//                                         ),
//                                         child: Text(
//                                           parameter.valueType,
//                                           style: TextStyle(
//                                             fontSize: 10,
//                                             fontWeight: FontWeight.w600,
//                                             color: Colors.orange[700],
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),

//                             // Значение параметра - компактнее
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 6,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF2E7D32).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(6),
//                                 border: Border.all(
//                                   color:
//                                       const Color(0xFF2E7D32).withOpacity(0.2),
//                                 ),
//                               ),
//                               child: Text(
//                                 '${_formatParameterValue(value.value, parameter.valueType)} ${_getParameterUnit(parameter.valueType)}',
//                                 style: const TextStyle(
//                                   fontSize: 14, // Уменьшить размер
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFF2E7D32),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // Вспомогательные методы для отображения параметров
//   Color _getParameterTypeColor(String valueType) {
//     switch (valueType.toLowerCase()) {
//       case 'temperature':
//       case 'temp':
//         return Colors.red;
//       case 'pressure':
//         return Colors.blue;
//       case 'flow':
//       case 'расход':
//         return Colors.cyan;
//       case 'level':
//       case 'уровень':
//         return Colors.green;
//       case 'status':
//       case 'состояние':
//         return Colors.orange;
//       case 'power':
//       case 'мощность':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getParameterTypeIcon(String valueType) {
//     switch (valueType.toLowerCase()) {
//       case 'temperature':
//       case 'temp':
//         return Icons.thermostat;
//       case 'pressure':
//         return Icons.speed;
//       case 'flow':
//       case 'расход':
//         return Icons.water_drop;
//       case 'level':
//       case 'уровень':
//         return Icons.height;
//       case 'status':
//       case 'состояние':
//         return Icons.info;
//       case 'power':
//       case 'мощность':
//         return Icons.flash_on;
//       default:
//         return Icons.sensors;
//     }
//   }

//   String _getParameterUnit(String valueType) {
//     switch (valueType.toLowerCase()) {
//       case 'temperature':
//       case 'temp':
//         return '°C';
//       case 'pressure':
//         return 'бар';
//       case 'flow':
//       case 'расход':
//         return 'м³/ч';
//       case 'level':
//       case 'уровень':
//         return 'м';
//       case 'power':
//       case 'мощность':
//         return 'кВт';
//       default:
//         return '';
//     }
//   }

//   String _formatParameterValue(dynamic value, String valueType) {
//     double numValue;

//     if (value is String) {
//       numValue = double.tryParse(value) ?? 0.0;
//     } else if (value is num) {
//       numValue = value.toDouble();
//     } else {
//       numValue = 0.0;
//     }

//     switch (valueType.toLowerCase()) {
//       case 'temperature':
//       case 'temp':
//       case 'pressure':
//       case 'flow':
//       case 'расход':
//       case 'level':
//       case 'уровень':
//       case 'power':
//       case 'мощность':
//         return numValue.toStringAsFixed(1);
//       case 'status':
//       case 'состояние':
//         return numValue.toInt().toString();
//       default:
//         return numValue.toString();
//     }
//   }
// }
