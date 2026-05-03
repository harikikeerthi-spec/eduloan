import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan.dart';
import 'api_config.dart';

class LoanService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    debugPrint(
      'LoanService: Sending request with token: ${token != null ? "Present (Starts with ${token.substring(0, 10)}...)" : "MISSING"}',
    );
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Loan> createLoan({
    required String userId,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String targetCountry,
    required String universityName,
    required String courseName,
    required String bank,
    required String loanType,
    required double amount,
    required int tenure,
    String? purpose,
    String? fatherName,
    String? fatherPhone,
    String? fatherEmail,
    String? motherName,
    String? motherPhone,
    String? motherEmail,
    bool hasCollateral = false,
    String? collateralDetails,
  }) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/applications'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phoneNumber,
          'email': email,
          'targetCountry': targetCountry,
          'universityName': universityName,
          'courseName': courseName,
          'bank': bank,
          'loanType': loanType,
          'amount': amount,
          'tenure': tenure,
          'purpose': purpose,
          'fatherName': fatherName,
          'fatherPhone': fatherPhone,
          'fatherEmail': fatherEmail,
          'motherName': motherName,
          'motherPhone': motherPhone,
          'motherEmail': motherEmail,
          'hasCollateral': hasCollateral,
          'collateralDetails': collateralDetails,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Loan.fromJson(data['data']);
      } else {
        throw Exception('Failed to create loan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating loan: $e');
    }
  }

  Future<List<Loan>> getUserLoans() async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/applications/my'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> loansJson = data['data'];
        return loansJson.map((json) => Loan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch loans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching loans: $e');
    }
  }

  Future<Loan> getLoanById(String loanId) async {
    try {
      final headers = await _getHeaders();
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/applications/$loanId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Loan.fromJson(data['data']);
      } else {
        throw Exception('Failed to fetch loan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching loan: $e');
    }
  }

  Future<void> deleteLoan(String loanId) async {
    debugPrint('[LoanService] Attempting to delete loan: $loanId');
    try {
      final headers = await _getHeaders();
      final baseUrl = await ApiConfig.getBaseUrl();
      debugPrint('[LoanService] URL: $baseUrl/applications/$loanId');
      final response = await http.delete(
        Uri.parse('$baseUrl/applications/$loanId'),
        headers: headers,
      );

      debugPrint('[LoanService] Response status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete loan: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[LoanService] Error deleting loan: $e');
      throw Exception('Error deleting loan: $e');
    }
  }

  Future<void> uploadDocument({
    required String applicationId,
    required String docType,
    required String docName,
    required String filePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final baseUrl = await ApiConfig.getBaseUrl();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/applications/$applicationId/documents'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['docType'] = docType;
      request.fields['docName'] = docName;

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Upload failed: ${response.body}');
        throw Exception('Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }
}
