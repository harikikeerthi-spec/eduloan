import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_document.dart';
import 'api_config.dart';

class UserService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<List<UserDocument>> getUserDocuments() async {
    try {
      final token = await _getToken();
      if (token == null) return [];
      final userId = await _getUserId();
      if (userId == null) return [];

      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/documents/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List? rawList;
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          if (decoded['data'] is List) {
            rawList = decoded['data'];
          } else if (decoded['documents'] is List) {
            rawList = decoded['documents'];
          } else if (decoded['userDocuments'] is List) {
            rawList = decoded['userDocuments'];
          } else if (decoded['results'] is List) {
            rawList = decoded['results'];
          }
        }
        if (rawList != null) {
          return rawList
              .map((item) => UserDocument.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      return [];
    }
  }

  static Future<String?> uploadDocument(File file, String docType, {String? password}) async {
    try {
      final token = await _getToken();
      if (token == null) return 'Authentication token not found.';
      final userId = await _getUserId();
      if (userId == null) return 'User ID not found.';

      final baseUrl = await ApiConfig.getBaseUrl();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['docType'] = docType;
      request.fields['userId'] = userId;
      // Send document password if provided (for backend decryption)
      if (password != null && password.isNotEmpty) {
        request.fields['docPassword'] = password;
      }

      final filePath = file.path.toLowerCase();
      MediaType contentType;
      if (filePath.endsWith('.pdf')) {
        contentType = MediaType('application', 'pdf');
      } else if (filePath.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else if (filePath.endsWith('.heic') || filePath.endsWith('.heif')) {
        contentType = MediaType('image', 'heic');
      } else if (filePath.endsWith('.webp')) {
        contentType = MediaType('image', 'webp');
      } else if (filePath.endsWith('.doc')) {
        contentType = MediaType('application', 'msword');
      } else if (filePath.endsWith('.docx')) {
        contentType = MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      } else {
        // Fallback: send as octet-stream so the server filter always accepts it
        contentType = MediaType('application', 'octet-stream');
      }

      request.files.add(await http.MultipartFile.fromPath('file', file.path, contentType: contentType));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final docData = data['data'];
            final ocrResult = docData?['ocrResult'] ?? docData?['verification'] ?? data['ocrResult'];
            final extractedFields = ocrResult?['extractedFields'] ??
                ocrResult?['extracted_fields'] ??
                ocrResult?['extracted_data'] ??
                docData?['verificationMetadata']?['details']?['extractedFields'] ??
                docData?['verificationMetadata']?['extractedFields'];

            if (extractedFields != null && extractedFields is Map) {
              final Map map = extractedFields;
              final numVal = map['pan_number'] ??
                  map['panNumber'] ??
                  map['pan'] ??
                  map['aadhaar_number'] ??
                  map['aadhar_number'] ??
                  map['aadhaarNumber'] ??
                  map['aadharNumber'] ??
                  map['passport_number'] ??
                  map['passportNumber'] ??
                  map['roll_number'] ??
                  map['rollNumber'] ??
                  map['registration_number'] ??
                  map['registrationNumber'];
              if (numVal != null && numVal.toString().trim().isNotEmpty) {
                await prefs.setString('ocr_number_${userId}_$docType', numVal.toString().trim());
              }
            }
          } catch (e) {
            debugPrint('Error caching OCR number in user_service: $e');
          }
          return null;
        } else {
          return data['message'] ?? 'Upload failed.';
        }
      }

      try {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          if (data['message'] is List) {
            return (data['message'] as List).join(', ');
          }
          return data['message'].toString();
        }
      } catch (_) {}

      return 'Upload failed (Status: ${response.statusCode})';
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return 'Error uploading document: $e';
    }
  }

  static Future<bool> deleteDocument(String docType) async {
    try {
      final token = await _getToken();
      if (token == null) return false;
      final userId = await _getUserId();
      if (userId == null) return false;

      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.delete(
        Uri.parse('$baseUrl/documents/$userId/$docType'),
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
    final userId = await _getUserId() ?? '';
    return '$baseUrl/documents/view/$userId/$docType';
  }
}
