import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'secure_storage_service.dart';

class AuthService {
  static dynamic _parseJsonResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return {
        'success': false,
        'message': 'Empty response from server (${response.statusCode})',
      };
    }
    if (body.startsWith('<') ||
        body.startsWith('Internal Server Error') ||
        body.startsWith('Bad Gateway')) {
      return {
        'success': false,
        'message':
            'Server is updating (${response.statusCode}). Please try again in a few seconds.',
      };
    }
    try {
      return jsonDecode(body);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Invalid response format (${response.statusCode}). Please try again.',
      };
    }
  }

  static const List<String> _reviewerEmails = [
    'demo@vidyaloans.in',
    'testuser@vidyaloans.app',
    'googleplay@vidyaloans.app',
    'reviewer@vidyaloans.in',
    'test@vidyaloans.in',
    'demo@vidyaloans.app',
  ];

  static const List<String> _reviewerOtps = ['123456', '000000', '999999'];

  static bool isReviewerEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final clean = email.trim().toLowerCase();
    return _reviewerEmails.contains(clean) ||
        clean.startsWith('testuser@') ||
        clean.contains('reviewer');
  }

  static bool isReviewerOtp(String? otp) {
    if (otp == null || otp.trim().isEmpty) return false;
    return _reviewerOtps.contains(otp.trim());
  }

  /// Sends a Unified OTP (handles both login and signup)
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    // Fast-path for Google Play Reviewer test accounts
    if (isReviewerEmail(cleanEmail)) {
      try {
        final baseUrl = await ApiConfig.getBaseUrl();
        await http
            .post(
              Uri.parse('$baseUrl/auth/send-otp'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      return {
        'success': true,
        'message': 'OTP sent successfully (Reviewer: use 123456)',
        'userExists': true,
      };
    }

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _parseJsonResponse(response);
      if (data is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Unexpected server response'};
      }

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'userExists': data['userExists'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    }
  }

  /// Verifies the OTP (Unified Flow)
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();

    // Check reviewer test account bypass first
    if (isReviewerEmail(cleanEmail) && isReviewerOtp(cleanOtp)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('latest_ai_recommendations');
      await prefs.remove('user_profileImage');
      await prefs.setString('user_email', cleanEmail);
      await prefs.setBool('has_registered', true);
      await prefs.setString('auth_token', 'demo_jwt_reviewer_token_vidyaloan');
      await prefs.setString('refresh_token', 'demo_jwt_reviewer_refresh_vidyaloan');
      await prefs.setString('userId', 'demo_reviewer_user_999');
      await prefs.setString('user_firstName', 'Demo');
      await prefs.setString('user_lastName', 'User');
      await prefs.setString('user_phone', '9876543210');
      await prefs.setString('user_dob', '1995-01-01');

      await SecureStorageService.saveToken('demo_jwt_reviewer_token_vidyaloan');
      await SecureStorageService.saveRefreshToken('demo_jwt_reviewer_refresh_vidyaloan');
      await SecureStorageService.saveUserId('demo_reviewer_user_999');

      // Attempt to notify backend in background if available
      try {
        final baseUrl = await ApiConfig.getBaseUrl();
        await http
            .post(
              Uri.parse('$baseUrl/auth/verify-otp'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email, 'otp': otp}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}

      return {
        'success': true,
        'userExists': true,
        'hasUserDetails': true,
        'message': 'OTP verified successfully',
      };
    }

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _parseJsonResponse(response);
      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': data is Map && data['message'] != null
              ? data['message']
              : 'Unexpected server response',
        };
      }

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final token = data['access_token'];
        final refreshToken = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('latest_ai_recommendations');
        await prefs.remove('user_profileImage');
        await prefs.setString('user_email', email);
        await prefs.setBool('has_registered', true);
        if (token != null) {
          await prefs.setString('auth_token', token);
          await SecureStorageService.saveToken(token);
        }
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
          await SecureStorageService.saveRefreshToken(refreshToken);
        }
        if (data['userId'] != null) {
          await prefs.setString('userId', data['userId']);
          await SecureStorageService.saveUserId(data['userId']);
        }

        if (data['firstName'] != null) {
          await prefs.setString('user_firstName', data['firstName']);
        }
        if (data['lastName'] != null) {
          await prefs.setString('user_lastName', data['lastName']);
        }
        if (data['phoneNumber'] != null) {
          await prefs.setString('user_phone', data['phoneNumber']);
        }

        return {
          'success': true,
          'userExists': data['userExists'] ?? false,
          'hasUserDetails': data['hasUserDetails'] ?? false,
          'message': data['message'] ?? 'OTP verified successfully',
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Logs in with Google (via Firebase ID Token)
  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    required String email,
  }) async {
    return loginWithFirebaseToken(idToken: idToken, email: email);
  }

  /// Authenticates using Firebase ID token
  static Future<Map<String, dynamic>> loginWithFirebaseToken({
    required String idToken,
    required String email,
  }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/firebase'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _parseJsonResponse(response);
      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': data is Map && data['message'] != null
              ? data['message']
              : 'Unexpected server response',
        };
      }

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final token = data['access_token'];
        final refreshToken = data['refresh_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('latest_ai_recommendations');
        await prefs.remove('user_profileImage');
        await prefs.setString('user_email', email);
        await prefs.setBool('has_registered', true);
        if (token != null) {
          await prefs.setString('auth_token', token);
          await SecureStorageService.saveToken(token);
        }
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
          await SecureStorageService.saveRefreshToken(refreshToken);
        }
        if (data['userId'] != null) {
          await prefs.setString('userId', data['userId']);
          await SecureStorageService.saveUserId(data['userId']);
        }

        if (data['firstName'] != null) {
          await prefs.setString('user_firstName', data['firstName']);
        }
        if (data['lastName'] != null) {
          await prefs.setString('user_lastName', data['lastName']);
        }
        if (data['phoneNumber'] != null) {
          await prefs.setString('user_phone', data['phoneNumber']);
        }

        return {
          'success': true,
          'userExists': data['userExists'] ?? false,
          'hasUserDetails': data['hasUserDetails'] ?? false,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Google login failed on server',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Refresh the access token using the securely stored refresh token.
  static Future<bool> refreshToken() async {
    try {
      // IMPORTANT:
      // Read refresh token from secure storage, NOT SharedPreferences.
      final refreshToken = await SecureStorageService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[AuthService] No refresh token available');
        return false;
      }

      final baseUrl = await ApiConfig.getBaseUrl();

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _parseJsonResponse(response);

      if (data is! Map<String, dynamic>) {
        debugPrint('[AuthService] Invalid refresh response');
        return false;
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        if (newAccessToken == null || newAccessToken.toString().isEmpty) {
          debugPrint('[AuthService] Refresh response has no access token');
          return false;
        }

        // Save new access token securely.
        await SecureStorageService.saveToken(newAccessToken.toString());

        // Backend rotates the refresh token — save the new one securely.
        if (newRefreshToken != null && newRefreshToken.toString().isNotEmpty) {
          await SecureStorageService.saveRefreshToken(
            newRefreshToken.toString(),
          );
        }

        debugPrint('[AuthService] Access token refreshed successfully');
        return true;
      }

      // Refresh token is invalid/expired.
      if (response.statusCode == 401) {
        debugPrint('[AuthService] Refresh token expired or invalid');
        await SecureStorageService.delete('auth_token');
        await SecureStorageService.delete('refresh_token');
        return false;
      }

      debugPrint('[AuthService] Token refresh failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('[AuthService] Error refreshing token: $e');
      return false;
    }
  }

  /// Updates user details (Complete Registration / Profile Update)
  static Future<Map<String, dynamic>> updateUserDetails(
    String email,
    String firstName,
    String lastName,
    String phoneNumber,
    String dateOfBirth, {
    String? profileImage,
  }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final String normalizedDob = dateOfBirth.replaceAll('/', '-');
      final bodyMap = <String, dynamic>{
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': normalizedDob,
      };
      if (profileImage != null) {
        bodyMap['profileImage'] = profileImage;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/update-details'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 30));

      final data = _parseJsonResponse(response);
      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': data is Map && data['message'] != null
              ? data['message']
              : 'Unexpected server response',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_firstName', firstName);
        await prefs.setString('user_lastName', lastName);
        await prefs.setString('user_name', '$firstName $lastName'.trim());
        await prefs.setString('user_phone', phoneNumber);
        await prefs.setString('user_dob', dateOfBirth);
        if (profileImage != null) {
          await prefs.setString('user_profileImage', profileImage);
        }
        if (data['user'] != null && data['user']['userId'] != null) {
          await prefs.setString('userId', data['user']['userId']);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Fetches user dashboard data (Profile)
  static Future<Map<String, dynamic>> getUserDashboard(String email) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/auth/dashboard'),
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));

      final data = _parseJsonResponse(response);
      if (data is! Map<String, dynamic>) {
        if (isReviewerEmail(email)) {
          final mock = {
            'email': email,
            'firstName': 'Demo',
            'lastName': 'User',
            'phoneNumber': '9876543210',
            'dateOfBirth': '1995-01-01',
            'userId': 'demo_reviewer_user_999',
            'userType': 'student',
          };
          return {'success': true, 'user': mock, 'data': mock};
        }
        return {
          'success': false,
          'message': data is Map && data['message'] != null
              ? data['message']
              : 'Unexpected server response',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'user': data, 'data': data};
      } else {
        if (isReviewerEmail(email)) {
          final mock = {
            'email': email,
            'firstName': 'Demo',
            'lastName': 'User',
            'phoneNumber': '9876543210',
            'dateOfBirth': '1995-01-01',
            'userId': 'demo_reviewer_user_999',
            'userType': 'student',
          };
          return {'success': true, 'user': mock, 'data': mock};
        }
        return {'success': false, 'message': 'Failed to fetch dashboard data'};
      }
    } catch (e) {
      if (isReviewerEmail(email)) {
        final mock = {
          'email': email,
          'firstName': 'Demo',
          'lastName': 'User',
          'phoneNumber': '9876543210',
          'dateOfBirth': '1995-01-01',
          'userId': 'demo_reviewer_user_999',
          'userType': 'student',
        };
        return {'success': true, 'user': mock, 'data': mock};
      }
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Deletes the current user account
  static Future<Map<String, dynamic>> deleteAccount(String email) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = await SecureStorageService.getToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/users/delete-self'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final data = _parseJsonResponse(response);
      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': data is Map && data['message'] != null
              ? data['message']
              : 'Unexpected server response',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Account deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete account',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }
}
