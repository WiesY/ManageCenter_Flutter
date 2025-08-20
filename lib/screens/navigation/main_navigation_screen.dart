import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/screens/dashboard_screen.dart';
import 'package:manage_center/screens/login_screen.dart';
import 'package:manage_center/screens/settings/settings_menu_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Ключи для навигации каждого таба
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Главная
    GlobalKey<NavigatorState>(), // Выгрузить
    GlobalKey<NavigatorState>(), // Диалоги
    GlobalKey<NavigatorState>(), // Настройки
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Если тапнули на текущий таб, возвращаемся к корню этого таба
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      // Переключаемся на новый таб
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          // Это состояние после успешного выхода
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false
          );
        }
      },
      child: Scaffold(
        body: _getCurrentScreen(),
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildTabNavigator(0, _buildHomeTab());
      case 1:
        return _buildTabNavigator(1, _buildUploadTab());
      case 2:
        return _buildTabNavigator(2, _buildMessagesTab());
      case 3:
        return _buildTabNavigator(3, _buildSettingsTab());
      default:
        return _buildTabNavigator(0, _buildHomeTab());
    }
  }

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }

  Widget _buildHomeTab() {
    return BlocProvider<BoilersBloc>(
      create: (context) => BoilersBloc(
        apiService: context.read<ApiService>(),
        storageService: context.read<StorageService>(),
      )..add(FetchBoilers()),
      child: const DashboardScreen(),
    );
  }

  Widget _buildUploadTab() {
    return const UploadScreen();
  }

  Widget _buildMessagesTab() {
    return const MessagesScreen();
  }

  Widget _buildSettingsTab() {
    return const SettingsScreen();
  }
}

// Временные экраны для табов, которые еще не реализованы
class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выгрузить'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Экран выгрузки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Функционал в разработке',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Диалоги'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Диалоги',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Функционал в разработке',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}