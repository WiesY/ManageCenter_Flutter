// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:manage_center/bloc/boiler_detail_bloc.dart';
// import 'package:manage_center/models/boiler_parameter_model.dart';
// import 'package:manage_center/models/boiler_parameter_value_model.dart';
// import 'package:manage_center/widgets/custom_bottom_navigation.dart';

// enum BoilerStatus {
//   normal,
//   warning,
//   error
// }

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

// class _BoilerDetailScreenState extends State<BoilerDetailScreen> with TickerProviderStateMixin {
//   final DateFormat timeFormatter = DateFormat('HH:mm:ss');
//   final DateFormat dateTimeFormatter = DateFormat('dd.MM.yyyy HH:mm');
//   BoilerState _boilerState = BoilerState.normal();

//   // Для управления выбранными параметрами
//   List<BoilerParameter> _allParameters = [];
//   Set<int> _selectedParameterIds = {};

//   // Для выбора даты и времени - по умолчанию текущая минута
//   DateTime _selectedDateTime = DateTime.now();

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

//     // Устанавливаем текущую минуту (обнуляем секунды)
//     _selectedDateTime = DateTime(
//       DateTime.now().year,
//       DateTime.now().month,
//       DateTime.now().day,
//       DateTime.now().hour,
//       DateTime.now().minute,
//     );

//     // Загружаем только параметры при инициализации
//     context.read<BoilerDetailBloc>().add(LoadBoilerParameters(widget.boilerId));
//   }

//   @override
//   void dispose() {
//     _statusAnimationController.dispose();
//     _refreshAnimationController.dispose();
//     super.dispose();
//   }

//   // Получаем временной диапазон для выбранной минуты
//   Map<String, DateTime> _getSelectedMinuteRange() {
//     final startOfMinute = DateTime(
//       _selectedDateTime.year,
//       _selectedDateTime.month,
//       _selectedDateTime.day,
//       _selectedDateTime.hour,
//       _selectedDateTime.minute,
//       0, // секунды = 0
//     );

//     final endOfMinute = startOfMinute.add(const Duration(minutes: 1)).subtract(const Duration(seconds: 1));

//     return {
//       'start': startOfMinute,
//       'end': endOfMinute,
//     };
//   }

//   void _loadDataForSelectedParameters() {
//     if (_selectedParameterIds.isNotEmpty) {
//       final timeRange = _getSelectedMinuteRange();
      
//       _refreshAnimationController.forward().then((_) {
//         _refreshAnimationController.reset();
//       });

//       context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
//         boilerId: widget.boilerId,
//         startDate: timeRange['start']!,
//         endDate: timeRange['end']!,
//         selectedParameterIds: _selectedParameterIds.toList(),
//       ));
//     }
//   }

//   // Выбор даты и времени с улучшенным дизайном
//   Future<void> _selectDateTime(BuildContext context) async {
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: _selectedDateTime,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
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

//     if (pickedDate != null) {
//       final TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
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
//                 data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
//                 child: child!,
//               ),
//             ),
//           );
//         },
//       );

//       if (pickedTime != null) {
//         setState(() {
//           _selectedDateTime = DateTime(
//             pickedDate.year,
//             pickedDate.month,
//             pickedDate.day,
//             pickedTime.hour,
//             pickedTime.minute,
//           );
//         });

//         if (_selectedParameterIds.isNotEmpty) {
//           _loadDataForSelectedParameters();
//         }
//       }
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

