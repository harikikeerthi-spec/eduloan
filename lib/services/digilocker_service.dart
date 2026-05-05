import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DigilockerService {
  // Use the local IP for the emulator/device to reach the NestJS backend
  static const String _baseUrl = 'https://vidyaloans.in/api/digilocker';

  Future<Map<String, dynamic>> verifyDigilocker(String authCode, {String? loanId, String? codeVerifier}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
 
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': authCode,
          'loanId': loanId,
          'code_verifier': codeVerifier,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to verify DigiLocker: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error verifying DigiLocker: $e');
    }
  }
}
