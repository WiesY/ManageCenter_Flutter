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
import 'package:manage_center/screens/water_losses_screen.dart';
import 'package:manage_center/services/api_service.dart';
import 'package:manage_center/services/signalr_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';
import 'package:manage_center/services/app_update_service.dart';
import 'package:manage_center/widgets/notification_toast.dart';
import 'package:manage_center/widgets/update_dialog.dart';

enum _NotificationType { alarm, resolved, connection, disconnection }

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final IncidentsBloc _incidentsBloc;
  late final SignalRService _signalRService;
  late final BoilersBloc _boilersBloc;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _boilersBloc = BoilersBloc(
      apiService: context.read<ApiService>(),
      storageService: context.read<StorageService>(),
    )..add(FetchBoilers());

    _incidentsBloc = IncidentsBloc(
      apiService: context.read<ApiService>(),
      storageService: context.read<StorageService>(),
    )..add(IncidentsInitEvent());

    switchTabNotifier.addListener(_onSwitchTab);

    if (switchTabNotifier.value != null) {
      _currentIndex = switchTabNotifier.value!;
      switchTabNotifier.value = null;
    }
    _initSignalR();
  }

  @override
  void dispose() {
    // 1) синхронно убираем колбэки — старые сообщения SignalR пойдут "в никуда"
    _signalRService.onNewBoilerParametersData = null;
    _signalRService.onNewAlarm = null;
    _signalRService.onDeviceStatusChanged = null;
    _signalRService.onAlarmResolved = null;

    // 2) запускаем дисконнект (fire-and-forget — dispose не может быть async)
    _signalRService.disconnect();

    switchTabNotifier.removeListener(_onSwitchTab);
    _incidentsBloc.close();
    _boilersBloc.close();
    super.dispose();
  }

  void _onSwitchTab() {
    final tabIndex = switchTabNotifier.value;
    if (tabIndex != null) {
      setState(() {
        _currentIndex = tabIndex;
      });
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

  // Безопасно достаём int из payload (приходит int / num / String)
  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Future<void> _initSignalR() async {
    _signalRService = context.read<SignalRService>();
    final token = await context.read<StorageService>().getToken();
    if (token != null) {
      // 1. Параметры котельных
      _signalRService.onNewBoilerParametersData = (boilerId, newData) {
        if (!mounted || _boilersBloc.isClosed) return;
        print('[SignalR] Котельная $boilerId: $newData');
        _boilersBloc.add(BoilerParametersUpdatedEvent(boilerId, newData));
      };

      // 2. Новая авария
      _signalRService.onNewAlarm = (alarmData) {
        print('[SignalR] Новая авария в UI: $alarmData');
        _incidentsBloc.add(IncidentsNewAlarmReceivedEvent(alarmData));

        final boilerId = _asInt(alarmData['boilerId']);
        print('[Main] onNewAlarm parsed boilerId=$boilerId');
        if (boilerId != null) {
          _boilersBloc.add(BoilerEmergencyStatusChangedEvent(boilerId, true));
        }

        final boilerName = alarmData['boilerName']?.toString() ?? 'Объект';
        final description = alarmData['description']?.toString() ?? 'Авария';
        _showNotification(
          title: boilerName,
          message: description,
          type: _NotificationType.alarm,
        );
      };

      // 3. Изменение статуса связи
      _signalRService.onDeviceStatusChanged = (statusData) {
        print('[SignalR] Статус изменился в UI: $statusData');

        final boilerId = _asInt(statusData['boilerId']);
        final status = statusData['status']?.toString().toLowerCase() ?? '';
        final hasConnection = status != 'offline';
        print(
            '[Main] onDeviceStatusChanged boilerId=$boilerId hasConnection=$hasConnection');

        if (boilerId != null) {
          _boilersBloc.add(
            BoilerConnectionStatusChangedEvent(boilerId, hasConnection),
          );
        }

        final name = statusData['name']?.toString() ?? 'Объект';
        final statusRaw = statusData['status']?.toString() ?? '';
        _showNotification(
          title: name,
          message: statusRaw,
          type: hasConnection
              ? _NotificationType.connection
              : _NotificationType.disconnection,
        );
      };

      // 4. Авария закрыта
      _signalRService.onAlarmResolved = (resolvedData) {
        print('[SignalR] Авария закрыта в UI: $resolvedData');
        _incidentsBloc.add(IncidentsAlarmResolvedEvent(resolvedData));

        final boilerId = _asInt(resolvedData['boilerId']);
        final hasActiveAlarms = resolvedData['hasActiveAlarms'] == true;
        print(
            '[Main] onAlarmResolved boilerId=$boilerId hasActiveAlarms=$hasActiveAlarms');

        if (boilerId != null) {
          _boilersBloc.add(
            BoilerEmergencyStatusChangedEvent(boilerId, hasActiveAlarms),
          );
        }

        final boilerName = resolvedData['boilerName']?.toString() ?? 'Объект';
        final paramName = resolvedData['parameterName']?.toString() ?? '';
        _showNotification(
          title: boilerName,
          message: paramName.isNotEmpty
              ? '$paramName — авария устранена'
              : 'Авария устранена',
          type: _NotificationType.resolved,
        );
      };

      await _signalRService.connect(token);
    }
  }

  void _showNotification({
    required String title,
    required String message,
    required _NotificationType type,
  }) {
    if (!mounted) return;

    final Color bgColor;
    final Color borderColor;
    final IconData icon;
    final Color iconColor;

    switch (type) {
      case _NotificationType.alarm:
        bgColor = const Color(0xFFFFF5F5);
        borderColor = const Color(0xFFE53E3E);
        icon = Icons.warning_rounded;
        iconColor = const Color(0xFFE53E3E);
        break;
      case _NotificationType.resolved:
        bgColor = const Color(0xFFF0FFF4);
        borderColor = Colors.green;
        icon = Icons.check_circle_rounded;
        iconColor = Colors.green;
        break;
      case _NotificationType.connection:
        bgColor = const Color(0xFFEBF8FF);
        borderColor = Colors.blue;
        icon = Icons.wifi_rounded;
        iconColor = Colors.blue;
        break;
      case _NotificationType.disconnection:
        bgColor = const Color(0xFFFFFAF0);
        borderColor = const Color(0xFFFF8C00);
        icon = Icons.wifi_off_rounded;
        iconColor = const Color(0xFFFF8C00);
        break;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => NotificationToast(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        bgColor: bgColor,
        borderColor: borderColor,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
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
        return _buildTabNavigator(3, _buildWaterLoosesTab());
      case 4:
        return _buildTabNavigator(4, _buildSettingsTab());
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
    return BlocProvider.value(
      value: _boilersBloc,
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

  Widget _buildWaterLoosesTab() => const WaterLossesScreen();

  Widget _buildSettingsTab() => const SettingsScreen();
}
