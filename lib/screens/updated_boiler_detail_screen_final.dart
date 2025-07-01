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

// class _BoilerDetailScreenState extends State<BoilerDetailScreen> {
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

//   @override
//   void initState() {
//     super.initState();
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

//       context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
//         boilerId: widget.boilerId,
//         startDate: timeRange['start']!,
//         endDate: timeRange['end']!,
//         selectedParameterIds: _selectedParameterIds.toList(),
//       ));
//     }
//   }

//   // Выбор даты и времени
//   Future<void> _selectDateTime(BuildContext context) async {
//     // Сначала выбираем дату
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: _selectedDateTime,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF2E7D32),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (pickedDate != null) {
//       // Затем выбираем время
//       final TimeOfDay? pickedTime = await showTimePicker(
//         context: context,
//         initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
//         builder: (context, child) {
//           return Theme(
//             data: Theme.of(context).copyWith(
//               colorScheme: const ColorScheme.light(
//                 primary: Color(0xFF2E7D32),
//                 onPrimary: Colors.white,
//                 surface: Colors.white,
//                 onSurface: Colors.black,
//               ),
//             ),
//             child: child!,
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

//         // Если есть выбранные параметры, загружаем данные
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
//       return parameter.parameterDescription
//           .toLowerCase()
//           .contains(_searchQuery.toLowerCase());
//     }).toList();
//   }

//   void _showParameterSelectionDialog() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             final filteredParameters = _getFilteredParameters();

//             return AlertDialog(
//               title: const Text('Выберите параметры для мониторинга'),
//               content: Container(
//                 width: double.maxFinite,
//                 height: 600,
//                 child: Column(
//                   children: [
//                     // Информация о выбранном времени
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.blue[200]!),
//                       ),
//                       child: Column(
//                         children: [
//                           const Text(
//                             'Данные за выбранную минуту',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             dateTimeFormatter.format(_selectedDateTime),
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.blue[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Кнопки быстрого выбора
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextButton.icon(
//                             onPressed: () {
//                               setDialogState(() {
//                                 _selectedParameterIds = filteredParameters.map((p) => p.id).toSet();
//                               });
//                             },
//                             icon: const Icon(Icons.select_all, size: 16),
//                             label: const Text('Все'),
//                             style: TextButton.styleFrom(
//                               backgroundColor: Colors.green[50],
//                               foregroundColor: Colors.green[700],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextButton.icon(
//                             onPressed: () {
//                               setDialogState(() {
//                                 _selectedParameterIds.clear();
//                               });
//                             },
//                             icon: const Icon(Icons.clear_all, size: 16),
//                             label: const Text('Очистить'),
//                             style: TextButton.styleFrom(
//                               backgroundColor: Colors.red[50],
//                               foregroundColor: Colors.red[700],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: TextButton.icon(
//                             onPressed: () {
//                               setDialogState(() {
//                                 // Выбираем первые 5 параметров из отфильтрованных
//                                 _selectedParameterIds = filteredParameters
//                                     .take(5)
//                                     .map((p) => p.id)
//                                     .toSet();
//                               });
//                             },
//                             icon: const Icon(Icons.star, size: 16),
//                             label: const Text('Топ-5'),
//                             style: TextButton.styleFrom(
//                               backgroundColor: Colors.orange[50],
//                               foregroundColor: Colors.orange[700],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Divider(),

//                     // Счетчик параметров
//                     Container(
//                       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Доступно параметров: ${filteredParameters.length}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           Text(
//                             'Выбрано: ${_selectedParameterIds.length}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                               color: _selectedParameterIds.isEmpty ? Colors.red : Colors.green,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     // Поле поиска
//                     TextField(
//                       decoration: InputDecoration(
//                         hintText: 'Поиск параметров...',
//                         prefixIcon: const Icon(Icons.search, size: 20),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       ),
//                       onChanged: (value) {
//                         setDialogState(() {
//                           _searchQuery = value;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 8),

//                     // Список параметров
//                     Expanded(
//                       child: filteredParameters.isEmpty 
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   'Параметры не найдены',
//                                   style: TextStyle(color: Colors.grey[600]),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : ListView.builder(
//                             itemCount: filteredParameters.length,
//                             itemBuilder: (context, index) {
//                               final parameter = filteredParameters[index];
//                               final isSelected = _selectedParameterIds.contains(parameter.id);

//                               return Card(
//                                 margin: const EdgeInsets.symmetric(vertical: 2),
//                                 elevation: isSelected ? 2 : 0,
//                                 color: isSelected ? Colors.green[50] : null,
//                                 child: CheckboxListTile(
//                                   title: Text(
//                                     parameter.parameterDescription, // Показываем название параметра
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   subtitle: Row(
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                         decoration: BoxDecoration(
//                                           color: Colors.blue[100],
//                                           borderRadius: BorderRadius.circular(4),
//                                         ),
//                                         child: Text(
//                                           parameter.valueType,
//                                           style: TextStyle(
//                                             fontSize: 10,
//                                             color: Colors.blue[700],
//                                             fontWeight: FontWeight.w500,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Text(
//                                         'ID: ${parameter.id}',
//                                         style: TextStyle(
//                                           fontSize: 10,
//                                           color: Colors.grey[500],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   value: isSelected,
//                                   dense: true,
//                                   activeColor: Colors.green,
//                                   onChanged: (bool? value) {
//                                     setDialogState(() {
//                                       if (value == true) {
//                                         _selectedParameterIds.add(parameter.id);
//                                       } else {
//                                         _selectedParameterIds.remove(parameter.id);
//                                       }
//                                     });
//                                   },
//                                 ),
//                               );
//                             },
//                           ),
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(dialogContext),
//                   child: const Text('Отмена'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _selectedParameterIds.isEmpty ? null : () {
//                     Navigator.pop(dialogContext);
//                     setState(() {
//                       _searchQuery = ''; // Сбрасываем поиск
//                     });
//                     _loadDataForSelectedParameters();
//                   },
//                   icon: const Icon(Icons.check),
//                   label: Text('Применить (${_selectedParameterIds.length})'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF2E7D32),
//                     disabledBackgroundColor: Colors.grey[300],
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   void _showStatusDetails(BuildContext context) {
//     final timeRange = _getSelectedMinuteRange();

//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) {
//         return Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Информация о мониторинге',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _buildStatusDetailRow('Статус', _boilerState.statusText),
//               _buildStatusDetailRow('Котельная', widget.boilerName),
//               if (widget.districtName != null)
//                 _buildStatusDetailRow('Район', widget.districtName!),
//               _buildStatusDetailRow('Выбрано параметров', '${_selectedParameterIds.length}'),
//               _buildStatusDetailRow('Выбранное время', dateTimeFormatter.format(_selectedDateTime)),
//               _buildStatusDetailRow('Период данных', 'Одна минута'),
//               const SizedBox(height: 16),
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
//                         backgroundColor: Colors.blue,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF2E7D32),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text('Закрыть'),
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

//   Widget _buildStatusDetailRow(String label, String value) {
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
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
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             if (widget.districtName != null)
//               Text(
//                 widget.districtName!,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   color: Colors.white,
//                 ),
//               ),
//           ],
//         ),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF2E7D32),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.tune, color: Colors.white),
//             onPressed: _allParameters.isNotEmpty ? _showParameterSelectionDialog : null,
//             tooltip: 'Выбрать параметры',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Выбор времени
//           InkWell(
//             onTap: () => _selectDateTime(context),
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF1B5E20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black26,
//                     offset: Offset(0, 2),
//                     blurRadius: 4,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.access_time,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Время: ${dateTimeFormatter.format(_selectedDateTime)}',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   const Icon(
//                     Icons.edit,
//                     color: Colors.white70,
//                     size: 16,
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // Статус панель
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(
//                 bottom: BorderSide(color: Colors.grey[200]!, width: 1),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: InkWell(
//                     onTap: () => _showStatusDetails(context),
//                     child: Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 12,
//                             height: 12,
//                             decoration: BoxDecoration(
//                               color: _boilerState.statusColor,
//                               shape: BoxShape.circle,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: _boilerState.statusColor.withOpacity(0.4),
//                                   blurRadius: 8,
//                                   spreadRadius: 2,
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Text(
//                             _boilerState.statusText,
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                               color: _boilerState.textColor,
//                             ),
//                           ),
//                           const Spacer(),
//                           Text(
//                             'Параметров: ${_selectedParameterIds.length}',
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blue[100]!),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.refresh),
//                     color: Colors.blue[700],
//                     tooltip: 'Обновить данные',
//                     onPressed: () {
//                       _loadDataForSelectedParameters();
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Основной контент с BlocBuilder
//           Expanded(
//             child: BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
//               builder: (context, state) {
//                 if (state is BoilerDetailLoadInProgress) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 16),
//                         Text('Загрузка данных...'),
//                       ],
//                     ),
//                   );
//                 }

//                 if (state is BoilerDetailLoadFailure) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.error_outline, size: 64, color: Colors.red),
//                         const SizedBox(height: 16),
//                         const Text(
//                           'Ошибка загрузки данных',
//                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           state.error,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed: () => _loadDataForSelectedParameters(),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF2E7D32),
//                           ),
//                           child: const Text('Попробовать снова'),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 if (state is BoilerDetailParametersLoaded) {
//                   // Сохраняем параметры и показываем интерфейс выбора
//                   _allParameters = state.parameters;

//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.tune, size: 64, color: Colors.grey),
//                         const SizedBox(height: 16),
//                         const Text(
//                           'Выберите параметры для мониторинга',
//                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Доступно ${_allParameters.length} параметров',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Время: ${dateTimeFormatter.format(_selectedDateTime)}',
//                           style: TextStyle(color: Colors.blue[600], fontSize: 14, fontWeight: FontWeight.w500),
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             ElevatedButton.icon(
//                               onPressed: _showParameterSelectionDialog,
//                               icon: const Icon(Icons.settings),
//                               label: const Text('Выбрать параметры'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF2E7D32),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             ElevatedButton.icon(
//                               onPressed: () => _selectDateTime(context),
//                               icon: const Icon(Icons.access_time),
//                               label: const Text('Изменить время'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blue,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 if (state is BoilerDetailValuesLoaded) {
//                   if (state.values.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.info_outline, size: 64, color: Colors.grey),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'Нет данных за выбранное время',
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Попробуйте выбрать другое время или параметры',
//                             style: TextStyle(color: Colors.grey[600]),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               ElevatedButton.icon(
//                                 onPressed: _loadDataForSelectedParameters,
//                                 icon: const Icon(Icons.refresh),
//                                 label: const Text('Обновить'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF2E7D32),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               ElevatedButton.icon(
//                                 onPressed: () => _selectDateTime(context),
//                                 icon: const Icon(Icons.access_time),
//                                 label: const Text('Другое время'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return _buildParameterValuesList(state.values);
//                 }

//                 return const Center(child: Text('Инициализация...'));
//               },
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: CustomBottomNavigation(
//         currentIndex: 0, 
//         onTap: (int) {}
//       ),
//     );
//   }

//   Widget _buildParameterValuesList(List<BoilerParameterValue> values) {
//     // Группируем значения по времени (с точностью до секунды)
//     final Map<DateTime, List<BoilerParameterValue>> groupedValues = {};

//     for (var value in values) {
//       final timeKey = DateTime(
//         value.dateTime.year,
//         value.dateTime.month,
//         value.dateTime.day,
//         value.dateTime.hour,
//         value.dateTime.minute,
//         value.dateTime.second,
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
//       child: Column(
//         children: [
//           // Заголовок со статистикой
//           Container(
//             padding: const EdgeInsets.all(16),
//             margin: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildStatItem('Записей', '${sortedTimes.length}', Icons.timeline),
//                 _buildStatItem('Параметров', '${_selectedParameterIds.length}', Icons.settings),
//                 _buildStatItem('Значений', '${values.length}', Icons.data_usage),
//               ],
//             ),
//           ),

//           // Список данных
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               itemCount: sortedTimes.length,
//               itemBuilder: (context, index) {
//                 final time = sortedTimes[index];
//                 final timeValues = groupedValues[time]!;

//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 4),
//                   elevation: 2,
//                   child: ExpansionTile(
//                     title: Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF2E7D32),
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Text(
//                             timeFormatter.format(time),
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           'Запись ${index + 1}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w500,
//                             color: Color(0xFF2E7D32),
//                           ),
//                         ),
//                         const Spacer(),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: Colors.blue[100],
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             '${timeValues.length} пар.',
//                             style: TextStyle(
//                               color: Colors.blue[700],
//                               fontSize: 11,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     children: [
//                       Container(
//                         constraints: const BoxConstraints(maxHeight: 400),
//                         child: Scrollbar(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: timeValues.length,
//                             itemBuilder: (context, paramIndex) {
//                               final value = timeValues[paramIndex];
//                               return Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                                 decoration: BoxDecoration(
//                                   color: paramIndex.isEven ? Colors.grey[50] : Colors.white,
//                                 ),
//                                 child: _buildParameterRow(
//                                   value.parameterDescription, // Показываем полное название параметра
//                                   value.displayValue,
//                                   value.valueType,
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String value, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: const Color(0xFF2E7D32), size: 20),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF2E7D32),
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildParameterRow(String label, String value, String valueType) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           flex: 3,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label, // Полное название параметра
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 13,
//                 ),
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 4),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(3),
//                 ),
//                 child: Text(
//                   valueType,
//                   style: TextStyle(
//                     fontSize: 9,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           flex: 1,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             decoration: BoxDecoration(
//               color: Colors.green[50],
//               borderRadius: BorderRadius.circular(6),
//               border: Border.all(color: Colors.green[200]!),
//             ),
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2E7D32),
//                 fontSize: 13,
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