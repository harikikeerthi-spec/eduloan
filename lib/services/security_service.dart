import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bank-Grade Mobile Security Service
///
/// Features:
/// 1. `FLAG_SECURE` screen capture and recording prevention on Android.
/// 2. Privacy shielding when app is minimized / sent to recent apps tray.
class SecurityService {
  static const MethodChannel _securityChannel = MethodChannel('com.vidyaloan/security');

  /// Enable FLAG_SECURE: Prevents screenshots and screen recordings on sensitive screens.
  static Future<void> enableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await _securityChannel.invokeMethod('enableSecureScreen');
      debugPrint('[SecurityService] FLAG_SECURE enabled (Screenshots & screen recording blocked)');
    } catch (e) {
      debugPrint('[SecurityService] Error enabling FLAG_SECURE: $e');
    }
  }

  /// Disable FLAG_SECURE
  static Future<void> disableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await _securityChannel.invokeMethod('disableSecureScreen');
      debugPrint('[SecurityService] FLAG_SECURE disabled');
    } catch (e) {
      debugPrint('[SecurityService] Error disabling FLAG_SECURE: $e');
    }
  }
}
