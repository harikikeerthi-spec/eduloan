import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Data Models
class EligibilityCheckDto {
  final int age;
  final int credit;
  final double income;
  final double loan;
  final String employment; // 'employed', 'self', 'student', 'unemployed'
  final String study; // 'undergrad', 'masters', 'doctoral', 'diploma'
  final bool coApplicant;
  final bool collateral;

  EligibilityCheckDto({
    required this.age,
    required this.credit,
    required this.income,
    required this.loan,
    required this.employment,
    required this.study,
    required this.coApplicant,
    required this.collateral,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'credit': credit,
      'income': income,
      'loan': loan,
      'employment': employment,
      'study': study,
      'coApplicant': coApplicant ? 'yes' : 'no',
      'collateral': collateral ? 'yes' : 'no',
    };
  }
}

class EligibilityResult {
  final int score;
  final String status;
  final double ratio;
  final String rateRange;
  final String coverage;
  final String summary;

  EligibilityResult({
    required this.score,
    required this.status,
    required this.ratio,
    required this.rateRange,
    required this.coverage,
    required this.summary,
  });

  factory EligibilityResult.fromJson(Map<String, dynamic> json) {
    return EligibilityResult(
      score: json['score'] ?? 0,
      status: json['status'] ?? 'unlikely',
      ratio: (json['ratio'] ?? 0).toDouble(),
      rateRange: json['rateRange'] ?? '',
      coverage: json['coverage'] ?? '',
      summary: json['summary'] ?? '',
    );
  }
}

class GradeConversionInput {
  final String inputType;
  final dynamic inputValue;
  final double? totalMarks;
  final String outputType;
  final String? gradingSystem;

  GradeConversionInput({
    required this.inputType,
    required this.inputValue,
    this.totalMarks,
    required this.outputType,
    this.gradingSystem,
  });

  Map<String, dynamic> toJson() {
    return {
      'inputType': inputType,
      'inputValue': inputValue,
      if (totalMarks != null) 'totalMarks': totalMarks,
      'outputType': outputType,
      if (gradingSystem != null) 'gradingSystem': gradingSystem,
    };
  }
}

class GradeConversionResult {
  final String inputGrade;
  final String outputGrade;
  final double percentage;
  final double gpa;
  final double cgpa;
  final String letterGrade;
  final String classification;
  final Map<String, String> internationalEquivalent;
  final Map<String, dynamic> analysis;

  GradeConversionResult({
    required this.inputGrade,
    required this.outputGrade,
    required this.percentage,
    required this.gpa,
    required this.cgpa,
    required this.letterGrade,
    required this.classification,
    required this.internationalEquivalent,
    required this.analysis,
  });

  factory GradeConversionResult.fromJson(Map<String, dynamic> json) {
    return GradeConversionResult(
      inputGrade: json['inputGrade'] ?? '',
      outputGrade: json['outputGrade'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      gpa: (json['gpa'] ?? 0).toDouble(),
      cgpa: (json['cgpa'] ?? 0).toDouble(),
      letterGrade: json['letterGrade'] ?? '',
      classification: json['classification'] ?? '',
      internationalEquivalent: Map<String, String>.from(
        json['internationalEquivalent'] ?? {},
      ),
      analysis: Map<String, dynamic>.from(json['analysis'] ?? {}),
    );
  }
}

class UniversityData {
  final String name;
  final String rank;
  final String tuition;
  final String rate;
  final String salary;
  final String loc;

  UniversityData({
    required this.name,
    required this.rank,
    required this.tuition,
    required this.rate,
    required this.salary,
    required this.loc,
  });

  factory UniversityData.fromJson(Map<String, dynamic> json) {
    return UniversityData(
      name: json['name'] ?? '',
      rank: json['rank'] ?? '',
      tuition: json['tuition'] ?? '',
      rate: json['rate'] ?? '',
      salary: json['salary'] ?? '',
      loc: json['loc'] ?? '',
    );
  }
}

class AiLogicService {
  // Try these URLs in order until one works
  static const List<String> _baseUrls = [
    'http://10.0.2.2:3000/ai', // 1. Standard Android Emulator
    'http://192.168.55.102:3000/ai', // 2. Your LAN IP (Works for devices)
    'http://127.0.0.1:3000/ai', // 3. Localhost (ADB Reverse)
  ];

  Future<dynamic> _postRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    String lastError = 'Unknown error';
    for (String baseUrl in _baseUrls) {
      final url = Uri.parse('$baseUrl/$endpoint');
      try {
        debugPrint('Trying connection to: $url');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('Success connected to: $url');
          return jsonDecode(response.body);
        } else {
          lastError =
              'Error ${response.statusCode} at $url\nBody: ${response.body}';
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('Failed to connect to $baseUrl: $e');
        // Continue to next URL
      }
    }
    throw Exception('Connection failed. Last error: $lastError');
  }

  Future<EligibilityResult> checkEligibility(EligibilityCheckDto data) async {
    try {
      final body = await _postRequest('eligibility-check', data.toJson());
      if (body['success'] == true && body['eligibility'] != null) {
        return EligibilityResult.fromJson(body['eligibility']);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<GradeConversionResult> convertGrade(GradeConversionInput data) async {
    try {
      final body = await _postRequest('convert-grades', data.toJson());
      if (body['success'] == true && body['gradeConversion'] != null) {
        return GradeConversionResult.fromJson(body['gradeConversion']);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, UniversityData>> compareUniversities(
    String uni1,
    String uni2,
  ) async {
    try {
      final body = await _postRequest('compare-universities', {
        'uni1': uni1,
        'uni2': uni2,
      });

      if (body['success'] == true && body['data'] != null) {
        final data = body['data'];
        return {
          'uni1': UniversityData.fromJson(data['uni1']),
          'uni2': UniversityData.fromJson(data['uni2']),
        };
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
