import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background push notification: ${message.messageId}');
  await PushNotificationService.saveNotificationLocally(
    title: message.notification?.title ?? message.data['title'] ?? 'VidyaLoans Notification',
    body: message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '',
    type: message.data['type'] ?? 'PUSH',
  );
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'vidyaloan_high_importance_channel',
    'VidyaLoans Notifications',
    description: 'High priority notifications for loan status updates and announcements',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize() async {
    try {
      // 1. Request Push Permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Push Notification Authorization status: ${settings.authorizationStatus}');

      // 2. Initialize Local Notifications Plugin
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Local notification tapped: ${response.payload}');
        },
      );

      // Create Android Notification Channel
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }

      // 3. Set Background Messaging Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Foreground Messaging Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Received foreground push message: ${message.notification?.title}');

        final title = message.notification?.title ?? message.data['title'] ?? 'VidyaLoan Notification';
        final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

        // Show system push notification banner
        await showLocalNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: json.encode(message.data),
        );

        // Save locally to reflect in Notification Bell
        await saveNotificationLocally(
          title: title,
          body: body,
          type: message.data['type'] ?? 'PUSH',
        );
      });

      // 5. App Opened from Background Push Listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from push notification: ${message.data}');
      });

      // 6. Fetch & Sync FCM Token
      await syncFcmToken();
    } catch (e) {
      debugPrint('PushNotificationService initialization error: $e');
    }
  }

  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'vidyaloan_high_importance_channel',
        'VidyaLoan Notifications',
        channelDescription: 'High priority notifications for loan status updates and announcements',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error displaying local notification: $e');
    }
  }

  static Future<String?> syncFcmToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Device Token: $token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> saveNotificationLocally({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'user_inapp_notifications';
      final currentRaw = prefs.getStringList(key) ?? [];
      final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
      final newNotif = {
        'id': notifId,
        'title': title,
        'message': body,
        'body': body,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      };
      currentRaw.insert(0, json.encode(newNotif));
      await prefs.setStringList(key, currentRaw);
    } catch (e) {
      debugPrint('Error saving push notification locally: $e');
    }
  }
}
