import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan.dart';
import 'api_config.dart';
import 'api_client.dart';

class LoanService {
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
    int? tenure,
    String? purpose,
    String? fatherName,
    String? fatherPhone,
    String? fatherEmail,
    String? motherName,
    String? motherPhone,
    String? motherEmail,
    String? city,
    String? pincode,
    String? country,
    bool hasCollateral = false,
    String? collateralDetails,
    bool hasCoApplicant = false,
    String? coApplicantName,
    String? coApplicantRelation,
    String? coApplicantPhone,
    String? coApplicantEmail,
    double? coApplicantIncome,
    String? fieldOfStudy,
    String? admissionStatus,
    String? dateOfBirth,
    bool isRetry = false,
  }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.post(
        Uri.parse('$baseUrl/applications'),
        body: json.encode({
          'userId': userId,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phoneNumber,
          'email': email,
          'dateOfBirth': dateOfBirth,
          'targetCountry': targetCountry,
          'country': country ?? targetCountry,
          'city': city,
          'pincode': pincode,
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
          'hasCoApplicant': hasCoApplicant,
          'coApplicantName': coApplicantName,
          'coApplicantRelation': coApplicantRelation,
          'coApplicantPhone': coApplicantPhone,
          'coApplicantEmail': coApplicantEmail,
          'coApplicantIncome': coApplicantIncome,
          'fieldOfStudy': fieldOfStudy,
          'admissionStatus': admissionStatus,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Loan.fromJson(data['data']);
      } else {
        String serverMsg = '';
        try {
          final errBody = json.decode(response.body);
          serverMsg = errBody['message'] ?? errBody['error'] ?? '';
        } catch (_) {}
        if (serverMsg.isNotEmpty) {
          throw Exception(serverMsg);
        }
        throw Exception('Failed to create loan: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Session expired')) rethrow;
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<Loan>> getUserLoans({bool isRetry = false}) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/applications/my'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> loansJson = data['data'];
        return loansJson.map((json) => Loan.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch loans: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Session expired')) rethrow;
      throw Exception('Error fetching loans: $e');
    }
  }

  Future<Loan> getLoanById(String loanId) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await ApiClient.get(
        Uri.parse('$baseUrl/applications/$loanId'),
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
      final baseUrl = await ApiConfig.getBaseUrl();
      debugPrint('[LoanService] URL: $baseUrl/auth/application/$loanId');
      final response = await ApiClient.delete(
        Uri.parse('$baseUrl/auth/application/$loanId'),
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
        debugPrint('Upload failed: ${response.body}');
        throw Exception('Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }
}
