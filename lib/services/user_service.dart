import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_document.dart';
import 'api_config.dart';

class UserService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<List<UserDocument>> getUserDocuments() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/users/documents'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => UserDocument.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      return [];
    }
  }

  static Future<bool> uploadDocument(File file, String docType) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final baseUrl = await ApiConfig.getBaseUrl();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/documents'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['docType'] = docType;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return false;
    }
  }

  static Future<bool> deleteDocument(String docType) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/documents/$docType'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  static Future<String> getDocumentViewUrl(String docType) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    return '$baseUrl/users/documents/$docType/view';
  }
}
