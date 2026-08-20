import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class OnboardingService {
  static Future<Map<String, dynamic>> saveOnboardingData(
    Map<String, dynamic> data,
  ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/onboarding'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result['success'] == true) {
          // Save basic info locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', result['user']['id']);
          await prefs.setString('user_email', result['user']['email']);
          await prefs.setString(
            'user_firstName',
            result['user']['firstName'] ?? '',
          );
          await prefs.setString(
            'user_lastName',
            result['user']['lastName'] ?? '',
          );
          await prefs.setString(
            'user_phone',
            result['user']['phoneNumber'] ?? result['user']['phone'] ?? '',
          );
          await prefs.setBool('is_onboarded', true);
        }
        return result;
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to save onboarding data',
        };
      }
    } catch (e) {
      debugPrint('Error saving onboarding data: $e');
      return {'success': false, 'message': 'Connectivity error: $e'};
    }
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_onboarded') ?? false;
  }
}
