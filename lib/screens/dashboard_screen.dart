import 'package:flutter/material.dart';
import 'package:manage_center/screens/Boiler_detail_screen.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';


//ДОБАВИТЬ ПО НАЖАТИЮ НА СТАТУСЫ ЧТОБЫ СТАНРОВИЛАСЬ ФИЛЬТРАЦИЯ

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Выйти из аккаунта?'),
                content: const Text('Вы уверены, что хотите выйти?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutEvent());
                      Navigator.pushAndRemoveUntil(
                        context,
                        SlideRightRoute(page: const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Выйти'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic
        },
        child: Column(
          children: [
            SearchBar(
              // Implement search functionality
            ),
            Expanded(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const SkeletonLoading();
                  }
                  return ListView.builder(
                    // Your list implementation
                  );
                },
              ),
            ),
          ],
        ),
      ),
        children: [
          // Статус котельных
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator('Норма', 63, Colors.green),
                _buildStatusIndicator('Авария', 8, Colors.red),
                _buildStatusIndicator('Внимание', 0, Colors.orange),
                _buildStatusIndicator('Отключено', 1, Colors.grey),
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
                  [
                    _buildBoilerButton('1', 'normal'),
                    _buildBoilerButton('2', 'normal'),
                    _buildBoilerButton('3', 'normal', 'MA'),
                    _buildBoilerButton('4', 'normal', 'MA'),
                    _buildBoilerButton('5', 'normal', 'MA'),
                    _buildBoilerButton('6', 'normal', 'MA'),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDistrictSection(
                  'Экс. Район - 1 (ЦТП)',
                  [
                    _buildBoilerButton('67', 'normal', 'A'),
                    _buildBoilerButton('70', 'normal', 'A'),
                    _buildBoilerButton('72', 'warning', 'A'),
                    _buildBoilerButton('73', 'normal', 'A'),
                  ],
                ),
                _buildDistrictSection(
                  'Эксплуатационный Район - 2',
                  [
                    _buildBoilerButton('7', 'normal'),
                    _buildBoilerButton('8', 'normal'),
                    _buildBoilerButton('9', 'normal', 'MA'),
                    _buildBoilerButton('10', 'normal', 'MA'),
                    _buildBoilerButton('11', 'error', 'MA'),
                    _buildBoilerButton('12', 'normal', 'MA'),
                  ],
                ),
                _buildDistrictSection(
                  'Эксплуатационный Район - 3',
                  [
                    _buildBoilerButton('7', 'normal'),
                    _buildBoilerButton('8', 'normal'),
                    _buildBoilerButton('9', 'normal', 'MA'),
                    _buildBoilerButton('10', 'normal', 'MA'),
                    _buildBoilerButton('11', 'normal', 'MA'),
                    _buildBoilerButton('12', 'normal', 'MA'),
                  ],
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
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
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
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictSection(String title, List<Widget> boilers) {
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
        children: boilers,
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