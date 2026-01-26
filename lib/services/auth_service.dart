import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // IMPORTANT: Update this URL based on where your API is running
  // For local development:
  // - Android Emulator: 'http://10.0.2.2:3000/auth'
  // - iOS Simulator/Web: 'http://localhost:3000/auth'
  // - Real device: 'http://YOUR_COMPUTER_IP:3000/auth'
  // - Production: 'https://your-api-domain.com/auth'
  static const String baseUrl = 'http://10.0.2.2:3000/auth';

  /// Checks if a user exists with the given email
  static Future<Map<String, dynamic>> checkUserExists(String email) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/check-user/$email'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'exists': data['exists'] ?? false,
          'message': data['message'],
        };
      } else {
        return {'success': false, 'message': 'Failed to check user status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Sends an OTP to the provided email address for login
  static Future<Map<String, dynamic>> sendLoginOTP(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 180));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Sends an OTP to the provided email address for registration
  static Future<Map<String, dynamic>> sendRegisterOTP(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 180));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Verifies the OTP sent to the email for login
  static Future<Map<String, dynamic>> verifyLoginOTP(
    String email,
    String otp,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 180));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Save initial data to SharedPreferences for local profile usage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        if (data['username'] != null) {
          await prefs.setString('profile_name_$email', data['username']);
        }

        return {
          'success': true,
          'token': data['access_token'],
          'username': data['username'],
          'hasUserDetails':
              data['hasUserDetails'] ??
              true, // Assume true for login flow usually
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Make sure the server is running.',
      };
    }
  }

  /// Verifies the OTP sent to the email for registration
  static Future<Map<String, dynamic>> verifyRegisterOTP(
    String email,
    String otp,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 180));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'token': data['access_token'],
          'username': data['username'],
          'hasUserDetails':
              data['hasUserDetails'] ?? false, // Assume false for fresh signup
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Make sure the server is running.',
      };
    }
  }

  /// Complete registration with user details after OTP verification
  static Future<Map<String, dynamic>> completeRegistration(
    String email,
    String username,
    String? phoneNumber,
    String? dob,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/register/complete',
            ), // Changed from update-details to align with remote
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'username': username,
              'phoneNumber': phoneNumber,
              'dob': dob,
            }),
          )
          .timeout(const Duration(seconds: 180));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Save initial profile data to local storage on successful registration
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        await prefs.setString('profile_name_$email', username);
        if (phoneNumber != null) {
          await prefs.setString('profile_phone_$email', phoneNumber);
        }
        if (dob != null) {
          await prefs.setString('profile_dob_$email', dob);
        }

        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Registration completed successfully',
          'token': data['access_token'],
          'username': data['username'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to complete registration',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Fetch user profile details (Backend Only)
  static Future<Map<String, dynamic>> getUserProfile(String email) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/user-profile/$email'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          return {'success': true, 'user': data['user']};
        }
        return {'success': false, 'message': 'User data is null'};
      } else {
        return {'success': false, 'message': 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Update user profile details (Backend Only)
  static Future<Map<String, dynamic>> updateUserProfile(
    String email,
    String username,
    String phoneNumber,
    String dob,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/update-details'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'username': username,
              'phoneNumber': phoneNumber,
              'dob': dob,
            }),
          )
          .timeout(const Duration(seconds: 180));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
