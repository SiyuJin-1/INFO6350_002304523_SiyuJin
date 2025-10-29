// lib/notification.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('${message.notification?.title} - ${message.notification?.body}');
}

final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _fgChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for foreground FCM notifications.',
  importance: Importance.high,
);

Future<void> initLocalNotifications() async {
  const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: initAndroid);
  await _flnp.initialize(initSettings);

  await _flnp
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_fgChannel);
}

Future<String?> initFcmAndGetToken() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
  debugPrint('Notification permission: ${settings.authorizationStatus}');

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true, badge: true, sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final n = message.notification;
    final android = message.notification?.android;
    if (n != null && android != null) {
      await _flnp.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _fgChannel.id,
            _fgChannel.name,
            channelDescription: _fgChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  messaging.onTokenRefresh.listen((t) => debugPrint('Token refreshed: $t'));

  try {
    final token = await messaging.getToken();
    debugPrint('getToken() -> $token');
    return token;
  } catch (e) {
    debugPrint('Error getting token: $e');
    return null;
  }
}
