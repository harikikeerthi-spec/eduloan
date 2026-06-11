import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

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
  final String employment;
  final String study;
  final String maritalStatus;
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
      'totalMarks': totalMarks,
      'outputType': outputType,
      'gradingSystem': gradingSystem,
    };
  }
}

class GradeConversionResult {
  final double score;
  final String scale;
  final String quality;
  final Map<String, String> internationalEquivalent;
  final Map<String, dynamic> analysis;

  GradeConversionResult({
    required this.score,
    required this.scale,
    required this.quality,
    required this.internationalEquivalent,
    required this.analysis,
  });

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll('%', '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  // Compatibility getters for legacy code
  double get percentage => _toDouble(analysis['percentage'] ?? score);
  double get gpa => _toDouble(analysis['gpa'] ?? score);
  double get cgpa => _toDouble(analysis['cgpa'] ?? score);
  String get outputGrade => quality;

  factory GradeConversionResult.fromJson(Map<String, dynamic> json) {
    final analysisMap = Map<String, dynamic>.from(json['analysis'] ?? {});
    
    // Copy root-level values into analysis map if they aren't already there
    if (json['percentage'] != null && analysisMap['percentage'] == null) {
      analysisMap['percentage'] = json['percentage'];
    }
    if (json['gpa'] != null && analysisMap['gpa'] == null) {
      analysisMap['gpa'] = json['gpa'];
    }
    if (json['cgpa'] != null && analysisMap['cgpa'] == null) {
      analysisMap['cgpa'] = json['cgpa'];
    }
    if (json['strength'] != null && analysisMap['strength'] == null) {
      analysisMap['strength'] = json['strength'];
    }
    if (json['competitiveness'] != null && analysisMap['competitiveness'] == null) {
      analysisMap['competitiveness'] = json['competitiveness'];
    }
    if (json['recommendations'] != null && analysisMap['recommendations'] == null) {
      analysisMap['recommendations'] = json['recommendations'];
    }

    return GradeConversionResult(
      score: (json['score'] ?? 0).toDouble(),
      scale: json['scale'] ?? '',
      quality: json['quality'] ?? json['letterGrade'] ?? json['outputGrade'] ?? '',
      internationalEquivalent: Map<String, String>.from(
        json['internationalEquivalent'] ?? {},
      ),
      analysis: analysisMap,
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
  final List<Map<String, dynamic>> categories;
  final List<Map<String, String>> weakAreas;
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

class PostAnalysisResult {
  final String sentiment;
  final List<String> tags;
  final String feedback;

  PostAnalysisResult({
    required this.sentiment,
    required this.tags,
    required this.feedback,
  });

  factory PostAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PostAnalysisResult(
      sentiment: json['sentiment'] ?? 'Neutral',
      tags: List<String>.from(json['tags'] ?? []),
      feedback: json['feedback'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'sentiment': sentiment, 'tags': tags, 'feedback': feedback};
  }
}

class UniversityRecommendation {
  final String name;
  final String chance;
  final String type;
  final String rank;
  final String tuition;
  final String location;
  final String reason;
  final String avgSalary;
  final String deadline;
  final String flag;
  final String country;
  final String programName;
  final String logoUrl;
  final String description;
  final String roi;
  final String acceptanceRate;
  final String duration;
  final String category;
  final String indianCommunity;
  final String theRank;
  final String costOfLiving;
  final String medianPackage;
  final String websiteUrl;
  final String universityType;
  final String genderRatio;
  final String studentTeacherRatio;
  final String raceRatio;
  final String safetyStatus;
  final String academicFocus;
  final List<String> images;
  final List<String> admissionProcess;
  final Map<String, String> testRequirements;

  UniversityRecommendation({
    required this.name,
    required this.chance,
    required this.type,
    required this.rank,
    required this.tuition,
    required this.location,
    required this.reason,
    this.avgSalary = '',
    this.deadline = '',
    this.flag = '',
    this.country = '',
    this.programName = '',
    this.logoUrl = '',
    this.description = '',
    this.roi = '',
    this.acceptanceRate = '',
    this.duration = '',
    this.category = '',
    this.indianCommunity = '',
    this.theRank = '',
    this.costOfLiving = '',
    this.medianPackage = '',
    this.websiteUrl = '',
    this.universityType = '',
    this.genderRatio = '',
    this.studentTeacherRatio = '',
    this.raceRatio = '',
    this.safetyStatus = '',
    this.academicFocus = '',
    this.images = const [],
    this.admissionProcess = const [],
    this.testRequirements = const {},
  });

  factory UniversityRecommendation.fromJson(Map<String, dynamic> json) {
    String logo = json['logoUrl'] ?? '';
    if (logo.isEmpty) {
      String? domainSource =
          json['domain']?.toString() ?? json['websiteUrl']?.toString();

      if (domainSource != null && domainSource.isNotEmpty) {
        String domain = domainSource.trim().toLowerCase();
        domain = domain.replaceFirst(
          RegExp(r'^(domain|website|url|site|link):\s*'),
          '',
        );
        domain = domain.replaceFirst(RegExp(r'^https?://'), '');
        domain = domain.replaceFirst(RegExp(r'^www\.'), '');

        // Handle paths (e.g., stanford.edu/admission -> stanford.edu)
        if (domain.contains('/')) {
          domain = domain.split('/').first;
        }

        if (domain.isNotEmpty && domain.contains('.')) {
          logo = "https://logo.clearbit.com/$domain";
        }
      }
    }

    return UniversityRecommendation(
      name: json['name'] ?? '',
      chance: json['chance'] ?? '',
      type: json['type'] ?? '',
      rank: json['rank'] ?? '',
      tuition: json['tuition'] ?? '',
      location: json['location'] ?? '',
      reason: json['reason'] ?? '',
      avgSalary: json['avgSalary'] ?? '',
      deadline: json['deadline'] ?? '',
      flag: json['flag'] ?? '',
      country: json['country'] ?? '',
      programName: json['programName'] ?? '',
      logoUrl: logo,
      description: json['description'] ?? '',
      roi: json['roi'] ?? '',
      acceptanceRate: json['acceptanceRate'] ?? '',
      duration: json['duration'] ?? '',
      category: json['category'] ?? '',
      indianCommunity:
          json['indianCommunity'] ?? json['indian_community'] ?? '',
      theRank: json['theRank'] ?? '',
      costOfLiving:
          json['costOfLiving'] ??
          json['cost_of_living'] ??
          json['costOfLiving_usd'] ??
          '',
      medianPackage:
          json['medianPackage'] ??
          json['median_package'] ??
          json['avgSalary'] ??
          json['average_salary'] ??
          '',
      websiteUrl: json['websiteUrl'] ?? json['website_url'] ?? '',
      universityType: json['universityType'] ?? json['university_type'] ?? '',
      genderRatio: json['genderRatio'] ?? '',
      studentTeacherRatio: json['studentTeacherRatio'] ?? '',
      raceRatio: json['raceRatio'] ?? '',
      safetyStatus: json['safetyStatus'] ?? '',
      academicFocus: json['academicFocus'] ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      admissionProcess: (json['admissionProcess'] as List?)?.map((e) => e.toString()).toList() ?? [],
      testRequirements: (json['testRequirements'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          ) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'chance': chance,
      'type': type,
      'rank': rank,
      'tuition': tuition,
      'location': location,
      'reason': reason,
      'avgSalary': avgSalary,
      'deadline': deadline,
      'flag': flag,
      'country': country,
      'programName': programName,
      'logoUrl': logoUrl,
      'description': description,
      'roi': roi,
      'acceptanceRate': acceptanceRate,
      'duration': duration,
      'category': category,
      'indianCommunity': indianCommunity,
      'theRank': theRank,
      'costOfLiving': costOfLiving,
      'medianPackage': medianPackage,
      'websiteUrl': websiteUrl,
      'universityType': universityType,
      'genderRatio': genderRatio,
      'studentTeacherRatio': studentTeacherRatio,
      'raceRatio': raceRatio,
      'safetyStatus': safetyStatus,
      'academicFocus': academicFocus,
      'images': images,
      'admissionProcess': admissionProcess,
      'testRequirements': testRequirements,
    };
  }
}

class ShortlistResult {
  final List<UniversityRecommendation> recommendations;

  ShortlistResult({required this.recommendations});

  factory ShortlistResult.fromJson(Map<String, dynamic> json) {
    var data =
        json['data']?['recommendations'] ?? json['recommendations'] ?? [];
    var list = data as List;
    return ShortlistResult(
      recommendations: list
          .map((e) => UniversityRecommendation.fromJson(e))
          .toList(),
    );
  }
}

class LoanOffer {
  final String id;
  final String bank;
  final String name;
  final String amount;
  final String rate;
  final String processingTime;
  final String savings;
  final bool requiresCoApplicant;
  final bool requiresCollateral;
  final String bestFor;

  LoanOffer({
    required this.id,
    required this.bank,
    required this.name,
    required this.amount,
    required this.rate,
    required this.processingTime,
    required this.savings,
    required this.requiresCoApplicant,
    required this.requiresCollateral,
    required this.bestFor,
  });

  factory LoanOffer.fromJson(Map<String, dynamic> json) {
    return LoanOffer(
      id: json['id'] ?? '',
      bank: json['bank'] ?? '',
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      rate: json['rate'] ?? '',
      processingTime: json['processingTime'] ?? '',
      savings: json['savings'] ?? '',
      requiresCoApplicant: json['requiresCoApplicant'] ?? false,
      requiresCollateral: json['requiresCollateral'] ?? false,
      bestFor: json['bestFor'] ?? '',
    );
  }
}

class LoanRecommendationResult {
  final LoanOffer primary;
  final int primaryFit;
  final List<LoanOffer> alternatives;

  LoanRecommendationResult({
    required this.primary,
    this.primaryFit = 0,
    this.alternatives = const [],
  });

  factory LoanRecommendationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final primaryData = data['primary'] ?? {};
    final primaryOffer = primaryData['offer'] != null
        ? LoanOffer.fromJson(primaryData['offer'])
        : LoanOffer(
            id: '0',
            bank: 'N/A',
            name: 'No Primary Offer',
            amount: 'N/A',
            rate: 'N/A',
            processingTime: 'N/A',
            savings: 'N/A',
            requiresCoApplicant: false,
            requiresCollateral: false,
            bestFor: '',
          );

    final alternativesList = data['alternatives'] as List? ?? [];

    return LoanRecommendationResult(
      primary: primaryOffer,
      primaryFit: (primaryData['fit'] ?? 0).toInt(),
      alternatives: alternativesList
          .map((e) => LoanOffer.fromJson(e['offer'] ?? e))
          .toList(),
    );
  }
}

// ── Visa Interview Data Models ──

class InterviewMessage {
  final String sender; // 'bot' or 'user'
  final String text;
  final DateTime timestamp;

  InterviewMessage({
    required this.sender,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory InterviewMessage.fromJson(Map<String, dynamic> json) {
    return InterviewMessage(
      sender: json['role'] == 'officer' ? 'bot' : 'user',
      text: json['question'] ?? json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, String> toJson() {
    return {'role': sender == 'bot' ? 'officer' : 'applicant', 'content': text};
  }
}

class VisaInterviewStartResponse {
  final String message;
  final String currentSection;

  VisaInterviewStartResponse({
    required this.message,
    required this.currentSection,
  });

  factory VisaInterviewStartResponse.fromJson(Map<String, dynamic> json) {
    return VisaInterviewStartResponse(
      message: json['question'] ?? json['message'] ?? '',
      currentSection: json['currentSection'] ?? 'Introduction',
    );
  }
}

class VisaInterviewContinueResponse {
  final String message;
  final String nextSection;

  VisaInterviewContinueResponse({
    required this.message,
    required this.nextSection,
  });

  factory VisaInterviewContinueResponse.fromJson(Map<String, dynamic> json) {
    return VisaInterviewContinueResponse(
      message: json['question'] ?? json['message'] ?? '',
      nextSection: json['currentSection'] ?? json['nextSection'] ?? '',
    );
  }
}

class EvaluationResult {
  final String question;
  final String answer;
  final int score;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;

  EvaluationResult({
    required this.question,
    required this.answer,
    required this.score,
    required this.feedback,
    required this.strengths,
    required this.improvements,
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      score: json['score'] ?? 0,
      feedback: json['feedback'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'score': score,
      'feedback': feedback,
      'strengths': strengths,
      'improvements': improvements,
    };
  }
}

class AiLogicService {
  static final AiLogicService _instance = AiLogicService._internal();
  factory AiLogicService() => _instance;
  AiLogicService._internal();

  Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final String baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/ai/$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw AiServiceException('Error from AI service: ${response.statusCode}');
    }
  }

  Future<dynamic> _getRequest(String endpoint) async {
    final String baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/ai/$endpoint');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw AiServiceException('Error from AI service: ${response.statusCode}');
    }
  }

  // --- University Inquiry (Callback) ---

  Future<bool> requestUniversityCallback(
    String universityName, {
    String type = 'callback',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name') ?? 'Student';
      final email = prefs.getString('email') ?? '';
      final userId = prefs.getString('userId') ?? '';

      final String baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse('$baseUrl/university-inquiry');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'userId': userId,
          'mobile': 'N/A',
          'universityName': universityName,
          'type': type,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true || data['id'] != null;
      }
      return false;
    } catch (e) {
      debugPrint('Callback request error: $e');
      return false;
    }
  }

  Future<bool> checkUniversityCallback(
    String universityName, {
    String type = 'callback',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final userId = prefs.getString('userId') ?? '';

      if (email.isEmpty && userId.isEmpty) return false;

      final String baseUrl = await ApiConfig.getBaseUrl();
      final url = Uri.parse(
        '$baseUrl/university-inquiry/check?email=${Uri.encodeComponent(email)}&userId=${Uri.encodeComponent(userId)}&universityName=${Uri.encodeComponent(universityName)}&type=$type',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> sendSupportMessage(String message) async {
    final data = await _postRequest('support-chat', {'message': message});
    return data['message'] ?? '';
  }

  Future<EligibilityResult> checkEligibility(EligibilityCheckDto dto) async {
    final data = await _postRequest('eligibility-check', dto.toJson());
    return EligibilityResult.fromJson(data['eligibility'] ?? data);
  }

  Future<GradeConversionResult> convertGrade(GradeConversionInput input) async {
    final data = await _postRequest('convert-grades', input.toJson());
    return GradeConversionResult.fromJson(data['gradeConversion'] ?? data);
  }

  Future<Map<String, UniversityData>> compareUniversities(
    String uni1,
    String uni2,
  ) async {
    final data = await _postRequest('compare-universities', {
      'uni1': uni1,
      'uni2': uni2,
    });
    final map = data['data'] ?? data;
    return {
      'uni1': UniversityData.fromJson(map['uni1']),
      'uni2': UniversityData.fromJson(map['uni2']),
    };
  }

  Future<SopAnalysisResult> analyzeSop(
    String content, [
    String? profile,
  ]) async {
    final data = await _postRequest('sop-analysis', {
      'sop': content,
      'profile': profile,
    });
    return SopAnalysisResult.fromJson(data['analysis'] ?? data);
  }

  Future<AdmitPredictionResult> predictAdmission(
    dynamic targetOrProfile, [
    Map<String, dynamic>? profileExtra,
  ]) async {
    Map<String, dynamic> body;
    if (targetOrProfile is Map<String, dynamic>) {
      body = {
        'university': targetOrProfile['targetUniversity'] ?? '',
        'profile': targetOrProfile,
      };
    } else {
      body = {
        'university': targetOrProfile.toString(),
        'profile': profileExtra,
      };
    }

    final data = await _postRequest('predict-admission', body);
    return AdmitPredictionResult.fromJson(data['prediction'] ?? data);
  }

  Future<PostAnalysisResult> analyzePost(String content) async {
    final data = await _postRequest('analyze-post', {'content': content});
    return PostAnalysisResult.fromJson(data['analysis'] ?? data);
  }

  Future<bool> checkDuplicate(String content) async {
    final data = await _postRequest('check-duplicate', {'content': content});
    return data['isDuplicate'] ?? false;
  }

  Future<ShortlistResult> shortlistUniversities(
    Map<String, dynamic> profile, {
    String? userId,
    List<Map<String, String>>? messages,
  }) async {
    final body = {
      'profile': profile,
      if (userId != null) 'userId': userId,
      if (messages != null) 'messages': messages,
    };
    final data = await _postRequest('shortlist', body);
    return ShortlistResult.fromJson(data);
  }

  Future<ShortlistResult> evaluateShortlist(
    Map<String, dynamic> profile, {
    String? userId,
    List<Map<String, String>>? messages,
  }) async {
    final body = {
      'profile': profile,
      if (userId != null) 'userId': userId,
      if (messages != null) 'messages': messages,
    };
    final data = await _postRequest('shortlist', body);
    return ShortlistResult.fromJson(data);
  }

  Future<Map<String, dynamic>?> getLatestShortlistChat(String userId) async {
    try {
      final data = await _getRequest('shortlist/$userId');
      if (data['success'] == true && data['chat'] != null) {
        return data['chat'];
      }
    } catch (e) {
      debugPrint('Error getting latest shortlist: $e');
    }
    return null;
  }

  Future<List<Map<String, String>>> searchGlobalUniversities(
    String query, {
    String degree = 'masters',
    String? country,
  }) async {
    final data = await _postRequest('search-universities', {
      'query': query,
      'degree': degree,
      'country': country,
    });
    final list = data['universities'] as List? ?? [];
    return list.map((e) {
      if (e is Map) {
        return e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {'name': e.toString()};
    }).toList();
  }

  Future<List<Map<String, String>>> searchUniversityCourses(
    String university,
    String query, {
    String degree = 'masters',
  }) async {
    final data = await _postRequest('search-courses', {
      'university': university,
      'query': query,
      'degree': degree,
    });
    final list = data['courses'] as List? ?? [];
    return list.map((e) {
      if (e is Map) {
        return e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {'name': e.toString()};
    }).toList();
  }

  Future<List<Map<String, String>>> searchCountries(String query) async {
    final data = await _postRequest('search-countries', {'query': query});
    final list = data['countries'] as List? ?? [];
    return list.map((e) {
      if (e is Map) {
        return e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {'name': e.toString()};
    }).toList();
  }

  Future<List<String>> searchFields(String query) async {
    final data = await _postRequest('search-fields', {'query': query});
    final list = data['fields'] as List? ?? [];
    return List<String>.from(list);
  }

  Future<LoanRecommendationResult> getLoanRecommendations(
    Map<String, dynamic> profile,
  ) async {
    final data = await _postRequest('loan-recommendations', profile);
    return LoanRecommendationResult.fromJson(data);
  }

  Future<String?> lookupPincode(String pincode) async {
    try {
      final data = await _postRequest('pincode-lookup', {'pincode': pincode});
      return data['address'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> pincodeLookup(String pincode) async {
    return lookupPincode(pincode);
  }

  Future<Map<String, dynamic>> startMockInterview(
    String university,
    String program,
  ) async {
    return await _postRequest('interview/start', {
      'university': university,
      'program': program,
    });
  }

  Future<Map<String, dynamic>> sendMockInterviewMessage(
    String sessionId,
    String message,
  ) async {
    return await _postRequest('interview/chat', {
      'sessionId': sessionId,
      'message': message,
    });
  }

  Future<Map<String, dynamic>> evaluateInterview(String sessionId) async {
    return await _postRequest('interview/evaluate', {'sessionId': sessionId});
  }

  // ── Visa Interview Simulator ──

  Future<VisaInterviewStartResponse> startVisaInterview(
    Map<String, dynamic> userProfile, [
    String visaType = 'F1 Student Visa',
  ]) async {
    final data = await _postRequest('visa-interview/start', {
      'userProfile': userProfile,
      'visaType': visaType,
    });
    return VisaInterviewStartResponse.fromJson(data);
  }

  Future<VisaInterviewContinueResponse> continueVisaInterview({
    required Map<String, dynamic> userProfile,
    required String previousQuestion,
    required String transcript,
    required String currentSection,
    required List<InterviewMessage> conversationHistory,
    String visaType = 'F1 Student Visa',
  }) async {
    final data = await _postRequest('visa-interview/continue', {
      'userProfile': userProfile,
      'visaType': visaType,
      'previousQuestion': previousQuestion,
      'transcript': transcript,
      'currentSection': currentSection,
      'conversationHistory': conversationHistory
          .map((e) => e.toJson())
          .toList(),
    });
    return VisaInterviewContinueResponse.fromJson(data);
  }

  Future<EvaluationResult> evaluateVisaAnswer({
    required String question,
    required String transcript,
    String visaType = 'F1 Student Visa',
  }) async {
    final data = await _postRequest('visa-interview/evaluate', {
      'question': question,
      'transcript': transcript,
      'visaType': visaType,
    });
    return EvaluationResult.fromJson(data['evaluation'] ?? data);
  }

  Future<String> getVisaFinalReport({
    required List<InterviewMessage> conversationHistory,
    required List<EvaluationResult> evaluations,
    String visaType = 'F1 Student Visa',
  }) async {
    final data = await _postRequest('visa-interview/final-report', {
      'conversationHistory': conversationHistory
          .map((e) => e.toJson())
          .toList(),
      'evaluations': evaluations.map((e) => e.toJson()).toList(),
      'visaType': visaType,
    });
    
    final reportData = data['report'];
    if (reportData is Map) {
      final buffer = StringBuffer();
      
      final score = reportData['overallScore'] ?? 'N/A';
      final risk = reportData['overallRisk'] ?? 'N/A';
      final likelihood = reportData['approvalLikelihood'] ?? 'N/A';
      final verdict = reportData['verdict'] ?? '';
      
      buffer.writeln('🎯 Overall Score: $score/100');
      buffer.writeln('⚠️ Risk Level: $risk');
      buffer.writeln('👍 Approval Likelihood: $likelihood');
      buffer.writeln();
      
      if (verdict.isNotEmpty) {
        buffer.writeln('📝 Consular Verdict:\n$verdict');
        buffer.writeln();
      }
      
      if (reportData['strengths'] is List && (reportData['strengths'] as List).isNotEmpty) {
        buffer.writeln('💪 Key Strengths:');
        for (var str in reportData['strengths']) {
          buffer.writeln('• $str');
        }
        buffer.writeln();
      }
      
      if (reportData['weaknesses'] is List && (reportData['weaknesses'] as List).isNotEmpty) {
        buffer.writeln('🥀 Weaknesses:');
        for (var weak in reportData['weaknesses']) {
          buffer.writeln('• $weak');
        }
        buffer.writeln();
      }
      
      if (reportData['criticalIssues'] is List && (reportData['criticalIssues'] as List).isNotEmpty) {
        buffer.writeln('🚨 Critical Issues:');
        for (var issue in reportData['criticalIssues']) {
          buffer.writeln('• $issue');
        }
        buffer.writeln();
      }
      
      if (reportData['ds160Inconsistencies'] is List && (reportData['ds160Inconsistencies'] as List).isNotEmpty) {
        buffer.writeln('❓ Inconsistencies:');
        for (var inc in reportData['ds160Inconsistencies']) {
          buffer.writeln('• $inc');
        }
        buffer.writeln();
      }
      
      if (reportData['tips'] is List && (reportData['tips'] as List).isNotEmpty) {
        buffer.writeln('💡 Tips for the Real Interview:');
        for (var tip in reportData['tips']) {
          buffer.writeln('• $tip');
        }
      }
      
      return buffer.toString().trim();
    }
    
    return reportData?.toString() ?? '';
  }

  // Saved Universities Persistence
  static const String _savedKey = 'saved_universities';

  Future<List<UniversityRecommendation>> getSavedUniversities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    // Try fetching from backend if user is logged in
    if (userId != null) {
      try {
        final data = await _getRequest('university/favorites/$userId');
        if (data is List) {
          final serverList = data
              .map(
                (json) =>
                    UniversityRecommendation.fromJson(json['universityData']),
              )
              .toList();

          // Update local cache to stay in sync
          await prefs.setString(
            _savedKey,
            jsonEncode(serverList.map((item) => item.toJson()).toList()),
          );
          return serverList;
        }
      } catch (e) {
        debugPrint('Error getting saved universities from backend: $e');
        // Let it fall through to local cache
      }
    }

    // Fallback to local cache
    final String? savedJson = prefs.getString(_savedKey);
    if (savedJson == null || savedJson.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(savedJson);
      return decoded
          .map((item) => UniversityRecommendation.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleSaveUniversity(UniversityRecommendation uni) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    if (userId == null) {
      // Fallback to local if not logged in
      final List<UniversityRecommendation> saved = await getSavedUniversities();
      final int index = saved.indexWhere((item) => item.name == uni.name);

      if (index != -1) {
        saved.removeAt(index);
      } else {
        saved.add(uni);
      }

      final String encoded = jsonEncode(
        saved.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_savedKey, encoded);
      return;
    }

    // Sync with backend
    try {
      final String baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/ai/university/favorite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'universityName': uni.name,
          'universityData': uni.toJson(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // We can still update local cache for offline/instant UI if needed,
        // but for now, let's rely on backend as source of truth.
        // To keep it simple, let's also update local.
        final List<UniversityRecommendation> saved =
            await getSavedUniversities();
        final int index = saved.indexWhere((item) => item.name == uni.name);
        final bool isSavedInDb = jsonDecode(response.body)['saved'] ?? false;

        if (isSavedInDb) {
          if (index == -1) saved.add(uni);
        } else {
          if (index != -1) saved.removeAt(index);
        }

        await prefs.setString(
          _savedKey,
          jsonEncode(saved.map((item) => item.toJson()).toList()),
        );
      }
    } catch (e) {
      debugPrint('Error toggling favorite on backend: $e');
    }
  }

  Future<bool> isUniversitySaved(String name) async {
    final List<UniversityRecommendation> saved = await getSavedUniversities();
    return saved.any((item) => item.name == name);
  }

  Future<void> trackUniversityView(UniversityRecommendation uni) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    try {
      final String baseUrl = await ApiConfig.getBaseUrl();
      await http.post(
        Uri.parse('$baseUrl/ai/university/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'universityName': uni.name,
          'programName': uni.programName,
          'location': uni.location,
        }),
      );
    } catch (e) {
      debugPrint('Error tracking university view: $e');
    }
  }

  Future<List<UniversityRecommendation>> getSavedAiRecommendations(
    String userId,
  ) async {
    try {
      final data = await _getRequest('shortlist/$userId');
      if (data['success'] == true && data['chat'] != null) {
        final chat = data['chat'];
        if (chat['recommendations'] != null) {
          final List<dynamic> list = chat['recommendations'];
          return list.map((e) => UniversityRecommendation.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting saved AI recommendations: $e');
    }
    return [];
  }
}
