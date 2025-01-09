import 'package:flutter/material.dart';
import 'package:manage_center/screens/Boiler_detail_screen.dart';
import 'package:manage_center/screens/login_screen.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';


//ДОБАВИТЬ ПО НАЖАТИЮ НА СТАТУСЫ ЧТОБЫ СТАНРОВИЛАСЬ ФИЛЬТРАЦИЯ

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? _selectedFilter;

  List<Widget> _filterBoilers(List<Widget> boilers, String? filter) {
  if (filter == null) return boilers;
  
  return boilers.where((boiler) {
    if (boiler is Material) {
      final inkWell = (boiler as Material).child as InkWell;
      final container = inkWell.child as Container;
      final column = container.child as Column;
      
      switch (filter) {
        case 'Норма':
          return boiler.color == Colors.green;
        case 'Авария':
          return boiler.color == Colors.red;
        case 'Внимание':
          return boiler.color == Colors.orange;
        case 'Отключено':
          return boiler.color == Colors.grey;
        default:
          return true;
      }
    }
    return false;
  }).toList();
}

Map<String, int> _countBoilersByStatus(List<List<Widget>> allBoilers) {
    Map<String, int> counts = {
      'Норма': 0,
      'Авария': 0,
      'Внимание': 0,
      'Отключено': 0,
    };

    for (var boilerList in allBoilers) {
      for (var boiler in boilerList) {
        if (boiler is Material) {
          if (boiler.color == Colors.green) {
            counts['Норма'] = counts['Норма']! + 1;
          } else if (boiler.color == Colors.red) {
            counts['Авария'] = counts['Авария']! + 1;
          } else if (boiler.color == Colors.orange) {
            counts['Внимание'] = counts['Внимание']! + 1;
          } else if (boiler.color == Colors.grey) {
            counts['Отключено'] = counts['Отключено']! + 1;
          }
        }
      }
    }
    return counts;
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
 @override
Widget build(BuildContext context) {
  // Создаем списки котельных для каждого района
  final List<List<Widget>> allBoilersList = [
    // ЭР-1
    [
      _buildBoilerButton('1', 'normal'),
      _buildBoilerButton('2', 'normal'),
      _buildBoilerButton('3', 'normal', 'MA'),
      _buildBoilerButton('4', 'normal', 'MA'),
      _buildBoilerButton('5', 'warning', 'MA'),
      _buildBoilerButton('6', 'normal', 'MA'),
    ],
    // ЭР-1 (ЦТП)
    [
      _buildBoilerButton('67', 'normal', 'A'),
      _buildBoilerButton('70', 'normal', 'A'),
      _buildBoilerButton('72', 'warning', 'A'),
      _buildBoilerButton('73', 'warning', 'A'),
    ],
    // ЭР-2
    [
      _buildBoilerButton('7', 'normal'),
      _buildBoilerButton('8', 'normal'),
      _buildBoilerButton('9', 'normal', 'MA'),
      _buildBoilerButton('10', 'normal', 'MA'),
      _buildBoilerButton('11', 'error', 'MA'),
      _buildBoilerButton('12', 'normal', 'MA'),
    ],
    // ЭР-3
    [
      _buildBoilerButton('7', 'normal'),
      _buildBoilerButton('8', 'error'),
      _buildBoilerButton('9', 'normal', 'MA'),
      _buildBoilerButton('10', 'normal', 'MA'),
      _buildBoilerButton('11', '', 'MA'),
      _buildBoilerButton('12', 'normal', 'MA'),
    ],
  ];

  // Подсчитываем статистику
  final boilerCounts = _countBoilersByStatus(allBoilersList);

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
        // Статус котельных с реальными данными
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusIndicator('Норма', boilerCounts['Норма']!, Colors.green),
              _buildStatusIndicator('Авария', boilerCounts['Авария']!, Colors.red),
              _buildStatusIndicator('Внимание', boilerCounts['Внимание']!, Colors.orange),
              _buildStatusIndicator('Отключено', boilerCounts['Отключено']!, Colors.grey),
            ],
          ),
        ),
        // Список районов с котельными
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDistrictSection(
                'Эксплуатационный Район - 1',
                allBoilersList[0],
              ),
              const SizedBox(height: 24),
              _buildDistrictSection(
                'Экс. Район - 1 (ЦТП)',
                allBoilersList[1],
              ),
              _buildDistrictSection(
                'Эксплуатационный Район - 2',
                allBoilersList[2],
              ),
              _buildDistrictSection(
                'Эксплуатационный Район - 3',
                allBoilersList[3],
              ),
            ],
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

 Widget _buildStatusIndicator(String label, int count, Color color) {
  final isSelected = _selectedFilter == label;
  
  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedFilter = isSelected ? null : label;
      });
    },
    child: Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(isSelected ? 0.3 : 0.1),
            shape: BoxShape.circle,
            border: isSelected 
              ? Border.all(color: color, width: 2)
              : null,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[600],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDistrictSection(String title, List<Widget> boilers) {
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: filteredBoilers,
      ),
    ],
  );
}

Widget _buildBoilerButton(String number, String status, [String? type]) {
  Color backgroundColor;
  switch (status) {
    case 'normal':
      backgroundColor = Colors.green;
      break;
    case 'warning':
      backgroundColor = Colors.orange;
      break;
    case 'error':
      backgroundColor = Colors.red;
      break;
    default:
      backgroundColor = Colors.grey;
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
        // Навигация к деталям котельной
      },
      child: Container(
        padding: const EdgeInsets.all(6), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (type != null)
              Text(
                type,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}