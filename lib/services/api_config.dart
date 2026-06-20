class ApiConfig {
  static const String _baseUrl = 'https://appv1.vidyaloans.in/api';
  static String? _cachedBaseUrl;

  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    _cachedBaseUrl = _baseUrl;
    return _cachedBaseUrl!;
  }

  static String get baseUrl => _cachedBaseUrl ?? _baseUrl;
  static String get authBaseUrl => '${_cachedBaseUrl ?? _baseUrl}/auth';
  static String get aiBaseUrl => '${_cachedBaseUrl ?? _baseUrl}/ai';
  static String get onboardingBaseUrl =>
      '${_cachedBaseUrl ?? _baseUrl}/onboarding';
  static String get communityBaseUrl =>
      '${_cachedBaseUrl ?? _baseUrl}/community';
  static String get blogBaseUrl => '${_cachedBaseUrl ?? _baseUrl}/blog';
  static String get userBaseUrl => '${_cachedBaseUrl ?? _baseUrl}/users';
}
