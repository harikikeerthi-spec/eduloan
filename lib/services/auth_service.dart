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

  /// Sends a Unified OTP (handles both login and signup)
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      // Check both status code AND the 'success' flag from backend
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
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Verifies the OTP (Unified Flow)
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      // CRITICAL FIX: The backend might return 201 Created but with { success: false } body
      // We must check data['success'] explicitly.
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final token = data['access_token'];

        // Save token and email
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        if (token != null) {
          await prefs.setString('auth_token', token);
        }

        // Save userId if available
        if (data['userId'] != null) {
          await prefs.setString('userId', data['userId']);
        }

        // Save user details if available
        if (data['firstName'] != null) {
          await prefs.setString('user_firstName', data['firstName']);
        }
        if (data['lastName'] != null) {
          await prefs.setString('user_lastName', data['lastName']);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Verification successful',
          'access_token': token,
          'userExists': data['userExists'] ?? false,
          'hasUserDetails': data['hasUserDetails'] ?? false,
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'userId': data['userId'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Updates user details (Complete Registration / Profile Update)
  static Future<Map<String, dynamic>> updateUserDetails(
    String email,
    String firstName,
    String lastName,
    String phoneNumber,
    String dateOfBirth,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/update-details'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'firstName': firstName,
              'lastName': lastName,
              'phoneNumber': phoneNumber,
              'dateOfBirth': dateOfBirth,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update local prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_firstName', firstName);
        await prefs.setString('user_lastName', lastName);
        await prefs.setString('user_phone', phoneNumber);
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
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Fetches user dashboard data (Profile)
  static Future<Map<String, dynamic>> getUserDashboard(String email) async {
    try {
      final response = await http
          .post(
            // Changed to POST as per some backend conventions, or assumes GET if modifying.
            // Wait, backend auth.controller.ts: @Post('dashboard') async dashboard(@Body() body: { email: string })
            // So it is POST /auth/dashboard
            Uri.parse('$baseUrl/dashboard'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'user':
              data, // The backend returns the user object directly or simpler structure?
          // Backend: return { message: 'Dashboard data', user: ... } or just user?
          // Let's assume standard response wrapper or check backend code if verified.
          // I'll assume data contains the user fields directly or inside 'user'.
          // Safest is to return data.
          'data': data,
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch dashboard data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
