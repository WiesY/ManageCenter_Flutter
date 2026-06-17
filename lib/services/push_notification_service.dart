import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manage_center/main.dart';

const AndroidNotificationChannel _kAlarmChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Аварийные уведомления',
  description: 'Важные оповещения SCADA системы',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

NotificationDetails _alarmNotificationDetails({
  Color color = const Color(0xFFE53E3E),
  bool fullScreenIntent = true,
}) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      _kAlarmChannel.id,
      _kAlarmChannel.name,
      channelDescription: _kAlarmChannel.description,
      icon: '@android:drawable/ic_dialog_alert',
      color: color,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: fullScreenIntent,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}

/// Стабильный id уведомления, чтобы дубли (FCM + SignalR) схлопывались в одно.
int _notificationId(Map<String, dynamic> data) {
  final raw =
      data['alarmId'] ?? data['id'] ?? data['incidentId'] ?? data['boilerId'];
  final parsed = int.tryParse('${raw ?? ''}');
  if (parsed != null) return parsed;
  return DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showBackgroundNotification(message);
}

/// Показ уведомления из фонового изолята (приложение в фоне или закрыто).
/// Сервер шлёт data-only сообщения, поэтому система Android сама ничего
/// не рисует — показываем локальное уведомление вручную.
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@android:drawable/ic_dialog_alert');
    const DarwinInitializationSettings darwinInit =
        DarwinInitializationSettings();

    await plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_kAlarmChannel);

    final data = message.data;
    final notification = message.notification;

    final bool resolved = '${data['type'] ?? ''}' == 'resolved' ||
        data['hasActiveAlarms'] != null && data['description'] == null;

    final String title =
        notification?.title ?? data['title'] ?? data['boilerName'] ?? 'Авария';
    final String body = notification?.body ??
        data['body'] ??
        data['description'] ??
        (resolved ? 'Авария устранена' : '');

    await plugin.show(
      id: _notificationId(data),
      title: title,
      body: body,
      notificationDetails: _alarmNotificationDetails(
        color: resolved ? const Color(0xFF38A169) : const Color(0xFFE53E3E),
        fullScreenIntent: !resolved,
      ),
      payload: jsonEncode(data),
    );
  } catch (e) {
    print("❌ [PushService BG] $e");
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  late final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await Firebase.initializeApp();

      _fcm = FirebaseMessaging.instance;

      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
          "🔔 [PushService] Разрешение: ${settings.authorizationStatus}");

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _fcm.getAPNSToken();
        debugPrint("🍎 [PushService] APNs token: ${apnsToken ?? "NULL"}");
      }

      String? token = await _fcm.getToken();
      debugPrint("==================== FCM TOKEN ====================");
      debugPrint(token ?? "NULL");
      debugPrint("===================================================");

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@android:drawable/ic_dialog_alert');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            _handleNavigation(jsonDecode(response.payload!));
          }
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_kAlarmChannel);

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            "📩 [PushService] onMessage: data=${message.data} notif=${message.notification?.title}");
        if (Platform.isAndroid) {
          _showLocalNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNavigation(message.data);
      });

      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNavigation(initialMessage.data);
      }

      _isInitialized = true;
    } catch (e) {
      print("❌ [PushService] FATAL ERROR: $e");
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;

    final String title = notification?.title ??
        message.data['title'] ??
        message.data['boilerName'] ??
        'Уведомление';
    final String body = notification?.body ??
        message.data['body'] ??
        message.data['description'] ??
        '';

    _localNotifications.show(
      id: _notificationId(message.data),
      title: title,
      body: body,
      notificationDetails: _alarmNotificationDetails(
        color: const Color(0xFFFF5722),
      ),
      payload: jsonEncode(message.data),
    );

    //print("📱 [LOCAL] Уведомление показано: $title");
  }

  void _handleNavigation(Map<String, dynamic> data) {
    //print("➡️ Переключаемся на журнал аварий");
    switchTabNotifier.value = 2;
  }

  Future<void> showAlarmNotification({
    required String boilerName,
    required String description,
    int? alarmId,
  }) async {
    _localNotifications.show(
      id: _notificationId({'alarmId': alarmId, 'boilerName': boilerName}),
      title: boilerName,
      body: description,
      notificationDetails: _alarmNotificationDetails(
        color: const Color(0xFFE53E3E),
      ),
      payload: jsonEncode({
        'type': 'alarm',
        'boilerName': boilerName,
        if (alarmId != null) 'alarmId': alarmId,
      }),
    );
  }

  Future<void> showResolvedNotification({
    required String boilerName,
    required String parameterName,
    int? alarmId,
  }) async {
    _localNotifications.show(
      id: _notificationId({'alarmId': alarmId, 'boilerName': boilerName}),
      title: boilerName,
      body: parameterName.isNotEmpty
          ? '$parameterName — авария устранена'
          : 'Авария устранена',
      notificationDetails: _alarmNotificationDetails(
        color: const Color(0xFF38A169),
        fullScreenIntent: false,
      ),
      payload: jsonEncode({
        'type': 'resolved',
        'boilerName': boilerName,
        if (alarmId != null) 'alarmId': alarmId,
      }),
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      if (!_isInitialized) await initialize();
      await _fcm.subscribeToTopic(topic);
    } catch (e) {
      print("❌ [SUBSCRIBE ERROR] $e");
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (!_isInitialized) await initialize();
      await _fcm.unsubscribeFromTopic(topic);
      print("⛔ [UNSUBSCRIBE] Отписан от: $topic");
    } catch (e) {
      print("❌ [UNSUBSCRIBE ERROR] $e");
    }
  }
}
