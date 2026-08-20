import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'secure_storage_service.dart';

class TokenRefreshService {
  static bool _isRefreshing = false;
  static Future<bool>? _refreshFuture;

  /// Refresh the access token using the secure refresh token.
  ///
  /// Prevents multiple API requests from simultaneously refreshing
  /// the token when several requests receive 401 at the same time.
  static Future<bool> refresh() {
    if (_isRefreshing && _refreshFuture != null) {
      return _refreshFuture!;
    }

    _isRefreshing = true;

    final future = _performRefresh();

    _refreshFuture = future;

    future.whenComplete(() {
      _isRefreshing = false;
      _refreshFuture = null;
    });

    return future;
  }

  static Future<bool> _performRefresh() async {
    try {
      // IMPORTANT:
      // Refresh token must come from secure storage.
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[TokenRefresh] No refresh token available');
        return false;
      }

      final baseUrl = await ApiConfig.getBaseUrl();

      debugPrint('[TokenRefresh] Requesting new access token');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint('[TokenRefresh] Refresh failed: ${response.statusCode}');

        if (response.statusCode == 401) {
          await _clearTokens();
        }

        return false;
      }

      final body = response.body.trim();

      if (body.isEmpty) {
        debugPrint('[TokenRefresh] Empty response');
        return false;
      }

      final data = jsonDecode(body);

      if (data is! Map<String, dynamic> || data['success'] != true) {
        debugPrint('[TokenRefresh] Invalid refresh response');
        return false;
      }

      final newAccessToken = data['access_token'];
      final newRefreshToken = data['refresh_token'];

      if (newAccessToken == null || newAccessToken.toString().isEmpty) {
        debugPrint('[TokenRefresh] No new access token received');
        return false;
      }

      // Save the new access token securely.
      await SecureStorageService.saveToken(newAccessToken.toString());

      // Your backend rotates refresh tokens.
      // Therefore save the new refresh token too.
      if (newRefreshToken != null && newRefreshToken.toString().isNotEmpty) {
        await SecureStorageService.saveRefreshToken(newRefreshToken.toString());
      }

      debugPrint('[TokenRefresh] Token refreshed successfully');

      return true;
    } catch (e) {
      debugPrint('[TokenRefresh] Error: $e');
      return false;
    }
  }

  static Future<void> _clearTokens() async {
    await SecureStorageService.delete('auth_token');
    await SecureStorageService.delete('refresh_token');

    debugPrint('[TokenRefresh] Tokens cleared');
  }
}
