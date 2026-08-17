import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'secure_storage_service.dart';

class DigilockerService {
  // Use dynamic base URL from ApiConfig
  static String get _baseUrl => '${ApiConfig.baseUrl}/digilocker';

  Future<Map<String, dynamic>> verifyDigilocker(String authCode, {String? loanId, String? codeVerifier}) async {
    final token = await SecureStorageService.getToken();
 
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
      ).timeout(const Duration(seconds: 30));

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
