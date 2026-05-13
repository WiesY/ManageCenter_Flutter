import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Глобальный нотифаер: уведомляет подписчиков о приходе новых данных
/// параметров котельной. Значение = boilerId, по которому пришли новые данные.
/// После эмита сбрасывается в null, чтобы повторное событие по тому же boilerId
/// снова триггерило слушателей.
final ValueNotifier<int?> boilerParamsUpdateNotifier = ValueNotifier<int?>(null);

class SignalRService {
  static const String _hubUrl = 'https://boiler-v2.nwwork.site/notifications';

  HubConnection? _hubConnection;

  Function(int boilerId, Map<String, dynamic> newData)? onNewBoilerParametersData;
  Function(Map<String, dynamic> alarmData)? onNewAlarm;
  Function(Map<String, dynamic> statusData)? onDeviceStatusChanged;
  Function(Map<String, dynamic> resolvedData)? onAlarmResolved;

  Future<void> connect(String token) async {
    print('[SignalR] Попытка подключения с токеном: ${token.substring(0, 20)}...');

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            // НЕ указываем transport и skipNegotiation — пусть клиент договорится с сервером сам
          ),
        )
        .withAutomaticReconnect()
        .build();

    // --- ВСЕ ПОДПИСКИ ДО start() ---

    _hubConnection!.on('OnNewBoilerParametersData', (args) {
      print('[SignalR RAW] OnNewBoilerParametersData: $args');
      if (args == null || args.length < 2) return;
      try {
        final boilerId = args[0] as int;
        final newData = Map<String, dynamic>.from(args[1] as Map);
        onNewBoilerParametersData?.call(boilerId, newData);

        // Широковещательно уведомляем подписчиков (BoilerDetailScreen и др.)
        boilerParamsUpdateNotifier.value = boilerId;
        // Сброс — чтобы следующее событие с тем же boilerId тоже сработало
        boilerParamsUpdateNotifier.value = null;
      } catch (e) {
        print('[SignalR] Ошибка OnNewBoilerParametersData: $e');
      }
    });

    _hubConnection!.on('ReceiveNewAlarm', (args) {
      print('[SignalR RAW] ReceiveNewAlarm: $args');
      if (args == null || args.isEmpty) return;
      try {
        final alarmData = Map<String, dynamic>.from(args[0] as Map);
        print('[SignalR] Получена живая авария: $alarmData');
        onNewAlarm?.call(alarmData);
      } catch (e) {
        print('[SignalR] Ошибка ReceiveNewAlarm: $e');
      }
    });

    _hubConnection!.on('DeviceStatusChanged', (args) {
      print('[SignalR RAW] DeviceStatusChanged: $args');
      if (args == null || args.isEmpty) return;
      try {
        final statusData = Map<String, dynamic>.from(args[0] as Map);
        print('[SignalR] Статус объекта изменился: $statusData');
        onDeviceStatusChanged?.call(statusData);
      } catch (e) {
        print('[SignalR] Ошибка DeviceStatusChanged: $e');
      }
    });

    _hubConnection!.on('AlarmResolved', (args) {
      print('[SignalR RAW] AlarmResolved: $args');
      if (args == null || args.isEmpty) return;
      try {
        final resolvedData = Map<String, dynamic>.from(args[0] as Map);
        print('[SignalR] Авария закрыта: $resolvedData');
        onAlarmResolved?.call(resolvedData);
      } catch (e) {
        print('[SignalR] Ошибка AlarmResolved: $e');
      }
    });

    _hubConnection!.onreconnected(({connectionId}) {
      print('[SignalR] Reconnected: $connectionId');
    });

    _hubConnection!.onclose(({error}) {
      print('[SignalR] Соединение закрыто: $error');
    });

    try {
      await _hubConnection!.start();
      print('[SignalR] Подключён к хабу. State=${_hubConnection!.state}');
    } catch (e) {
      print('[SignalR] Ошибка подключения: $e');
    }
  }

Future<void> disconnect() async {
  // 1) убрать слушателей на хабе
  try {
    _hubConnection?.off('OnNewBoilerParametersData');
    _hubConnection?.off('ReceiveNewAlarm');
    _hubConnection?.off('DeviceStatusChanged');
    _hubConnection?.off('AlarmResolved');
  } catch (_) {}

  // 2) обнулить колбэки, чтобы события в пути не достигли закрытых блоков
  onNewBoilerParametersData = null;
  onNewAlarm = null;
  onDeviceStatusChanged = null;
  onAlarmResolved = null;

  // 3) остановить соединение
  try {
    await _hubConnection?.stop();
  } catch (_) {}
  _hubConnection = null;
}

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;
}