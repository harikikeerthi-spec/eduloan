import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // Compatibility getters for legacy code
  double get percentage => (analysis['percentage'] ?? score).toDouble();
  double get gpa => (analysis['gpa'] ?? score).toDouble();
  double get cgpa => (analysis['cgpa'] ?? score).toDouble();
  String get outputGrade => quality;

  factory GradeConversionResult.fromJson(Map<String, dynamic> json) {
    return GradeConversionResult(
      score: (json['score'] ?? 0).toDouble(),
      scale: json['scale'] ?? '',
      quality: json['quality'] ?? '',
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
      indianCommunity: json['indianCommunity'] ?? '',
      theRank: json['theRank'] ?? '',
      costOfLiving: json['costOfLiving'] ?? '',
      medianPackage: json['medianPackage'] ?? '',
      websiteUrl: json['websiteUrl'] ?? '',
      universityType: json['universityType'] ?? '',
      genderRatio: json['genderRatio'] ?? '',
      studentTeacherRatio: json['studentTeacherRatio'] ?? '',
      raceRatio: json['raceRatio'] ?? '',
      safetyStatus: json['safetyStatus'] ?? '',
      academicFocus: json['academicFocus'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      admissionProcess: List<String>.from(json['admissionProcess'] ?? []),
      testRequirements: Map<String, String>.from(
        json['testRequirements'] ?? {},
      ),
    );
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
    Map<String, dynamic> profile,
  ) async {
    final data = await _postRequest('shortlist', profile);
    return ShortlistResult.fromJson(data);
  }

  Future<ShortlistResult> evaluateShortlist(
    Map<String, dynamic> profile,
  ) async {
    final data = await _postRequest('shortlist', profile);
    return ShortlistResult.fromJson(data);
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
    return list.map((e) => Map<String, String>.from(e)).toList();
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
      if (e is Map) return Map<String, String>.from(e);
      return {'name': e.toString()};
    }).toList();
  }

  Future<List<Map<String, String>>> searchCountries(String query) async {
    final data = await _postRequest('search-countries', {'query': query});
    final list = data['countries'] as List? ?? [];
    return list.map((e) => Map<String, String>.from(e as Map)).toList();
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
}
