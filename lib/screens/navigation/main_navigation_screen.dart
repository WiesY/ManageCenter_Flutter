import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manage_center/bloc/boilers_bloc.dart';
import 'package:manage_center/bloc/incidents_bloc.dart';
import 'package:manage_center/main.dart';
import 'package:manage_center/screens/analitics_screen.dart';
import 'package:manage_center/screens/dashboard_screen.dart';
import 'package:manage_center/screens/incidents_screen.dart';
import 'package:manage_center/screens/settings/settings_menu_screen.dart';
import 'package:manage_center/screens/water_losses_screen.dart';
import 'package:manage_center/services/signalr_service.dart';
import 'package:manage_center/services/storage_service.dart';
import 'package:manage_center/theme/app_theme.dart';
import 'package:manage_center/utils/app_logger.dart';
import 'package:manage_center/widgets/custom_bottom_navigation.dart';
import 'package:manage_center/services/app_update_service.dart';
import 'package:manage_center/widgets/notification_toast.dart';
import 'package:manage_center/widgets/update_dialog.dart';
import 'package:audioplayers/audioplayers.dart';

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

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  /// Вкладки, которые уже открывали. Остальные не строим, чтобы на старте
  /// не грузить аналитику и настройки, которые могут и не понадобиться.
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Блоки сессии создаются в main.dart — здесь те же экземпляры, что видят
    // экраны во вкладках, иначе события SignalR уходили бы мимо них.
    _boilersBloc = context.read<BoilersBloc>();
    _incidentsBloc = context.read<IncidentsBloc>();

    switchTabNotifier.addListener(_onSwitchTab);

    if (switchTabNotifier.value != null) {
      _currentIndex = switchTabNotifier.value!;
      _visitedTabs.add(_currentIndex);
      switchTabNotifier.value = null;
    }
    _initSignalR();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await AppUpdateService().checkForUpdate();
      if (info != null && mounted) {
        UpdateDialog.show(context, info);
      }
    });
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
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onSwitchTab() {
    final tabIndex = switchTabNotifier.value;
    if (tabIndex != null) {
      _selectTab(tabIndex);
      switchTabNotifier.value = null;
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      _selectTab(index);
    }
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  /// Системная «Назад»: сначала закрываем экраны внутри вкладки, потом
  /// возвращаемся на главную и только с неё выходим из приложения.
  void _onBackPressed() {
    final tabNavigator = _navigatorKeys[_currentIndex].currentState;
    if (tabNavigator != null && tabNavigator.canPop()) {
      tabNavigator.pop();
    } else if (_currentIndex != 0) {
      _selectTab(0);
    } else {
      SystemNavigator.pop();
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
    final storage = context.read<StorageService>();
    final token = await storage.getToken();
    if (token != null) {
      // 1. Параметры котельных
      _signalRService.onNewBoilerParametersData = (boilerId, newData) {
        if (!mounted || _boilersBloc.isClosed) return;
        //logDebug('Котельная $boilerId: $newData', name: 'signalr');
        _boilersBloc.add(BoilerParametersUpdatedEvent(boilerId, newData));
      };

      // 2. Новая авария
      _signalRService.onNewAlarm = (alarmData) {
        logDebug('Новая авария в UI: $alarmData', name: 'signalr');
        _incidentsBloc.add(IncidentsNewAlarmReceivedEvent(alarmData));

        final boilerId = _asInt(alarmData['boilerId']);
        logDebug('onNewAlarm parsed boilerId=$boilerId', name: 'signalr');
        if (boilerId != null) {
          _boilersBloc.add(BoilerEmergencyStatusChangedEvent(boilerId, true));
        }

        final boilerName = alarmData['boilerName']?.toString() ?? 'Объект';
        final description = alarmData['description']?.toString() ?? 'Авария';

        // На переднем плане показываем in-app тост.
        // В фоне/закрытом приложении уведомление покажет FCM (фоновый
        // обработчик), поэтому здесь дублировать не нужно.
        final state = WidgetsBinding.instance.lifecycleState;
        if (state == AppLifecycleState.resumed) {
          _showNotification(
            title: boilerName,
            message: description,
            type: _NotificationType.alarm,
          );
        }
      };

      // 3. Изменение статуса связи
      _signalRService.onDeviceStatusChanged = (statusData) {
        logDebug('Статус изменился в UI: $statusData', name: 'signalr');

        final boilerId = _asInt(statusData['boilerId']);
        final status = statusData['status']?.toString().toLowerCase() ?? '';
        final hasConnection = status != 'offline';
        logDebug('onDeviceStatusChanged boilerId=$boilerId hasConnection=$hasConnection', name: 'signalr');

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
        logDebug('Авария закрыта в UI: $resolvedData', name: 'signalr');
        _incidentsBloc.add(IncidentsAlarmResolvedEvent(resolvedData));

        final boilerId = _asInt(resolvedData['boilerId']);
        final hasActiveAlarms = resolvedData['hasActiveAlarms'] == true;
        logDebug('onAlarmResolved boilerId=$boilerId hasActiveAlarms=$hasActiveAlarms', name: 'signalr');

        if (boilerId != null) {
          _boilersBloc.add(
            BoilerEmergencyStatusChangedEvent(boilerId, hasActiveAlarms),
          );
        }

        final boilerName = resolvedData['boilerName']?.toString() ?? 'Объект';
        final paramName = resolvedData['parameterName']?.toString() ?? '';

        // На переднем плане — in-app тост; в фоне/закрытом приложении
        // уведомление доставит FCM.
        final state = WidgetsBinding.instance.lifecycleState;
        if (state == AppLifecycleState.resumed) {
          _showNotification(
            title: boilerName,
            message: paramName.isNotEmpty
                ? '$paramName — авария устранена'
                : 'Авария устранена',
            type: _NotificationType.resolved,
          );
        }
      };

      await _signalRService.connect(storage.getToken);
    }
  }

  Future<void> _showNotification({
    required String title,
    required String message,
    required _NotificationType type,
  }) async {
    if (!mounted) return;

    // 🔊 Звук только для аварий и только если он не выключен в настройках
    if (type == _NotificationType.alarm) {
      final storage = context.read<StorageService>();
      if (await storage.isAlarmSoundEnabled()) {
        final volume = await storage.getAlarmVolume();
        final sound = await storage.getAlarmSound();
        await _audioPlayer.setVolume(volume);
        await _audioPlayer.play(AssetSource(sound));
      }
    }

    if (!mounted) return;

    final colors = context.colors;
    final appColors = context.appColors;

    final Color bgColor;
    final Color borderColor;
    final IconData icon;
    final Color iconColor;

    switch (type) {
      case _NotificationType.alarm:
        bgColor = colors.errorContainer;
        borderColor = colors.error;
        icon = Icons.warning_rounded;
        iconColor = colors.error;
        break;
      case _NotificationType.resolved:
        bgColor = appColors.successContainer;
        borderColor = appColors.success;
        icon = Icons.check_circle_rounded;
        iconColor = appColors.success;
        break;
      case _NotificationType.connection:
        bgColor = appColors.infoContainer;
        borderColor = appColors.info;
        icon = Icons.wifi_rounded;
        iconColor = appColors.info;
        break;
      case _NotificationType.disconnection:
        bgColor = appColors.warningContainer;
        borderColor = appColors.warning;
        icon = Icons.wifi_off_rounded;
        iconColor = appColors.warning;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        extendBody: true,
        // Все открытые вкладки остаются в дереве: при переключении не теряются
        // ни прокрутка, ни открытые внутри вкладки экраны.
        body: IndexedStack(
          index: _currentIndex,
          children: [
            for (var i = 0; i < _navigatorKeys.length; i++)
              _visitedTabs.contains(i)
                  ? TickerMode(
                      enabled: i == _currentIndex,
                      child: _buildTabNavigator(i, _buildTab(i)),
                    )
                  : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: BlocBuilder<IncidentsBloc, IncidentsState>(
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

  Widget _buildTab(int index) {
    switch (index) {
      case 1:
        return const AnalyticsScreen();
      case 2:
        return const IncidentsScreen();
      case 3:
        return const WaterLossesScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
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
}
