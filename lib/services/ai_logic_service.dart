import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Data Models
class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => message;
}

class EligibilityCheckDto {
  final int age;
  final int credit;
  final double income;
  final double loan;
  final String employment; // 'employed', 'self', 'student', 'unemployed'
  final String study; // 'undergrad', 'masters', 'doctoral', 'diploma'
  final String maritalStatus; // 'single', 'married'
  final bool coApplicant;
  final bool collateral;

  EligibilityCheckDto({
    required this.age,
    required this.credit,
    required this.income,
    required this.loan,
    required this.employment,
    required this.study,
    required this.maritalStatus,
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
      'maritalStatus': maritalStatus,
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
      name: json['name'] ?? 'N/A',
      rank: json['rank'] ?? 'N/A',
      tuition: json['tuition'] ?? 'N/A',
      rate: json['rate'] ?? 'N/A',
      salary: json['salary'] ?? 'N/A',
      loc: json['loc'] ?? 'N/A',
    );
  }
}

class SopAnalysisResult {
  final double totalScore;
  final String quality;
  final List<Map<String, dynamic>> categories; // {name, score, weight}
  final List<Map<String, String>> weakAreas; // {issue, recommendation}
  final String summary;

  SopAnalysisResult({
    required this.totalScore,
    required this.quality,
    required this.categories,
    required this.weakAreas,
    required this.summary,
  });

  factory SopAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SopAnalysisResult(
      totalScore: (json['totalScore'] ?? 0).toDouble(),
      quality: json['quality'] ?? '',
      categories: List<Map<String, dynamic>>.from(json['categories'] ?? []),
      weakAreas:
          (json['weakAreas'] as List?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          [],
      summary: json['summary'] ?? '',
    );
  }
}

class AdmitPredictionResult {
  final String university;
  final int probability;
  final List<String> feedback;
  final int tier;

  AdmitPredictionResult({
    required this.university,
    required this.probability,
    required this.feedback,
    required this.tier,
  });

  factory AdmitPredictionResult.fromJson(Map<String, dynamic> json) {
    return AdmitPredictionResult(
      university: json['university'] ?? '',
      probability: json['probability'] ?? 0,
      feedback: List<String>.from(json['feedback'] ?? []),
      tier: json['tier'] ?? 3,
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
            .timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('Success connected to: $url');
          return jsonDecode(response.body);
        } else {
          // Server responded, but with error (400, 500, etc.)
          dynamic msg = response.body;
          try {
            final errorBody = jsonDecode(response.body);
            msg = errorBody['message'] ?? response.body;
          } catch (_) {}

          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw AiServiceException(msg.toString());
          } else {
            throw AiServiceException('Error ${response.statusCode}: $msg');
          }
        }
      } catch (e) {
        if (e is AiServiceException) {
          throw e;
        }

        lastError = e.toString();
        debugPrint('Failed to connect to $baseUrl: $e');
        // Continue to next URL for network failures
      }
    }
    throw Exception('Connection failed. Last error: $lastError');
  }

  Future<EligibilityResult> checkEligibility(EligibilityCheckDto data) async {
    final body = await _postRequest('eligibility-check', data.toJson());
    if (body['success'] == true && body['eligibility'] != null) {
      return EligibilityResult.fromJson(body['eligibility']);
    }
    throw Exception('Invalid response format');
  }

  Future<GradeConversionResult> convertGrade(GradeConversionInput data) async {
    final body = await _postRequest('convert-grades', data.toJson());
    if (body['success'] == true && body['gradeConversion'] != null) {
      return GradeConversionResult.fromJson(body['gradeConversion']);
    }
    throw Exception('Invalid response format');
  }

  Future<Map<String, UniversityData>> compareUniversities(
    String uni1,
    String uni2,
  ) async {
    final body = await _postRequest('compare-universities', {
      'uni1': uni1,
      'uni2': uni2,
    });

    if (body['success'] == true && body['data'] != null) {
      final data = body['data'];
      final u1 = data['uni1'] ?? <String, dynamic>{};
      final u2 = data['uni2'] ?? <String, dynamic>{};

      return {
        'uni1': UniversityData.fromJson(Map<String, dynamic>.from(u1)),
        'uni2': UniversityData.fromJson(Map<String, dynamic>.from(u2)),
      };
    }
    throw Exception('Invalid response format');
  }

  Future<SopAnalysisResult> analyzeSop(String text) async {
    final body = await _postRequest('sop-analysis', {'sop': text});
    if (body['success'] == true && body['analysis'] != null) {
      return SopAnalysisResult.fromJson(body['analysis']);
    }
    throw Exception('Invalid response format');
  }

  Future<AdmitPredictionResult> predictAdmission(
    Map<String, dynamic> profile,
  ) async {
    final body = await _postRequest('predict-admission', profile);
    if (body['success'] == true && body['prediction'] != null) {
      return AdmitPredictionResult.fromJson(body['prediction']);
    }
    throw Exception('Invalid response format');
  }

  Future<String> sendSupportMessage(String message) async {
    final body = await _postRequest('support-chat', {'message': message});
    if (body['success'] == true && body['message'] != null) {
      return body['message'];
    }
    throw Exception('Invalid response format');
  }
}
