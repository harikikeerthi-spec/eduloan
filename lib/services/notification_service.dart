import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import 'api_config.dart';
import 'push_notification_service.dart';
import 'secure_storage_service.dart';

class NotificationService {
  static Future<String> get baseUrl async => ApiConfig.getBaseUrl();

  /// Common headers with securely stored access token.
  static Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorageService.getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // User ID is not an authentication secret, so it can remain in
      // SharedPreferences. The access token comes from SecureStorage.
      final userId = prefs.getString('userId');

      final localRaw = prefs.getStringList('user_inapp_notifications') ?? [];

      final List<NotificationModel> localNotifs = [];

      for (var str in localRaw) {
        try {
          final map = json.decode(str) as Map<String, dynamic>;

          localNotifs.add(
            NotificationModel(
              id: map['id'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
              title: map['title'] ?? 'Notification',
              body: map['message'] ?? map['body'] ?? '',
              timestamp:
                  DateTime.tryParse(
                    map['timestamp'] ?? map['createdAt'] ?? '',
                  ) ??
                  DateTime.now(),
              isRead: map['isRead'] ?? false,
              type: NotificationType.communityMessage,
            ),
          );
        } catch (_) {}
      }

      if (userId == null || userId.isEmpty) {
        return localNotifs;
      }

      final urlStr = await baseUrl;

      final response = await http
          .get(
            Uri.parse('$urlStr/notifications?userId=$userId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List list = data['data'] ?? [];

          final serverNotifs = list
              .map(
                (json) =>
                    NotificationModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          final map = <String, NotificationModel>{};

          for (var n in localNotifs) {
            map[n.id] = n;
          }

          for (var n in serverNotifs) {
            map[n.id] = n;
          }

          final combined = map.values.toList();

          combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return combined;
        }
      }

      return localNotifs;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Push dual notification for Polls, Alerts, and Staff announcements.
  ///
  /// Saves the notification locally, displays a heads-up notification,
  /// and sends it to the backend using the securely stored access token.
  static Future<void> pushNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString('userId');

      // Save locally for the VidyaLoan notification bell.
      final key = 'user_inapp_notifications';
      final currentRaw = prefs.getStringList(key) ?? [];

      final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';

      final newNotif = {
        'id': notifId,
        'title': title,
        'message': message,
        'body': message,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      };

      currentRaw.insert(0, json.encode(newNotif));

      await prefs.setStringList(key, currentRaw);

      // Trigger heads-up system push notification banner.
      await PushNotificationService.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
      );

      // Send notification to backend.
      if (userId != null && userId.isNotEmpty) {
        final urlStr = await ApiConfig.getBaseUrl();

        final response = await http
            .post(
              Uri.parse('$urlStr/notifications'),
              headers: await _getHeaders(),
              body: json.encode({
                'userId': userId,
                'title': title,
                'body': message,
                'type': type,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            '[NotificationService] Backend notification failed: '
            '${response.statusCode}',
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Notification push error: $e');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update local notification state.
      final localRaw = prefs.getStringList('user_inapp_notifications') ?? [];

      final updatedRaw = <String>[];

      for (var str in localRaw) {
        try {
          final map = json.decode(str) as Map<String, dynamic>;

          if (map['id'] == notificationId) {
            map['isRead'] = true;
          }

          updatedRaw.add(json.encode(map));
        } catch (_) {
          updatedRaw.add(str);
        }
      }

      await prefs.setStringList('user_inapp_notifications', updatedRaw);

      // Update backend using secure authentication.
      final urlStr = await baseUrl;

      final response = await http
          .put(
            Uri.parse('$urlStr/notifications/$notificationId/read'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
        '[NotificationService] Error marking notification as read: $e',
      );
      return true;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear local unread/read notification cache.
      await prefs.remove('user_inapp_notifications');

      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        return true;
      }

      final urlStr = await baseUrl;

      final response = await http
          .post(
            Uri.parse('$urlStr/notifications/read-all'),
            headers: await _getHeaders(),
            body: json.encode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '[NotificationService] Mark all as read failed: '
          '${response.statusCode}',
        );
        return false;
      }

      final data = json.decode(response.body);

      return data['success'] == true;
    } catch (e) {
      debugPrint(
        '[NotificationService] Error marking all notifications as read: $e',
      );
      return true;
    }
  }
}
