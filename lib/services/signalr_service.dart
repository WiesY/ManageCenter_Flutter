import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:manage_center/utils/app_logger.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Глобальный нотифаер: уведомляет подписчиков о приходе новых данных
/// параметров котельной. Значение = boilerId, по которому пришли новые данные.
/// После эмита сбрасывается в null, чтобы повторное событие по тому же boilerId
/// снова триггерило слушателей.
final ValueNotifier<int?> boilerParamsUpdateNotifier = ValueNotifier<int?>(null);

class SignalRService {
  static const String _hubUrl = 'https://boiler-v2.nwwork.site/notifications';

  /// Паузы между попытками поднять соединение заново. После последней
  /// пытаемся с ней же, пока сервис не остановят через [disconnect].
  static const List<Duration> _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
  ];

  HubConnection? _hubConnection;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  /// Сервис остановлен явно — переподключаться больше не нужно.
  bool _stopped = true;

  Function(int boilerId, Map<String, dynamic> newData)? onNewBoilerParametersData;
  Function(Map<String, dynamic> alarmData)? onNewAlarm;
  Function(Map<String, dynamic> statusData)? onDeviceStatusChanged;
  Function(Map<String, dynamic> resolvedData)? onAlarmResolved;

  /// Подключается к хабу. Токен запрашивается у [tokenProvider] на каждой
  /// попытке, поэтому переподключение идёт с актуальным токеном сессии.
  Future<void> connect(Future<String?> Function() tokenProvider) async {
    _stopped = false;
    _retryAttempt = 0;
    _retryTimer?.cancel();

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          _hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => await tokenProvider() ?? '',
            // НЕ указываем transport и skipNegotiation — пусть клиент договорится с сервером сам
          ),
        )
        .withAutomaticReconnect()
        .build();

    // --- ВСЕ ПОДПИСКИ ДО start() ---

    _hubConnection!.on('OnNewBoilerParametersData', (args) {
      //print('[SignalR RAW] OnNewBoilerParametersData: $args');
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
        logError('Ошибка OnNewBoilerParametersData', error: e, name: 'signalr');
      }
    });

    _hubConnection!.on('ReceiveNewAlarm', (args) {
      //print('[SignalR RAW] ReceiveNewAlarm: $args');
      if (args == null || args.isEmpty) return;
      try {
        final alarmData = Map<String, dynamic>.from(args[0] as Map);
        logDebug('Получена живая авария: $alarmData', name: 'signalr');
        onNewAlarm?.call(alarmData);
      } catch (e) {
        logError('Ошибка ReceiveNewAlarm', error: e, name: 'signalr');
      }
    });

    _hubConnection!.on('DeviceStatusChanged', (args) {
      //print('[SignalR RAW] DeviceStatusChanged: $args');
      if (args == null || args.isEmpty) return;
      try {
        final statusData = Map<String, dynamic>.from(args[0] as Map);
        logDebug('Статус объекта изменился: $statusData', name: 'signalr');
        onDeviceStatusChanged?.call(statusData);
      } catch (e) {
        logError('Ошибка DeviceStatusChanged', error: e, name: 'signalr');
      }
    });

    _hubConnection!.on('AlarmResolved', (args) {
      //print('[SignalR RAW] AlarmResolved: $args');
      if (args == null || args.isEmpty) return;
      try {
        final resolvedData = Map<String, dynamic>.from(args[0] as Map);
        logDebug('Авария закрыта: $resolvedData', name: 'signalr');
        onAlarmResolved?.call(resolvedData);
      } catch (e) {
        logError('Ошибка AlarmResolved', error: e, name: 'signalr');
      }
    });

    _hubConnection!.onreconnected(({connectionId}) {
      logDebug('Соединение восстановлено: $connectionId', name: 'signalr');
    });

    // Сюда попадаем, когда встроенное переподключение исчерпало попытки
    // (или сервер закрыл соединение). Без этого живые обновления пропадали
    // до перезапуска приложения.
    _hubConnection!.onclose(({error}) {
      logError('Соединение закрыто', error: error, name: 'signalr');
      _scheduleRetry();
    });

    await _start();
  }

  Future<void> _start() async {
    final connection = _hubConnection;
    if (_stopped || connection == null) return;
    if (connection.state != HubConnectionState.Disconnected) return;

    try {
      await connection.start();
      _retryAttempt = 0;
      logDebug('Подключён к хабу', name: 'signalr');
    } catch (e) {
      logError('Ошибка подключения', error: e, name: 'signalr');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_stopped || _retryTimer?.isActive == true) return;
    final delay =
        _retryDelays[_retryAttempt.clamp(0, _retryDelays.length - 1)];
    _retryAttempt++;
    logDebug('Повтор подключения через ${delay.inSeconds} с', name: 'signalr');
    _retryTimer = Timer(delay, _start);
  }

Future<void> disconnect() async {
  // 0) запретить переподключение — stop() вызовет onclose
  _stopped = true;
  _retryTimer?.cancel();
  _retryTimer = null;

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

  // 3) остановить соединение. Ссылку снимаем сразу: пока идёт stop(),
  // новый вход мог уже вызвать connect(), и его соединение трогать нельзя.
  final connection = _hubConnection;
  _hubConnection = null;
  try {
    await connection?.stop();
  } catch (_) {}
}

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;
}