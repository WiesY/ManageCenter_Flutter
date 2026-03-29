import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manage_center/main.dart';
import 'package:manage_center/screens/incidents_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  late final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'high_importance_channel',
    'Аварийные уведомления',
    description: 'Важные оповещения SCADA системы',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

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

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await _fcm.getToken();

      //String? apnsToken = await _fcm.getAPNSToken();
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   final ctx = navigatorKey.currentContext;
      //   if (ctx != null) {
      //     showDialog(
      //       context: ctx,
      //       builder: (_) => AlertDialog(
      //         title: const Text('Push Debug'),
      //         content: SelectableText(
      //           'FCM: ${token ?? "NULL"}\n\nAPNs: ${apnsToken ?? "NULL"}',
      //         ),
      //         actions: [
      //           TextButton(
      //             onPressed: () => Navigator.pop(ctx),
      //             child: const Text('OK'),
      //           ),
      //         ],
      //       ),
      //     );
      //   }
      // });

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
          ?.createNotificationChannel(_androidChannel);

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // print(
        //     "🔔 [FOREGROUND] Пришло сообщение: ${message.notification?.title}");
        if (Platform.isAndroid) _showLocalNotification(message);
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

    final String title =
        notification?.title ?? message.data['title'] ?? 'Уведомление';
    final String body = notification?.body ?? message.data['body'] ?? '';

    _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@android:drawable/ic_dialog_alert',
          color: const Color(0xFFFF5722),
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    //print("📱 [LOCAL] Уведомление показано: $title");
  }

  void _handleNavigation(Map<String, dynamic> data) {
    //print("➡️ Переключаемся на журнал аварий");
    switchTabNotifier.value = 2;
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
