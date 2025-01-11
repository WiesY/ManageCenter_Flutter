import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/models/boiler_model.dart';
import 'package:manage_center/screens/Boiler_detail_screen.dart';
import 'package:manage_center/screens/login_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';

enum BoilerStatus {
  normal, // зеленый - данные за текущий час
  warning, // желтый - данные отсутствуют менее 10 минут
  error, // красный - данные отсутствуют более 10 минут
  disabled // серый - котельная отключена
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? _selectedFilter;
  List<BoilerWithLastData> _boilers = [];
  bool _isLoading = true;
  bool _isInitialized = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadBoilers();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadBoilers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadBoilers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final storageService = context.read<StorageService>();
      final apiService = context.read<ApiService>();

      final token = await storageService.getToken();
      if (token == null) {
        throw Exception('Токен авторизации не найден');
      }

      final boilers = await apiService.getBoilersWithLastData(token);

      if (!mounted) return;
      setState(() {
        _boilers = boilers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  BoilerStatus _getBoilerStatus(BoilerWithLastData boilerWithLastData) {
    if (boilerWithLastData.boiler.isDisabled) {
      return BoilerStatus.disabled;
    }

    if (boilerWithLastData.lastData == null) {
      return BoilerStatus.error;
    }

    final now = DateTime.now();
    final submitTime = boilerWithLastData.lastData!.submitDateTime;

    // Проверяем, соответствует ли час отправки текущему часу
    if (submitTime.hour == now.hour &&
        submitTime.day == now.day &&
        submitTime.month == now.month &&
        submitTime.year == now.year) {
      return BoilerStatus.normal;
    }

    // Проверяем, прошло ли меньше 10 минут с начала нового часа
    final timeDifference = now.difference(submitTime);
    if (timeDifference.inMinutes <= 10) {
      return BoilerStatus.warning;
    }

    return BoilerStatus.error;
  }

  Map<String, int> _countBoilersByStatus(List<BoilerWithLastData> boilers) {
    return {
      'Данные получены': boilers.where((b) {
        if (b.boiler.isDisabled) return false;
        if (b.lastData == null) return false;
        return _isCurrentHour(b.lastData!.submitDateTime);
      }).length,
      'Задержка отправки': boilers.where((b) {
        if (b.boiler.isDisabled) return false;
        if (b.lastData == null) return false;
        if (_isCurrentHour(b.lastData!.submitDateTime)) return false;
        return _isWithinWarningPeriod(b.lastData!.submitDateTime);
      }).length,
      'Пропуск отправки': boilers.where((b) {
        if (b.boiler.isDisabled) return false;
        if (b.lastData == null) return true;
        if (_isCurrentHour(b.lastData!.submitDateTime)) return false;
        return !_isWithinWarningPeriod(b.lastData!.submitDateTime);
      }).length,
      'Котельная отключена': boilers.where((b) => b.boiler.isDisabled).length,
    };
  }

  bool _isCurrentHour(DateTime submitTime) {
    final now = DateTime.now();
    return submitTime.hour == now.hour &&
        submitTime.day == now.day &&
        submitTime.month == now.month &&
        submitTime.year == now.year;
  }

  bool _isWithinWarningPeriod(DateTime submitTime) {
    final now = DateTime.now();
    final difference = now.difference(submitTime);
    return difference.inMinutes <= 20;
  }

  bool _isErrorPeriod(DateTime submitTime) {
    final now = DateTime.now();
    final difference = now.difference(submitTime);
    return difference.inMinutes > 20;
  }

  List<Widget> _filterBoilers(
      List<BoilerWithLastData> boilers, String? filter) {
    if (filter == null) {
      return boilers.map((boiler) => _buildBoilerButton(boiler)).toList();
    }

    return boilers
        .where((boiler) {
          final status = _getBoilerStatus(boiler);
          switch (filter) {
            case 'Данные получены':
              return status == BoilerStatus.normal;
            case 'Задержка отправки':
              return status == BoilerStatus.warning;
            case 'Пропуск отправки':
              return status == BoilerStatus.error;
            case 'Котельная отключена':
              return status == BoilerStatus.disabled;
            default:
              return true;
          }
        })
        .map((boiler) => _buildBoilerButton(boiler))
        .toList();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы действительно хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Группируем котельные по районам
    final boilersByDistrict = <int, List<BoilerWithLastData>>{};
    for (var boiler in _boilers) {
      boilersByDistrict
          .putIfAbsent(boiler.boiler.districtId, () => [])
          .add(boiler);
    }

    final boilerCounts = _countBoilersByStatus(_boilers);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Диспетчерская'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 12), // изменил отступы
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // равномерное распределение
              children: [
                _buildStatusIndicator('Данные получены',
                    boilerCounts['Данные получены']!, Colors.green),
                _buildStatusIndicator('Пропуск отправки',
                    boilerCounts['Пропуск отправки']!, Colors.red),
                _buildStatusIndicator('Задержка отправки',
                    boilerCounts['Задержка отправки']!, Colors.orange),
                _buildStatusIndicator('Котельная отключена',
                    boilerCounts['Котельная отключена']!, Colors.grey),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: boilersByDistrict.length,
              itemBuilder: (context, index) {
                final districtId = boilersByDistrict.keys.elementAt(index);
                final districtBoilers = boilersByDistrict[districtId]!;

                return _buildDistrictSection(
                  'Эксплуатационный Район - $districtId',
                  districtBoilers,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    final isSelected = _selectedFilter == label;

    return Expanded(
      // добавил Expanded
      child: Padding(
        // добавил отступы
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilter = isSelected ? null : label;
            });
          },
          child: Column(
            children: [
              Container(
                width: 36, // фиксированная ширина
                height: 36, // фиксированная высота
                decoration: BoxDecoration(
                  color: color.withOpacity(isSelected ? 0.3 : 0.1),
                  shape: BoxShape.circle,
                  border:
                      isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // уменьшил размер шрифта
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontSize: 11, // уменьшил размер шрифта
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center, // выравнивание по центру
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictSection(String title, List<BoilerWithLastData> boilers) {
    final filteredBoilers = _filterBoilers(boilers, _selectedFilter);

    if (filteredBoilers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
          padding: EdgeInsets.zero,
          children: filteredBoilers,
        ),
      ],
    );
  }

  Widget _buildBoilerButton(BoilerWithLastData boiler) {
    Color backgroundColor;

    if (boiler.boiler.isDisabled) {
      backgroundColor = Colors.grey;
    } else if (boiler.lastData == null) {
      backgroundColor = Colors.red;
    } else if (_isCurrentHour(boiler.lastData!.submitDateTime)) {
      backgroundColor = Colors.green;
    } else if (_isWithinWarningPeriod(boiler.lastData!.submitDateTime)) {
      backgroundColor = Colors.orange;
    } else {
      backgroundColor = Colors.red;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BoilerDetailScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                boiler.boiler.id.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (boiler.boiler.isModule || boiler.boiler.isAutomated)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (boiler.boiler.isModule)
                      const Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    if (boiler.boiler.isModule && boiler.boiler.isAutomated)
                      const Text(
                        ' • ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    if (boiler.boiler.isAutomated)
                      const Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