//                     // Информация о выбранном времени с улучшенным дизайном
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
//                       child: Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.blue[600],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(
//                               Icons.access_time,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   'Данные за выбранную минуту',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   dateTimeFormatter.format(_selectedDateTime),
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.blue[800],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Кнопки быстрого выбора с улучшенным дизайном
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () {
//                               setDialogState(() {
//                                 _selectedParameterIds = filteredParameters.map((p) => p.id).toSet();
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

//                     // Счетчик параметров с улучшенным дизайном
//                     Container(
//                       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
//                               Icon(Icons.list_alt, color: Colors.grey[600], size: 20),
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
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: _selectedParameterIds.isEmpty ? Colors.red[100] : Colors.green[100],
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Icon(
//                                   _selectedParameterIds.isEmpty ? Icons.error_outline : Icons.check_circle,
//                                   size: 16,
//                                   color: _selectedParameterIds.isEmpty ? Colors.red[700] : Colors.green[700],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   'Выбрано: ${_selectedParameterIds.length}',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                     color: _selectedParameterIds.isEmpty ? Colors.red[700] : Colors.green[700],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Поле поиска с улучшенным дизайном
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
//                           prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
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
//                             borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                         ),
//                         onChanged: (value) {
//                           setDialogState(() {
//                             _searchQuery = value;
//                           });
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Список параметров с улучшенным дизайном
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
//                                   final isSelected = _selectedParameterIds.contains(parameter.id);

//                                   return Container(
//                                     margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                     decoration: BoxDecoration(
//                                       color: isSelected ? Colors.green[50] : Colors.white,
//                                       borderRadius: BorderRadius.circular(8),
//                                       border: Border.all(
//                                         color: isSelected ? Colors.green[300]! : Colors.grey[200]!,
//                                         width: isSelected ? 2 : 1,
//                                       ),
//                                     ),
//                                     child: CheckboxListTile(
//                                       title: Text(
//                                         parameter.paramDescription,
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                                           color: isSelected ? Colors.green[800] : Colors.black87,
//                                         ),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       subtitle: Padding(
//                                         padding: const EdgeInsets.only(top: 8),
//                                         child: Row(
//                                           children: [
//                                             Container(
//                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.blue[100],
//                                                 borderRadius: BorderRadius.circular(6),
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
//                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.orange[100],
//                                                 borderRadius: BorderRadius.circular(6),
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
//                                             _selectedParameterIds.add(parameter.id);
//                                           } else {
//                                             _selectedParameterIds.remove(parameter.id);
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

//                     // Кнопки действий с улучшенным дизайном
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
//                             onPressed: _selectedParameterIds.isEmpty ? null : () {
//                               Navigator.pop(dialogContext);
//                               setState(() {
//                                 _searchQuery = '';
//                               });
//                               _loadDataForSelectedParameters();
//                             },
//                             icon: const Icon(Icons.check_circle),
//                             label: Text('Применить (${_selectedParameterIds.length})'),
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
//               _buildInfoCard('Статус', _boilerState.statusText, Icons.circle, _boilerState.statusColor),
//               _buildInfoCard('Котельная', widget.boilerName, Icons.factory, Colors.blue),
//               if (widget.districtName != null)
//                 _buildInfoCard('Район', widget.districtName!, Icons.location_on, Colors.orange),
//               _buildInfoCard('Выбрано параметров', '${_selectedParameterIds.length}', Icons.tune, Colors.purple),
//               _buildInfoCard('Выбранное время', dateTimeFormatter.format(_selectedDateTime), Icons.access_time, Colors.green),
//               _buildInfoCard('Период данных', 'Одна минута', Icons.timer, Colors.teal),

//               const SizedBox(height: 24),

//               // Кнопки действий
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         _selectDateTime(context);
//                       },
//                       icon: const Icon(Icons.access_time),
//                       label: const Text('Изменить время'),
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

//   Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
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
//           _buildTimeSelector(),
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
//           onPressed: _allParameters.isNotEmpty ? _showParameterSelectionDialog : null,
//           tooltip: 'Выбрать параметры',
//         ),
//       ],
//     );
//   }

//   Widget _buildTimeSelector() {
//     return InkWell(
//       onTap: () => _selectDateTime(context),
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
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Icon(
//                 Icons.access_time,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               children: [
//                 const Text(
//                   'Выбранное время',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Text(
//                   dateTimeFormatter.format(_selectedDateTime),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(width: 12),
//             Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: const Icon(
//                 Icons.edit,
//                 color: Colors.white70,
//                 size: 16,
//               ),
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
//                   border: Border.all(color: _boilerState.statusColor.withOpacity(0.3)),
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
//                                   color: _boilerState.statusColor.withOpacity(0.6),
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
//               child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
//               child: Text(
//                 'Время: ${dateTimeFormatter.format(_selectedDateTime)}',
//                 style: TextStyle(
//                   color: Colors.blue[700],
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
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
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 //const SizedBox(width: 16),
//                 // ElevatedButton.icon(
//                 //   onPressed: () => _selectDateTime(context),
//                 //   icon: const Icon(Icons.access_time),
//                 //   label: const Text('Изменить время'),
//                 //   style: ElevatedButton.styleFrom(
//                 //     backgroundColor: Colors.blue[600],
//                 //     foregroundColor: Colors.white,
//                 //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 //     shape: RoundedRectangleBorder(
//                 //       borderRadius: BorderRadius.circular(10),
//                 //     ),
//                 //   ),
//                 // ),
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
//               'Нет данных за выбранное время',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.orange,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Попробуйте выбрать другое время или параметры',
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
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 ElevatedButton.icon(
//                   onPressed: () => _selectDateTime(context),
//                   icon: const Icon(Icons.access_time),
//                   label: const Text('Другое время'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
//       ..sort((a, b) => b.compareTo(a)); // Сортируем по убыванию (новые сверху)

//     return RefreshIndicator(
//       onRefresh: () async {
//         _loadDataForSelectedParameters();
//         await context.read<BoilerDetailBloc>().stream
//             .firstWhere((state) => state is! BoilerDetailLoadInProgress);
//       },
//       color: const Color(0xFF2E7D32),
//       child: Column(
//         children: [
//           // Заголовок со статистикой с улучшенным дизайном
//           Container(
//             margin: const EdgeInsets.all(16),
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.white, Colors.grey[50]!],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildStatItem('Записей', '${sortedTimes.length}', Icons.timeline, Colors.blue),
//                 _buildStatItem('Параметров', '${_selectedParameterIds.length}', Icons.settings, Colors.green),
//                 _buildStatItem('Значений', '${values.length}', Icons.data_usage, Colors.orange),
//               ],
//             ),
//           ),

//           // Список данных с улучшенным дизайном
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: sortedTimes.length,
//               itemBuilder: (context, index) {
//                 final time = sortedTimes[index];
//                 final timeValues = groupedValues[time]!;

//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Theme(
//                     data: Theme.of(context).copyWith(
//                       dividerColor: Colors.transparent,
//                     ),
//                     child: ExpansionTile(
//                       tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                       childrenPadding: EdgeInsets.zero,
//                       title: Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               gradient: const LinearGradient(
//                                 colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
//                               ),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               timeFormatter.format(time),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Text(
//                               'Запись ${index + 1}',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF2E7D32),
//                                 fontSize: 16,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: Colors.blue[100],
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '${timeValues.length} пар.',
//                               style: TextStyle(
//                                 color: Colors.blue[700],
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       children: [
//                         Container(
//                           constraints: const BoxConstraints(maxHeight: 400),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[50],
//                             borderRadius: const BorderRadius.only(
//                               bottomLeft: Radius.circular(16),
//                               bottomRight: Radius.circular(16),
//                             ),
//                           ),
//                           child: Scrollbar(
//                             child: ListView.builder(
//                               shrinkWrap: true,
//                               itemCount: timeValues.length,
//                               itemBuilder: (context, paramIndex) {
//                                 final value = timeValues[paramIndex];
//                                 return Container(
//                                   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(12),
//                                     border: Border.all(color: Colors.grey[200]!),
//                                   ),
//                                   child: _buildParameterRow(
//                                     value.parameterDescription.isEmpty 
//                                         ? 'Параметр ID: ${value.parameterId}'
//                                         : value.parameterDescription,
//                                     value.displayValue,
//                                     value.valueType,
//                                     value.parameterId,
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(icon, color: color, size: 24),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
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
//                   fontWeight: FontWeight.w600,
//                   fontSize: 14,
//                   color: Colors.black87,
//                 ),
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[100],
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       valueType,
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.blue[700],
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.orange[100],
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       'ID: $parameterId',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.orange[700],
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           flex: 1,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.green[50]!, Colors.green[100]!],
//               ),
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.green[300]!),
//             ),
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2E7D32),
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