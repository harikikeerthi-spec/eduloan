import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const List<String> _baseUrls = [
    'http://10.0.2.2:3000', // standard Android emulator
    'http://10.94.206.91:3000', // user's current local IP
    'http://192.168.55.101:3000', // user's previous local IP
    'http://localhost:3000', // adb reverse or web
  ];

  static String? _cachedBaseUrl;

  /// Returns the most reliable base URL by checking connectivity
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    for (String url in _baseUrls) {
      try {
        final response = await http
            .get(Uri.parse('$url/auth/check-user/test'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 404 && response.statusCode != 500) {
          debugPrint('[ApiConfig] Discovered working backend: $url');
          _cachedBaseUrl = url;
          return url;
        }
      } catch (e) {
        debugPrint('[ApiConfig] URL $url unreachable: $e');
      }
    }

    debugPrint(
      '[ApiConfig] No local backend discovered, falling back to emulator IP',
    );
    _cachedBaseUrl = _baseUrls[0];
    return _baseUrls[0];
  }

  static String get authBaseUrl => '${_cachedBaseUrl ?? _baseUrls[0]}/auth';
  static String get aiBaseUrl => '${_cachedBaseUrl ?? _baseUrls[0]}/ai';
  static String get onboardingBaseUrl =>
      '${_cachedBaseUrl ?? _baseUrls[0]}/onboarding';
  static String get communityBaseUrl =>
      '${_cachedBaseUrl ?? _baseUrls[0]}/community';
  static String get blogBaseUrl => '${_cachedBaseUrl ?? _baseUrls[0]}/blog';
  static String get userBaseUrl => '${_cachedBaseUrl ?? _baseUrls[0]}/users';
}
