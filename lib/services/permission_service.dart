import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static bool _startupPermissionsRequested = false;

  /// Sequentially requests Notifications, Phone Call, Photos, and Location permissions.
  /// Only runs once per app execution session.
  static Future<void> checkAndRequestStartupPermissions() async {
    if (_startupPermissionsRequested) return;
    _startupPermissionsRequested = true;

    // 1. Notification
    try {
      await requestNotificationPermission();
    } catch (e) {
      debugPrint('Startup Notification Request Error: $e');
    }

    // 2. Phone Call
    try {
      await requestPhonePermission();
    } catch (e) {
      debugPrint('Startup Phone Request Error: $e');
    }

    // 3. Photos
    try {
      await requestPhotosPermission();
    } catch (e) {
      debugPrint('Startup Photos Request Error: $e');
    }
  }

  /// Checks if a specific permission is granted.
  static Future<bool> isGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Requests a specific permission and returns whether it was granted.
  static Future<bool> request(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  /// Request multiple permissions at once.
  static Future<Map<Permission, PermissionStatus>> requestMultiple(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// Check if the permission is permanently denied.
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    return await permission.isPermanentlyDenied;
  }

  /// Request Phone Calls permission.
  static Future<bool> requestPhonePermission() async {
    return await request(Permission.phone);
  }

  /// Request Photos/Storage permission depending on platform and OS version.
  static Future<bool> requestPhotosPermission() async {
    // For iOS and Android 13+ (API 33+)
    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted) return true;

    // Fallback/also request storage for older Android versions
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Request Notifications permission.
  static Future<bool> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Error requesting notifications permission via FCM: $e');
      return await request(Permission.notification);
    }
  }

  /// Shows a premium explanation dialog when a permission is permanently denied
  /// and guides the user to the system app settings to enable it.
  static Future<void> showSettingsDialog({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color themeColor,
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            description,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
