import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/bloc/boiler_detail_bloc.dart';
import 'package:manage_center/models/boiler_parameter_model.dart';
import 'package:manage_center/models/boiler_parameter_value_model.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';

enum BoilerStatus { normal, warning, error }

class BoilerState {
  final BoilerStatus status;
  final String statusText;
  final String lastUpdate;
  final Color statusColor;
  final Color textColor;

  BoilerState({
    required this.status,
    required this.statusText,
    required this.lastUpdate,
    required this.statusColor,
    required this.textColor,
  });

  factory BoilerState.normal() {
    // Используем московское время для отображения
    final moscowTime = DateTime.now().add(const Duration(hours: 3));
    return BoilerState(
      status: BoilerStatus.normal,
      statusText: 'В работе',
      lastUpdate: DateFormat('HH:mm').format(moscowTime),
      statusColor: const Color(0xFF4CAF50),
      textColor: const Color(0xFF2E7D32),
    );
  }

  factory BoilerState.warning() {
    // Используем московское время для отображения
    final moscowTime = DateTime.now().add(const Duration(hours: 3));
    return BoilerState(
      status: BoilerStatus.warning,
      statusText: 'Внимание',
      lastUpdate: DateFormat('HH:mm').format(moscowTime),
      statusColor: Colors.orange,
      textColor: Colors.orange[800]!,
    );
  }

  factory BoilerState.error() {
    // Используем московское время для отображения
    final moscowTime = DateTime.now().add(const Duration(hours: 3));
    return BoilerState(
      status: BoilerStatus.error,
      statusText: 'Авария',
      lastUpdate: DateFormat('HH:mm').format(moscowTime),
      statusColor: Colors.red,
      textColor: Colors.red[800]!,
    );
  }
}

class BoilerDetailScreen extends StatefulWidget {
  final int boilerId;
  final String boilerName;
  final String? districtName;

  const BoilerDetailScreen({
    Key? key,
    required this.boilerId,
    required this.boilerName,
    this.districtName,
  }) : super(key: key);

  @override
  _BoilerDetailScreenState createState() => _BoilerDetailScreenState();
}

class _BoilerDetailScreenState extends State<BoilerDetailScreen> {
  // Форматтеры для отображения времени
  final DateFormat timeFormatter = DateFormat('HH:mm:ss');
  final DateFormat dateTimeFormatter = DateFormat('dd.MM.yyyy HH:mm');
  final DateFormat dateRangeFormatter = DateFormat('dd.MM HH:mm');
  BoilerState _boilerState = BoilerState.normal();

  // Для управления выбранными параметрами
  List<BoilerParameter> _allParameters = [];
  Set<int> _selectedParameterIds = {};

  // Для выбора даты и времени - по умолчанию текущая минута
  DateTime _selectedDateTime = DateTime.now();

  DateTime _startDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
  DateTime _endDate = DateTime.now();
  String _selectedInterval = '60';

