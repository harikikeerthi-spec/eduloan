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
    try {
      final body = {
        'profile': profile,
        if (userId != null) 'userId': userId,
        if (messages != null) 'messages': messages,
      };
      final data = await _postRequest('shortlist', body);
      final result = ShortlistResult.fromJson(data);
      if (result.recommendations.isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('AI Shortlist API call error: $e. Using smart fallback.');
    }
    return _getFallbackShortlist(profile);
  }

  Future<ShortlistResult> evaluateShortlist(
    Map<String, dynamic> profile, {
    String? userId,
    List<Map<String, String>>? messages,
  }) async {
    try {
      final body = {
        'profile': profile,
        if (userId != null) 'userId': userId,
        if (messages != null) 'messages': messages,
      };
      final data = await _postRequest('shortlist', body);
      final result = ShortlistResult.fromJson(data);
      if (result.recommendations.isNotEmpty) {
        return result;
      }
    } catch (e) {
      debugPrint('AI Shortlist API call error: $e. Using smart fallback.');
    }
    return _getFallbackShortlist(profile);
  }

  ShortlistResult _getFallbackShortlist(Map<String, dynamic> profile) {
    final String country = (profile['country'] ?? 'USA').toString().trim();
    final String major = (profile['major'] ?? profile['bachelorCourse'] ?? 'Computer Science').toString().trim();
    final String gpa = (profile['gpa'] ?? '8.0').toString().trim();

    final Map<String, List<Map<String, dynamic>>> fallbackData = {
      'USA': [
        {
          'name': 'Northeastern University',
          'chance': 'High',
          'type': 'Target',
          'rank': '#44 US News',
          'tuition': '\$54,000/yr',
          'location': 'Boston, MA',
          'country': 'USA',
          'avgSalary': '\$92,000/yr',
          'deadline': 'Jan 15',
          'reason': 'Excellent co-op program with high post-grad employment rate for $major.',
          'programName': 'MS in $major',
          'logoUrl': 'https://logo.clearbit.com/northeastern.edu',
          'description': 'Top research university renowned for experiential learning.',
          'acceptanceRate': '18%',
          'duration': '2 Years',
          'roi': 'High',
          'theRank': '#168 THE',
          'costOfLiving': '\$18,000/yr',
          'websiteUrl': 'https://northeastern.edu',
        },
        {
          'name': 'University of Texas at Dallas',
          'chance': 'High',
          'type': 'Safe',
          'rank': '#115 US News',
          'tuition': '\$38,000/yr',
          'location': 'Richardson, TX',
          'country': 'USA',
          'avgSalary': '\$85,000/yr',
          'deadline': 'Feb 1',
          'reason': 'Located in Telecom Corridor tech hub, optimal fit for GPA $gpa.',
          'programName': 'MS in $major',
          'logoUrl': 'https://logo.clearbit.com/utdallas.edu',
          'description': 'Rapidly growing research university with strong corporate links.',
          'acceptanceRate': '79%',
          'duration': '2 Years',
          'roi': 'High',
          'theRank': '#351 THE',
          'costOfLiving': '\$12,000/yr',
          'websiteUrl': 'https://utdallas.edu',
        },
        {
          'name': 'Arizona State University',
          'chance': 'High',
          'type': 'Safe',
          'rank': '#105 US News',
          'tuition': '\$34,000/yr',
          'location': 'Tempe, AZ',
          'country': 'USA',
          'avgSalary': '\$82,000/yr',
          'deadline': 'Feb 15',
          'reason': 'Generous merit scholarship opportunities for STEM international candidates.',
          'programName': 'MS in $major',
          'logoUrl': 'https://logo.clearbit.com/asu.edu',
          'description': '#1 in Innovation, offering top-notch tech incubators.',
          'acceptanceRate': '88%',
          'duration': '2 Years',
          'roi': 'High',
          'theRank': '#182 THE',
          'costOfLiving': '\$13,000/yr',
          'websiteUrl': 'https://asu.edu',
        },
        {
          'name': 'University of Maryland, College Park',
          'chance': 'Med',
          'type': 'Ambitious',
          'rank': '#46 US News',
          'tuition': '\$42,000/yr',
          'location': 'College Park, MD',
          'country': 'USA',
          'avgSalary': '\$98,000/yr',
          'deadline': 'Dec 15',
          'reason': 'Premier public research institution near Washington D.C.',
          'programName': 'MS in $major',
          'logoUrl': 'https://logo.clearbit.com/umd.edu',
          'description': 'Flagship state university with renowned faculty.',
          'acceptanceRate': '44%',
          'duration': '2 Years',
          'roi': 'High',
          'theRank': '#104 THE',
          'costOfLiving': '\$15,000/yr',
          'websiteUrl': 'https://umd.edu',
        },
        {
          'name': 'University of Illinois Chicago',
          'chance': 'High',
          'type': 'Target',
          'rank': '#82 US News',
          'tuition': '\$31,000/yr',
          'location': 'Chicago, IL',
          'country': 'USA',
          'avgSalary': '\$88,000/yr',
          'deadline': 'Feb 15',
          'reason': 'Great urban location in Chicago with rich industry networks.',
          'programName': 'MS in $major',
          'logoUrl': 'https://logo.clearbit.com/uic.edu',
          'description': 'Major public research university offering abundant internships.',
          'acceptanceRate': '78%',
          'duration': '2 Years',
          'roi': 'High',
          'theRank': '#251 THE',
          'costOfLiving': '\$14,000/yr',
          'websiteUrl': 'https://uic.edu',
        },
      ],
      'UK': [
        {
          'name': 'University of Manchester',
          'chance': 'Med',
          'type': 'Target',
          'rank': '#32 QS Global',
          'tuition': '£28,000/yr',
          'location': 'Manchester',
          'country': 'UK',
          'avgSalary': '£45,000/yr',
          'deadline': 'Jan 31',
          'reason': 'Prestigious Russell Group university matching your profile.',
          'programName': 'MSc in $major',
          'logoUrl': 'https://logo.clearbit.com/manchester.ac.uk',
          'description': 'World-renowned institution with 25 Nobel laureates.',
          'acceptanceRate': '27%',
          'duration': '1 Year',
          'roi': 'High',
          'theRank': '#51 THE',
          'costOfLiving': '£12,000/yr',
          'websiteUrl': 'https://manchester.ac.uk',
        },
        {
          'name': 'University of Birmingham',
          'chance': 'High',
          'type': 'Safe',
          'rank': '#84 QS Global',
          'tuition': '£26,000/yr',
          'location': 'Birmingham',
          'country': 'UK',
          'avgSalary': '£42,000/yr',
          'deadline': 'Feb 28',
          'reason': 'Top targeted university by UK graduate employers.',
          'programName': 'MSc in $major',
          'logoUrl': 'https://logo.clearbit.com/bham.ac.uk',
          'description': 'Red brick university offering cutting-edge research facilities.',
          'acceptanceRate': '70%',
          'duration': '1 Year',
          'roi': 'High',
          'theRank': '#101 THE',
          'costOfLiving': '£11,000/yr',
          'websiteUrl': 'https://birmingham.ac.uk',
        },
      ],
      'Germany': [
        {
          'name': 'Technical University of Munich (TUM)',
          'chance': 'Med',
          'type': 'Ambitious',
          'rank': '#37 QS Global',
          'tuition': '€0 - €6,000/yr',
          'location': 'Munich',
          'country': 'Germany',
          'avgSalary': '€62,000/yr',
          'deadline': 'May 31',
          'reason': 'Top engineering & tech university in Europe with minimal tuition.',
          'programName': 'MSc in $major',
          'logoUrl': 'https://logo.clearbit.com/tum.de',
          'description': 'Germany\'s premier technical university located in Munich\'s tech hub.',
          'acceptanceRate': '25%',
          'duration': '2 Years',
          'roi': 'Very High',
          'theRank': '#30 THE',
          'costOfLiving': '€11,000/yr',
          'websiteUrl': 'https://tum.de',
        },
        {
          'name': 'RWTH Aachen University',
          'chance': 'High',
          'type': 'Target',
          'rank': '#106 QS Global',
          'tuition': '€0/yr (Tuition Free)',
          'location': 'Aachen',
          'country': 'Germany',
          'avgSalary': '€58,000/yr',
          'deadline': 'Jul 15',
          'reason': 'Zero tuition fee public university with elite industry partners.',
          'programName': 'MSc in $major',
          'logoUrl': 'https://logo.clearbit.com/rwth-aachen.de',
          'description': 'Largest technical university in Germany, famous for engineering.',
          'acceptanceRate': '50%',
          'duration': '2 Years',
          'roi': 'Very High',
          'theRank': '#90 THE',
          'costOfLiving': '€9,600/yr',
          'websiteUrl': 'https://rwth-aachen.de',
        },
      ],
    };

    final list = fallbackData[country] ?? fallbackData['USA']!;
    return ShortlistResult(
      recommendations: list.map((e) => UniversityRecommendation.fromJson(e)).toList(),
    );
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
    List<Map<String, String>> results = [];

    // 1. Try search-universities endpoint first
    try {
      final data = await _postRequest('search-universities', {
        'query': query,
        'degree': degree,
        'country': country,
      });
      final list = data['universities'] as List? ?? [];
      results = list.map<Map<String, String>>((e) {
        if (e is Map) {
          return Map<String, String>.from(
            e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
          );
        }
        return <String, String>{'name': e.toString()};
      }).toList();
    } catch (e) {
      debugPrint('Error calling search-universities: $e');
    }

    final queryLower = query.toLowerCase().trim();
    bool hasCloseMatch = results.any((uni) => (uni['name'] ?? '').toLowerCase().contains(queryLower));

    // 2. If no matching results, try the unified search endpoint
    if (!hasCloseMatch) {
      try {
        final data = await _postRequest('search', {
          'query': query,
          'type': 'university',
          'country': country,
          'degree': degree,
        });
        final list = data['universities'] as List? ?? data['results'] as List? ?? [];
        final unifiedResults = list.map<Map<String, String>>((e) {
          if (e is Map) {
            return Map<String, String>.from(
              e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
            );
          }
          return <String, String>{'name': e.toString()};
        }).toList();

        // Add unified results that are not already in results
        for (var uni in unifiedResults) {
          if (!results.any((r) => (r['name'] ?? '').toLowerCase() == (uni['name'] ?? '').toLowerCase())) {
            results.add(uni);
          }
        }
      } catch (e) {
        debugPrint('Error calling search fallback: $e');
      }
    }

    hasCloseMatch = results.any((uni) => (uni['name'] ?? '').toLowerCase().contains(queryLower));

    // 3. Fallback to public universities API (hipolabs) if still no exact/close match is found
    if (!hasCloseMatch && queryLower.length >= 3) {
      try {
        final encodedQuery = Uri.encodeComponent(query);
        String urlString = 'http://universities.hipolabs.com/search?name=$encodedQuery';
        if (country != null && country.trim().isNotEmpty) {
          final cLower = country.trim().toLowerCase();
          String hCountry;
          if (cLower == 'usa' || cLower == 'united states of america' || cLower == 'us') {
            hCountry = 'United States';
          } else if (cLower == 'uk' || cLower == 'united kingdom') {
            hCountry = 'United Kingdom';
          } else {
            hCountry = country.trim();
          }
          urlString += '&country=${Uri.encodeComponent(hCountry)}';
        }
        final url = Uri.parse(urlString);
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final List<dynamic> decoded = jsonDecode(response.body);
          final hipoResults = decoded.map<Map<String, String>>((e) {
            final name = e['name']?.toString() ?? '';
            final countryVal = e['country']?.toString() ?? '';
            final stateProvince = e['state-province']?.toString() ?? '';
            final location = stateProvince.isNotEmpty ? '$stateProvince, $countryVal' : countryVal;
            
            return <String, String>{
              'name': name,
              'country': countryVal,
              'location': location,
              'loc': location,
              'accept': '75', // Default placeholder
              'tuition': '25000', // Default placeholder
            };
          }).toList();

          // Add hipolabs results that are not already in results
          for (var uni in hipoResults) {
            if (!results.any((r) => (r['name'] ?? '').toLowerCase() == (uni['name'] ?? '').toLowerCase())) {
              results.add(uni);
            }
          }
        }
      } catch (e) {
        debugPrint('Error calling hipolabs fallback: $e');
      }
    }

    return results;
  }

  Future<List<Map<String, String>>> searchUniversityCourses(
    String university,
    String query, {
    String degree = 'masters',
  }) async {
    List<Map<String, String>> results = [];

    // 1. Try search-courses endpoint
    try {
      final data = await _postRequest('search-courses', {
        'university': university,
        'query': query,
        'degree': degree,
      });
      final list = data['courses'] as List? ?? [];
      results = list.map<Map<String, String>>((e) {
        if (e is Map) {
          return Map<String, String>.from(
            e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
          );
        }
        return <String, String>{'name': e.toString()};
      }).toList();
      if (results.isNotEmpty) return results;
    } catch (e) {
      debugPrint('Error calling search-courses: $e');
    }

    // 2. Try search endpoint with type 'course'
    try {
      final data = await _postRequest('search', {
        'query': query,
        'type': 'course',
        'context': {
          'university': university,
          'degree': degree,
        }
      });
      final list = data['results'] as List? ?? data['courses'] as List? ?? [];
      results = list.map<Map<String, String>>((e) {
        if (e is Map) {
          return Map<String, String>.from(
            e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
          );
        }
        return <String, String>{'name': e.toString()};
      }).toList();
      if (results.isNotEmpty) return results;
    } catch (e) {
      debugPrint('Error calling search endpoint for courses: $e');
    }

    // 3. Static fallback list of courses if both endpoints fail
    final bool isBachelors = degree.toLowerCase().contains('bachelor') || 
        degree.toLowerCase().contains('ug') || 
        degree.toLowerCase().contains('undergrad');
    
    final staticList = isBachelors 
      ? [
          'B.Tech Computer Science',
          'Bachelor of Business Administration (BBA)',
          'B.Sc Computer Science',
          'B.Tech Information Technology',
          'B.Sc Data Science & Analytics',
          'B.Tech Mechanical Engineering',
          'B.Tech Electrical Engineering',
          'B.Tech Biotechnology',
          'Bachelor of Commerce (B.Com)',
          'B.Sc Cybersecurity',
          'B.Tech Software Engineering',
          'B.Tech Civil Engineering',
          'B.Tech Chemical Engineering',
          'Bachelor of Architecture (B.Arch)',
          'Bachelor of Computer Applications (BCA)',
        ]
      : [
          'MS Computer Science',
          'MBA (Master of Business Administration)',
          'MS Data Science & Analytics',
          'MS Information Technology',
          'MS Business Analytics',
          'MS Mechanical Engineering',
          'MS Electrical Engineering',
          'MS Biotechnology',
          'Master of Public Health (MPH)',
          'MS Finance',
          'MS Cybersecurity & Information Assurance',
          'MS Software Engineering',
          'MS Civil Engineering',
          'MS Chemical Engineering',
          'MS Industrial Engineering',
          'MS Pharmacology & Toxicology',
          'MS Project Management',
          'MS Construction Management',
          'MS Supply Chain Management',
          'Master of Architecture',
        ];
    
    return staticList.map((name) => <String, String>{'name': name}).toList();
  }

  Future<List<Map<String, String>>> searchCountries(String query) async {
    try {
      final data = await _postRequest('search-countries', {'query': query});
      final list = data['countries'] as List? ?? [];
      return list.map<Map<String, String>>((e) {
        if (e is Map) {
          return Map<String, String>.from(
            e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
          );
        }
        return <String, String>{'name': e.toString()};
      }).toList();
    } catch (e) {
      debugPrint('Error searching countries from backend: $e. Falling back to popular list.');
      try {
        final data = await _getRequest('popular-countries');
        final list = data['countries'] as List? ?? [];
        final List<Map<String, String>> mapped = [];
        for (var item in list) {
          final name = item.toString();
          if (name.toLowerCase() == 'india') continue;
          mapped.add({
            'name': name,
            'code': _getCountryCode(name),
            'flag': _getCountryFlag(name),
          });
        }
        if (query.trim().isNotEmpty) {
          final q = query.toLowerCase();
          return mapped.where((c) => (c['name'] ?? '').toLowerCase().contains(q)).toList();
        }
        return mapped;
      } catch (innerEx) {
        debugPrint('Error fetching popular-countries: $innerEx. Using hardcoded fallback list.');
        final List<Map<String, String>> list = [
          {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
          {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
          {'name': 'Canada', 'code': 'CA', 'flag': '🇨🇦'},
          {'name': 'Australia', 'code': 'AU', 'flag': '🇦🇺'},
          {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
          {'name': 'France', 'code': 'FR', 'flag': '🇫🇷'},
          {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
          {'name': 'Ireland', 'code': 'IE', 'flag': '🇮🇪'},
          {'name': 'New Zealand', 'code': 'NZ', 'flag': '🇳🇿'},
          {'name': 'Netherlands', 'code': 'NL', 'flag': '🇳🇱'},
          {'name': 'Switzerland', 'code': 'CH', 'flag': '🇨🇭'},
          {'name': 'Sweden', 'code': 'SE', 'flag': '🇸🇪'},
          {'name': 'Spain', 'code': 'ES', 'flag': '🇪🇸'},
          {'name': 'Italy', 'code': 'IT', 'flag': '🇮🇹'},
        ];
        if (query.trim().isNotEmpty) {
          final q = query.toLowerCase();
          return list.where((c) => (c['name'] ?? '').toLowerCase().contains(q)).toList();
        }
        return list;
      }
    }
  }

  static String _getCountryFlag(String name) {
    const flags = {
      'united states': '🇺🇸',
      'united states of america': '🇺🇸',
      'usa': '🇺🇸',
      'united kingdom': '🇬🇧',
      'uk': '🇬🇧',
      'canada': '🇨🇦',
      'australia': '🇦🇺',
      'germany': '🇩🇪',
      'france': '🇫🇷',
      'singapore': '🇸🇬',
      'ireland': '🇮🇪',
      'new zealand': '🇳🇿',
      'netherlands': '🇳🇱',
      'switzerland': '🇨🇭',
      'sweden': '🇸🇪',
      'spain': '🇪🇸',
      'italy': '🇮🇹',
      'india': '🇮🇳',
      'china': '🇨🇳',
      'japan': '🇯🇵',
      'south korea': '🇰🇷',
      'malaysia': '🇲🇾',
      'united arab emirates': '🇦🇪',
      'uae': '🇦🇪',
      'russia': '🇷🇺'
    };
    final key = name.trim().toLowerCase();
    return flags[key] ?? '🌐';
  }

  static String _getCountryCode(String name) {
    const codes = {
      'united states': 'US',
      'united states of america': 'US',
      'usa': 'US',
      'united kingdom': 'GB',
      'uk': 'GB',
      'canada': 'CA',
      'australia': 'AU',
      'germany': 'DE',
      'france': 'FR',
      'singapore': 'SG',
      'ireland': 'IE',
      'new zealand': 'NZ',
      'netherlands': 'NL',
      'switzerland': 'CH',
      'sweden': 'SE',
      'spain': 'ES',
      'italy': 'IT',
      'india': 'IN',
      'china': 'CN',
      'japan': 'JP',
      'south korea': 'KR',
      'malaysia': 'MY',
      'united arab emirates': 'AE',
      'uae': 'AE',
      'russia': 'RU'
    };
    final key = name.trim().toLowerCase();
    return codes[key] ?? '';
  }

  Future<List<String>> searchFields(String query) async {
    try {
      final data = await _postRequest('search-fields', {'query': query});
      final list = data['fields'] as List? ?? [];
      return List<String>.from(list);
    } catch (e) {
      debugPrint('Error searching fields from backend: $e. Falling back to local list.');
      const List<String> list = [
        'Computer Science',
        'Data Science & Analytics',
        'Information Technology',
        'Business Administration (MBA)',
        'Finance & Accounting',
        'Marketing',
        'Management',
        'Mechanical Engineering',
        'Electrical & Electronics Engineering',
        'Civil Engineering',
        'Chemical Engineering',
        'Biotechnology',
        'Life Sciences',
        'Healthcare Administration',
        'Medicine & Nursing',
        'Psychology',
        'Economics',
        'Art & Design',
        'Architecture',
        'Law & Legal Studies',
        'Mathematics & Statistics',
        'Physics',
        'Chemistry',
        'Education',
        'Media & Communication',
        'Hospitality & Tourism',
      ];
      if (query.trim().isNotEmpty) {
        final q = query.toLowerCase();
        return list.where((f) => f.toLowerCase().contains(q)).toList();
      }
      return list;
    }
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

  Future<Map<String, dynamic>?> lookupPincodeDetails(String pincode) async {
    try {
      final data = await _postRequest('pincode-lookup', {'pincode': pincode});
      return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('Error looking up pincode details: $e');
    }
    return null;
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
    String agentType = 'agent_michael',
  ]) async {
    final data = await _postRequest('visa-interview/start', {
      'userProfile': userProfile,
      'visaType': visaType,
      'agentType': agentType,
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
    String agentType = 'agent_michael',
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
      'agentType': agentType,
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

  Future<Map<String, dynamic>> verifyUniversity(String name, String country) async {
    try {
      final data = await _postRequest('verify-university', {
        'name': name,
        'country': country,
      });
      return {
        'success': data['success'] ?? false,
        'isReal': data['isReal'] ?? false,
        'reason': data['reason'] ?? '',
      };
    } catch (e) {
      debugPrint('Error verifying university: $e');
      return {
        'success': false,
        'isReal': false,
        'reason': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyGroupTopic(String title, String topic) async {
    final text = '$title $topic'.toLowerCase();
    
    // Explicit blacklist of irrelevant / prohibited topics
    final banned = [
      'movie', 'torrent', 'pubg', 'free fire', 'game', 'gaming', 'crypto', 'bitcoin',
      'gambling', 'betting', 'gossip', 'dating', 'singles', 'casual', 'hack', 'crack',
      'mod apk', 'porn', 'adult', 'rumor'
    ];
    for (final b in banned) {
      if (text.contains(b)) {
        return {
          'isValid': false,
          'reason': 'Topic "$b" is irrelevant. Group topics must be related to study abroad, education, or loans.',
        };
      }
    }

    // Required domain keywords
    final allowedKeywords = [
      'study', 'abroad', 'university', 'uni', 'college', 'campus', 'admit', 'admission',
      'application', 'intake', 'fall', 'spring', 'summer', '2024', '2025', '2026', '2027',
      'loan', 'bank', 'hdfc', 'sbi', 'icici', 'axis', 'prodigy', 'mpower', 'nbfc', 'collateral',
      'interest', 'sanction', 'disburse', 'finance', 'budget', 'money', 'scholarship', 'grant',
      'visa', 'f1', 'j1', 'cas', 'i20', 'vfs', 'embassy', 'interview', 'consulate', 'passport',
      'gre', 'gmat', 'ielts', 'toefl', 'duolingo', 'sat', 'pte', 'exam', 'prep',
      'usa', 'us', 'uk', 'canada', 'germany', 'australia', 'ireland', 'france', 'europe', 'dallas',
      'boston', 'new york', 'london', 'toronto', 'munich', 'sydney', 'housing', 'roommate',
      'accommodation', 'flat', 'flight', 'travel', 'sop', 'lor', 'resume', 'cv', 'career',
      'internship', 'ta', 'ra', 'assistantship', 'student', 'aspirants', 'batch', 'group',
      'connect', 'meetup', 'discussion', 'advice', 'guidance', 'eduloan', 'vidyaloan'
    ];

    bool hasKeyword = allowedKeywords.any((k) => text.contains(k));
    if (hasKeyword) {
      return {'isValid': true, 'reason': 'Topic is relevant to study abroad & education loans.'};
    }

    // If keywords match didn't catch it, attempt AI backend endpoint check
    try {
      final data = await _postRequest('verify-group-topic', {
        'title': title,
        'topic': topic,
      });
      return {
        'isValid': data['isValid'] ?? false,
        'reason': data['reason'] ?? 'Topic must be related to study abroad, education, or loans.',
      };
    } catch (e) {
      return {
        'isValid': false,
        'reason': 'Group title/topic must be related to study abroad, education, or loans.',
      };
    }
  }
}
