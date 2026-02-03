import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan.dart';

class LoanService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<Loan> createLoan({
    required String userId,
    required String applicantName,
    required String phoneNumber,
    required String email,
    required String institute,
    required String course,
    required double amount,
    required int tenure,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/loans'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'applicantName': applicantName,
          'phoneNumber': phoneNumber,
          'email': email,
          'institute': institute,
          'course': course,
          'amount': amount,
          'tenure': tenure,
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

  Future<List<Loan>> getUserLoans(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/loans/user/$userId'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.get(
        Uri.parse('$baseUrl/loans/$loanId'),
        headers: {'Content-Type': 'application/json'},
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
}