  // Для поиска параметров
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Устанавливаем текущую минуту (обнуляем секунды)
    _selectedDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      DateTime.now().hour,
      DateTime.now().minute,
    );

    // Загружаем только параметры при инициализации
    context.read<BoilerDetailBloc>().add(LoadBoilerParameters(widget.boilerId));
  }

  // Конвертирует время UTC в московское время (+3 часа)
  DateTime _toMoscowTime(DateTime utcTime) {
    return utcTime.add(const Duration(hours: 3));
  }

  // Конвертирует московское время в UTC для отправки на сервер
  DateTime _toUtcTime(DateTime moscowTime) {
    return moscowTime.subtract(const Duration(hours: 3));
  }

  // Форматирует время для отображения (в московском времени)
  String _formatTime(DateTime utcTime) {
    final moscowTime = _toMoscowTime(utcTime);
    return timeFormatter.format(moscowTime);
  }

  // Форматирует дату и время для отображения (в московском времени)
  String _formatDateTime(DateTime utcTime) {
    final moscowTime = _toMoscowTime(utcTime);
    return dateTimeFormatter.format(moscowTime);
  }

  // Форматирует дату и время для диапазона (в московском времени)
  String _formatDateRange(DateTime utcTime) {
    final moscowTime = _toMoscowTime(utcTime);
    return dateRangeFormatter.format(moscowTime);
  }

  Map<String, DateTime> _getSelectedDateRange() {
    return {
      'start': _startDate,
      'end': _endDate,
    };
  }

  // Метод для получения диапазона выбранной минуты
  Map<String, DateTime> _getSelectedMinuteRange() {
    final startOfMinute = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      _selectedDateTime.hour,
      _selectedDateTime.minute,
      0, // секунды = 0
    );

    final endOfMinute = startOfMinute
        .add(const Duration(minutes: 1))
        .subtract(const Duration(seconds: 1));

    return {
      'start': startOfMinute,
      'end': endOfMinute,
    };
  }

  void _loadDataForSelectedParameters() {
    if (_selectedParameterIds.isNotEmpty) {
      final timeRange = _getSelectedDateRange();

      context.read<BoilerDetailBloc>().add(LoadBoilerParameterValues(
            boilerId: widget.boilerId,
            startDate: timeRange['start']!,
            endDate: timeRange['end']!,
            selectedParameterIds: _selectedParameterIds.toList(),
            interval: int.parse(_selectedInterval),
          ));
    }
  }

  // Метод для выбора даты и времени (в московском времени)
  Future<void> _selectDateTime(BuildContext context) async {
    // Конвертируем текущее UTC время в московское для отображения в пикере
    final moscowDateTime = _toMoscowTime(_selectedDateTime);
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: moscowDateTime,
      firstDate: DateTime(2020),
      lastDate: _toMoscowTime(DateTime.now()),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) => _timePickerTheme(child!),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(moscowDateTime),
        builder: (context, child) => _timePickerTheme(child!),
      );

      if (pickedTime != null) {
        // Создаем дату в московском времени
        final selectedMoscowTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        // Конвертируем обратно в UTC для хранения и отправки на сервер
        setState(() {
          _selectedDateTime = _toUtcTime(selectedMoscowTime);
        });

        if (_selectedParameterIds.isNotEmpty) {
          _loadDataForSelectedParameters();
        }
      }
    }
  }

  // Выбор диапазона дат (в московском времени)
  Future<void> _selectDateRange(BuildContext context) async {
    // Конвертируем UTC время в московское для отображения
    final moscowStartDate = _toMoscowTime(_startDate);
    final moscowEndDate = _toMoscowTime(_endDate);
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _toMoscowTime(DateTime.now()),
      initialDateRange: DateTimeRange(start: moscowStartDate, end: moscowEndDate),
      locale: const Locale('ru', 'RU'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Выбираем время для начала (00:00)
      final TimeOfDay? startTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(moscowStartDate),
        builder: (context, child) => _timePickerTheme(child!),
      );

      if (startTime != null) {
        // Выбираем время для конца (текущее время если сегодня)
        final TimeOfDay? endTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(moscowEndDate),
          builder: (context, child) => _timePickerTheme(child!),
        );

        if (endTime != null) {
          // Создаем даты в московском времени
          final selectedMoscowStartDate = DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
            startTime.hour,
            startTime.minute,
          );
          
          final selectedMoscowEndDate = DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            endTime.hour,
            endTime.minute,
          );
          
          // Конвертируем обратно в UTC для хранения и отправки на сервер
          setState(() {
            _startDate = _toUtcTime(selectedMoscowStartDate);
            _endDate = _toUtcTime(selectedMoscowEndDate);
          });

          if (_selectedParameterIds.isNotEmpty) {
            _loadDataForSelectedParameters();
          }
        }
      }
    }
  }

  void _showIntervalDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите интервал',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildIntervalOption('1', 'Каждую минуту'),
              _buildIntervalOption('5', 'Каждые 5 минут'),
              _buildIntervalOption('15', 'Каждые 15 минут'),
              _buildIntervalOption('60', 'Каждый час'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntervalOption(String value, String label) {
    final isSelected = _selectedInterval == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedInterval = value);
        Navigator.pop(context);
        if (_selectedParameterIds.isNotEmpty) {
          _loadDataForSelectedParameters();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePickerTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),
          onPrimary: Colors.white,
        ),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child,
      ),
    );
  }

  // Фильтрация параметров по поиску
  List<BoilerParameter> _getFilteredParameters() {
    if (_searchQuery.isEmpty) {
      return _allParameters;
    }

    return _allParameters.where((parameter) {
      return parameter.paramDescription
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showParameterSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredParameters = _getFilteredParameters();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Заголовок с ручкой для перетаскивания
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Выберите параметры',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Информация о выбранном времени
                  // Container(
                  //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  //   padding: const EdgeInsets.all(12),
                  //   decoration: BoxDecoration(
                  //     color: Colors.blue[50],
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(color: Colors.blue[200]!),
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Icon(Icons.access_time, color: Colors.blue[700], size: 18),
                  //           const SizedBox(width: 8),
                  //           Text(
                  //             'Данные за выбранную минуту',
                  //             style: TextStyle(
                  //               fontWeight: FontWeight.bold,
                  //               color: Colors.blue[700],
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 4),
                  //       Text(
                  //         _formatDateTime(_selectedDateTime),
                  //         style: TextStyle(
                  //           fontSize: 14,
                  //           fontWeight: FontWeight.w500,
                  //           color: Colors.blue[700],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  
                  // Поле поиска
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Поиск параметров...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  
                  // Кнопки быстрого выбора
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _selectedParameterIds =
                                    filteredParameters.map((p) => p.id).toSet();
                              });
                            },
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Выбрать все'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                _selectedParameterIds.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Очистить'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Счетчик параметров
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Доступно: ${filteredParameters.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _selectedParameterIds.isEmpty
                                ? Colors.red[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedParameterIds.isEmpty
                                  ? Colors.red[300]!
                                  : Colors.green[300]!,
                            ),
                          ),
                          child: Text(
                            'Выбрано: ${_selectedParameterIds.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _selectedParameterIds.isEmpty
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Список параметров
                  Expanded(
                    child: filteredParameters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Параметры не найдены',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredParameters.length,
                            itemBuilder: (context, index) {
                              final parameter = filteredParameters[index];
                              final isSelected = _selectedParameterIds
                                  .contains(parameter.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green[50] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green[300]!
                                        : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: CheckboxListTile(
                                  title: Text(
                                    parameter.paramDescription,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          parameter.valueType,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ID: ${parameter.id}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: isSelected,
                                  dense: true,
                                  activeColor: Colors.green[700],
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        _selectedParameterIds
                                            .add(parameter.id);
                                      } else {
                                        _selectedParameterIds
                                            .remove(parameter.id);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Кнопки действий
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Отмена'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedParameterIds.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(dialogContext);
                                    setState(() {
                                      _searchQuery = ''; // Сбрасываем поиск
                                    });
                                    _loadDataForSelectedParameters();
                                  },
                            icon: const Icon(Icons.check),
                            label: Text('Применить (${_selectedParameterIds.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

 void _showStatusDetails(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _boilerState.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Информация о мониторинге',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _boilerState.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusDetailRow('Статус', _boilerState.statusText),
            _buildStatusDetailRow('Котельная', widget.boilerName),
            if (widget.districtName != null)
              _buildStatusDetailRow('Район', widget.districtName!),
            _buildStatusDetailRow(
              'Выбрано параметров', '${_selectedParameterIds.length}'),
            _buildStatusDetailRow('Диапазон времени', 
              '${_formatDateRange(_startDate)} - ${_formatDateRange(_endDate)}'),
            _buildStatusDetailRow('Интервал', _getIntervalText()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _selectDateRange(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.date_range, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Изменить диапазон',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Закрыть'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

  String _getIntervalText() {
    switch (_selectedInterval) {
      case '1':
        return '1 мин';
      case '5':
        return '5 мин';
      case '15':
        return '15 мин';
      case '60':
        return '1 час';
      default:
        return '1 час';
    }
  }

  Widget _buildStatusDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.boilerName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (widget.districtName != null)
              Text(
                widget.districtName!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _allParameters.isNotEmpty
                ? _showParameterSelectionDialog
                : null,
            tooltip: 'Выбрать параметры',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель выбора времени
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
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
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.date_range,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${_formatDateRange(_startDate)} - ${_formatDateRange(_endDate)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white24,
                ),
                InkWell(
                  onTap: _showIntervalDialog,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _getIntervalText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Статус панель
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showStatusDetails(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _boilerState.statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _boilerState.statusColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _boilerState.statusText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _boilerState.textColor,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.settings,
                                    size: 14, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '${_selectedParameterIds.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    color: Colors.blue[700],
                    tooltip: 'Обновить данные',
                    onPressed: () {
                      _loadDataForSelectedParameters();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Основной контент с BlocBuilder
          Expanded(
            child: BlocBuilder<BoilerDetailBloc, BoilerDetailState>(
              builder: (context, state) {
                if (state is BoilerDetailLoadInProgress) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2E7D32)),
                        ),
                        SizedBox(height: 16),
                        Text('Загрузка данных...'),
                      ],
                    ),
                  );
                }

                if (state is BoilerDetailLoadFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Ошибка загрузки данных',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            state.error,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _loadDataForSelectedParameters(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Попробовать снова'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BoilerDetailParametersLoaded) {
                  // Сохраняем параметры и показываем интерфейс выбора
                  _allParameters = state.parameters;

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.tune,
                              size: 40, color: Colors.green[700]),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Выберите параметры для мониторинга',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Доступно ${_allParameters.length} параметров',
                            style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  color: Colors.blue[700], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(_selectedDateTime),
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showParameterSelectionDialog,
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Выбрать параметры'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF2E7D32),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectDateTime(context),
                                  icon: const Icon(Icons.access_time),
                                  label: const Text('Изменить время'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                    side: BorderSide(color: Colors.blue[300]!),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BoilerDetailValuesLoaded) {
                  if (state.values.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.info_outline,
                                size: 40, color: Colors.orange[700]),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Нет данных за выбранное время',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Попробуйте выбрать другое время или параметры',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _loadDataForSelectedParameters,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Обновить'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectDateTime(context),
                                    icon: const Icon(Icons.access_time),
                                    label: const Text('Другое время'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue[700],
                                      side: BorderSide(color: Colors.blue[300]!),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildParameterValuesList(state.values);
                }

                return const Center(child: Text('Инициализация...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterValuesList(List<BoilerParameterValue> values) {
    // Группируем значения по времени (с точностью до секунды)
    final Map<DateTime, List<BoilerParameterValue>> groupedValues = {};

    for (var value in values) {
      final timeKey = DateTime(
        value.receiptDate.year,
        value.receiptDate.month,
        value.receiptDate.day,
        value.receiptDate.hour,
        value.receiptDate.minute,
        value.receiptDate.second,
      );

      groupedValues.putIfAbsent(timeKey, () => []).add(value);
    }

    final sortedTimes = groupedValues.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Сортируем по убыванию (новые сверху)

    return RefreshIndicator(
      onRefresh: () async {
        _loadDataForSelectedParameters();
        await context
            .read<BoilerDetailBloc>()
            .stream
            .firstWhere((state) => state is! BoilerDetailLoadInProgress);
      },
      child: Column(
        children: [
          // Заголовок со статистикой
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    'Записей', '${sortedTimes.length}', Icons.timeline),
                _buildStatItem('Параметров', '${_selectedParameterIds.length}',
                    Icons.settings),
                _buildStatItem(
                    'Значений', '${values.length}', Icons.data_usage),
              ],
            ),
          ),

          // Список данных
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: sortedTimes.length,
              itemBuilder: (context, index) {
                final time = sortedTimes[index];
                final timeValues = groupedValues[time]!;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      childrenPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTime(time), // Используем московское время
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Запись ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E7D32),
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${timeValues.length} парам.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxHeight: 400),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Scrollbar(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: timeValues.length,
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.grey[200],
                                height: 1,
                              ),
                              itemBuilder: (context, paramIndex) {
                                final value = timeValues[paramIndex];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: _buildParameterRow(
                                    value.parameter.paramDescription.isEmpty
                                        ? 'Параметр ID: ${value.parameter.id}'
                                        : value.parameter.paramDescription,
                                    value.displayValue,
                                    value.parameter.valueType,
                                    value.parameter.id,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(
      String label, String value, String valueType, int parameterId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      valueType,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: $parameterId',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}