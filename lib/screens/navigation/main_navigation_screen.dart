import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/auth_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/bloc/incidents_bloc.dart';
import 'package:manage_center/main.dart';
import 'package:manage_center/screens/analitics_screen.dart';
import 'package:manage_center/screens/dashboard_screen.dart';
import 'package:manage_center/screens/incidents_screen.dart';
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

  late final IncidentsBloc _incidentsBloc;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _incidentsBloc = IncidentsBloc(
      apiService: context.read<ApiService>(),
      storageService: context.read<StorageService>(),
    )..add(IncidentsInitEvent());

    // ✅ Слушаем переключение вкладок из push-уведомлений
    switchTabNotifier.addListener(_onSwitchTab);

    // ✅ Проверяем — может уведомление уже пришло при холодном старте
    if (switchTabNotifier.value != null) {
      _currentIndex = switchTabNotifier.value!;
      switchTabNotifier.value = null;
    }
  }

  @override
  void dispose() {
    switchTabNotifier.removeListener(_onSwitchTab);
    _incidentsBloc.close();
    super.dispose();
  }

  // ✅ Переключение вкладки по уведомлению
  void _onSwitchTab() {
    final tabIndex = switchTabNotifier.value;
    if (tabIndex != null) {
      setState(() {
        _currentIndex = tabIndex;
      });
      // Сбрасываем чтобы не срабатывало повторно
      switchTabNotifier.value = null;
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      },
      child: Scaffold(
        extendBody: true,
        body: _getCurrentScreen(),
        bottomNavigationBar: BlocBuilder<IncidentsBloc, IncidentsState>(
          bloc: _incidentsBloc,
          builder: (context, state) {
            final count =
                state is IncidentsLoadedState ? state.activeIncidentsCount : 0;

            return CustomBottomNavigation(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              activeIncidentsCount: count,
            );
          },
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
        return _buildTabNavigator(2, _buildIncidentsTab());
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
        return MaterialPageRoute(builder: (context) => child);
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

  Widget _buildUploadTab() => const AnalyticsScreen();

  Widget _buildIncidentsTab() {
    return BlocProvider.value(
      value: _incidentsBloc,
      child: const IncidentsScreen(),
    );
  }

  Widget _buildSettingsTab() => const SettingsScreen();
}
