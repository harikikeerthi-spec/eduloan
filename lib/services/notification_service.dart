import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import 'api_config.dart';
import 'push_notification_service.dart';

class NotificationService {
  static Future<String> get baseUrl async => ApiConfig.getBaseUrl();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final localRaw = prefs.getStringList('user_inapp_notifications') ?? [];

      List<NotificationModel> localNotifs = [];
      for (var str in localRaw) {
        try {
          final map = json.decode(str) as Map<String, dynamic>;
          localNotifs.add(
            NotificationModel(
              id: map['id'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
              title: map['title'] ?? 'Notification',
              body: map['message'] ?? map['body'] ?? '',
              timestamp: DateTime.tryParse(map['timestamp'] ?? map['createdAt'] ?? '') ?? DateTime.now(),
              isRead: map['isRead'] ?? false,
              type: NotificationType.communityMessage,
            ),
          );
        } catch (_) {}
      }

      if (userId == null) return localNotifs;

      final urlStr = await baseUrl;
      final response = await http.get(
        Uri.parse('$urlStr/notifications?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List list = data['data'];
          final serverNotifs = list.map((json) => NotificationModel.fromJson(json)).toList();
          
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

  /// Push dual notification for Polls, Alerts, and Staff announcements
  /// Saves to backend & local notifications for the VidyaLoan bell icon
  static Future<void> pushNotification({
    required String title,
    required String message,
    required String type, // 'POLL', 'ALERT', 'ANNOUNCEMENT'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

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

      // Trigger heads-up system push notification banner
      await PushNotificationService.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
      );

      if (userId != null) {
        final urlStr = await ApiConfig.getBaseUrl();
        await http.post(
          Uri.parse('$urlStr/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': userId,
            'title': title,
            'body': message,
            'type': type,
          }),
        );
      }
    } catch (e) {
      debugPrint('Notification push info: $e');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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

      final urlStr = await baseUrl;
      final response = await http.put(
        Uri.parse('$urlStr/notifications/$notificationId/read'),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return true;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_inapp_notifications');

      final userId = prefs.getString('userId');
      if (userId == null) return true;

      final urlStr = await baseUrl;
      final response = await http.post(
        Uri.parse('$urlStr/notifications/read-all'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return true;
    }
  }
}
