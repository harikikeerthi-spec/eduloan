import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hardware-Backed Keystore & Keychain Secure Storage Service
///
/// Encrypts sensitive authentication credentials (JWT access tokens, refresh tokens)
/// using AES-256 keys managed by the Android Keystore System (hardware TEE/StrongBox)
/// and iOS Keychain.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'userId';

  /// Save JWT Access Token to Hardware-backed Keystore
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _keyAuthToken, value: token);
    } catch (e) {
      debugPrint('[SecureStorage] Error writing auth token: $e');
    }
  }

  /// Retrieve JWT Access Token from Keystore (with fallback to SharedPreferences)
  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _keyAuthToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('[SecureStorage] Error reading auth token: $e');
    }
    // Fallback migration check from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_keyAuthToken);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      // Migrate to secure storage silently
      await saveToken(legacyToken);
      return legacyToken;
    }
    return null;
  }

  /// Save Refresh Token to Hardware-backed Keystore
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (e) {
      debugPrint('[SecureStorage] Error writing refresh token: $e');
    }
  }

  /// Retrieve Refresh Token
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _storage.read(key: _keyRefreshToken);

      if (token != null && token.isNotEmpty) {
        return token;
      }
    } catch (e) {
      debugPrint('[SecureStorage] Error reading refresh token: $e');
    }

    return null;
  }

  /// Save User ID
  static Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _keyUserId, value: userId);
    } catch (e) {
      debugPrint('[SecureStorage] Error writing userId: $e');
    }
  }

  /// Retrieve User ID
  static Future<String?> getUserId() async {
    try {
      final id = await _storage.read(key: _keyUserId);
      if (id != null && id.isNotEmpty) return id;
    } catch (e) {
      debugPrint('[SecureStorage] Error reading userId: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Generic write
  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[SecureStorage] Error writing key $key: $e');
    }
  }

  /// Generic read
  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] Error reading key $key: $e');
      return null;
    }
  }

  /// Delete a key
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] Error deleting key $key: $e');
    }
  }

  /// Clear all secure storage upon Logout / Account Deletion
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[SecureStorage] Error clearing storage: $e');
    }
  }
}
