import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';
// import 'path_to_your/custom_nav_bar.dart';

enum BoilerStatus {
  normal,
  warning,
  error
}

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
    return BoilerState(
      status: BoilerStatus.normal,
      statusText: 'В работе',
      lastUpdate: DateFormat('HH:mm').format(DateTime.now()),
      statusColor: Color(0xFF4CAF50),
      textColor: Color(0xFF2E7D32),
    );
  }

  factory BoilerState.warning() {
    return BoilerState(
      status: BoilerStatus.warning,
      statusText: 'Внимание',
      lastUpdate: DateFormat('HH:mm').format(DateTime.now()),
      statusColor: Colors.orange,
      textColor: Colors.orange[800]!,
    );
  }

  factory BoilerState.error() {
    return BoilerState(
      status: BoilerStatus.error,
      statusText: 'Авария',
      lastUpdate: DateFormat('HH:mm').format(DateTime.now()),
      statusColor: Colors.red,
      textColor: Colors.red[800]!,
    );
  }
}

class BoilerDetailScreen extends StatefulWidget {
  @override
  _BoilerDetailScreenState createState() => _BoilerDetailScreenState();
}

class _BoilerDetailScreenState extends State<BoilerDetailScreen> {
  DateTime selectedDate = DateTime.now();
  final DateFormat dateFormatter = DateFormat('dd.MM.yyyy');
  BoilerState _boilerState = BoilerState.normal();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        loadBoilerData(selectedDate);
      });
    }
  }

  void loadBoilerData(DateTime date) {
    // Логика загрузки данных
  }

  void _showStatusDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Состояние котельной',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildStatusDetailRow('Статус', _boilerState.statusText),
              _buildStatusDetailRow('Последнее обновление', _boilerState.lastUpdate),
              _buildStatusDetailRow('Температура воды', '75°C'),
              _buildStatusDetailRow('Давление', '0.6 МПа'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Закрыть'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Котельная №3',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Истра[1]',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Выбор даты
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF1B5E20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    dateFormatter.format(selectedDate),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Статус панель
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showStatusDetails(context),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
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
                                  color: _boilerState.statusColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            _boilerState.statusText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _boilerState.textColor,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Обновлено: ${_boilerState.lastUpdate}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.history),
                    color: Colors.blue[700],
                    tooltip: 'Журнал событий',
                    onPressed: () {
                      // Открытие журнала событий
                    },
                  ),
                ),
              ],
            ),
          ),

          // Список записей
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: 9,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Text(
                          'Запись ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          '${17-index}:00:00',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailRow('Оператор:', 'Александрова Н. Г.'),
                            _buildDetailRow('Время отправки:', '${17-index}:06:${23+(index*3)}'),
                            _buildDetailRow('Время фиксации:', '${17-index}:00:00'),
                            Divider(),
                            _buildParameterRow(
                              'Расход:',
                              '${120 + index * 5} м³/ч',
                              'Давление:',
                              '${0.6 + index * 0.1} МПа',
                            ),
                            _buildParameterRow(
                              'Подпитка:',
                              '${2 + index * 0.5} м³/ч',
                              'Температура:',
                              '${75 + index} °C',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),// Замени на свой виджет
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(currentIndex: 0, onTap: (int){}),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(String label1, String value1, String label2, String value2) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  label1,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  value1,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  label2,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  value2,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}