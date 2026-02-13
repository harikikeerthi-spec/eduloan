import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/community.dart';

class CommunityService {
  static const List<String> _baseUrls = [
    'http://127.0.0.1:3000', // 1. Localhost (ADB Reverse) - Most reliable
    'http://10.0.2.2:3000', // 2. Android Emulator
    'http://192.168.1.19:3000', // 3. LAN IP
  ];

  /// Helper for GET requests
  Future<dynamic> _getRequest(String endpoint) async {
    String lastError = 'Unknown error';
    for (String baseUrl in _baseUrls) {
      final url = Uri.parse('$baseUrl$endpoint');
      print('Trying to connect to: $url');
      try {
        print('Fetching: $url');
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return json.decode(response.body);
        } else {
          lastError = 'Status ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = e.toString();
        print('Error connecting to $baseUrl: $e');
        print('Detailed error for $baseUrl: $e');
      }
    }
    throw Exception('Connection failed: $lastError');
  }

  /// Helper for POST requests
  Future<dynamic> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    String lastError = 'Unknown error';
    for (String baseUrl in _baseUrls) {
      final url = Uri.parse('$baseUrl$endpoint');
      print('Trying to POST to: $url');
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return json.decode(response.body);
        } else {
          lastError = 'Status ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = e.toString();
        print('Error connecting to $baseUrl: $e');
      }
    }
    throw Exception('Connection failed: $lastError');
  }

  // ==================== MENTORS ====================

  Future<List<Mentor>> getAllMentors({
    String? university,
    String? country,
    String? loanType,
    String? category,
    int limit = 10,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (university != null) query += '&university=$university';
    if (country != null) query += '&country=$country';
    if (loanType != null) query += '&loanType=$loanType';
    if (category != null) query += '&category=$category';

    final response = await _getRequest('/community/mentors$query');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => Mentor.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<Mentor> getMentorById(String id) async {
    final response = await _getRequest('/community/mentors/$id');
    if (response['success'] == true) {
      return Mentor.fromJson(response['data']);
    }
    throw Exception('Mentor not found');
  }

  Future<Map<String, dynamic>> bookMentorSession({
    required String mentorId,
    required String studentName,
    required String studentEmail,
    String? studentPhone,
    required String preferredDate,
    required String preferredTime,
    String? message,
  }) async {
    final response = await _postRequest('/community/mentors/$mentorId/book', {
      'studentName': studentName,
      'studentEmail': studentEmail,
      if (studentPhone != null) 'studentPhone': studentPhone,
      'preferredDate': preferredDate,
      'preferredTime': preferredTime,
      if (message != null) 'message': message,
    });
    return response;
  }

  // ==================== EVENTS ====================

  Future<List<CommunityEvent>> getAllEvents({
    String? type,
    String? category,
    int limit = 10,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (type != null) query += '&type=$type';
    if (category != null) query += '&category=$category';

    final response = await _getRequest('/community/events$query');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => CommunityEvent.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<CommunityEvent>> getUpcomingEvents({int limit = 5}) async {
    final response = await _getRequest(
      '/community/events/upcoming?limit=$limit',
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => CommunityEvent.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<CommunityEvent> getEventById(String id) async {
    final response = await _getRequest('/community/events/$id');
    if (response['success'] == true) {
      return CommunityEvent.fromJson(response['data']);
    }
    throw Exception('Event not found');
  }

  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    required String name,
    required String email,
    String? phone,
  }) async {
    final response = await _postRequest('/community/events/$eventId/register', {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
    });
    return response;
  }

  // ==================== SUCCESS STORIES ====================

  Future<List<SuccessStory>> getAllStories({
    String? country,
    String? category,
    int limit = 10,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (country != null) query += '&country=$country';
    if (category != null) query += '&category=$category';

    final response = await _getRequest('/community/stories$query');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => SuccessStory.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<SuccessStory> getStoryById(String id) async {
    final response = await _getRequest('/community/stories/$id');
    if (response['success'] == true) {
      return SuccessStory.fromJson(response['data']);
    }
    throw Exception('Story not found');
  }

  Future<Map<String, dynamic>> submitSuccessStory({
    required String name,
    required String email,
    required String university,
    required String country,
    required String degree,
    required String loanAmount,
    required String bank,
    String? interestRate,
    required String story,
    String? tips,
    String? image,
  }) async {
    final response = await _postRequest('/community/stories/submit', {
      'name': name,
      'email': email,
      'university': university,
      'country': country,
      'degree': degree,
      'loanAmount': loanAmount,
      'bank': bank,
      if (interestRate != null) 'interestRate': interestRate,
      'story': story,
      if (tips != null) 'tips': tips,
      if (image != null) 'image': image,
    });
    return response;
  }

  // ==================== FORUM ====================

  Future<List<ForumPost>> getForumPosts({
    String? category,
    String? tag,
    int limit = 10,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (category != null) query += '&category=$category';
    if (tag != null) query += '&tag=$tag';

    final response = await _getRequest('/community/forum$query');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => ForumPost.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<ForumPost> getForumPostById(String id) async {
    final response = await _getRequest('/community/forum/$id');
    if (response['success'] == true) {
      return ForumPost.fromJson(response['data']);
    }
    throw Exception('Post not found');
  }

  Future<Map<String, dynamic>> likeForumPost(String id) async {
    final response = await _postRequest('/community/forum/$id/like', {});
    return response;
  }

  Future<Map<String, dynamic>> addForumComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final response = await _postRequest('/community/forum/$postId/comments', {
      'content': content,
      if (parentId != null) 'parentId': parentId,
    });
    return response;
  }

  // ==================== RESOURCES ====================

  Future<List<CommunityResource>> getAllResources({
    String? type,
    String? category,
    int limit = 10,
    int offset = 0,
  }) async {
    String query = '?limit=$limit&offset=$offset';
    if (type != null) query += '&type=$type';
    if (category != null) query += '&category=$category';

    final response = await _getRequest('/community/resources$query');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => CommunityResource.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<CommunityResource>> getPopularResources({int limit = 5}) async {
    final response = await _getRequest(
      '/community/resources/popular?limit=$limit',
    );
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => CommunityResource.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<CommunityResource> getResourceById(String id) async {
    final response = await _getRequest('/community/resources/$id');
    if (response['success'] == true) {
      return CommunityResource.fromJson(response['data']);
    }
    throw Exception('Resource not found');
  }

  Future<Map<String, dynamic>> trackResourceDownload(String resourceId) async {
    final response = await _postRequest(
      '/community/resources/$resourceId/track',
      {},
    );
    return response;
  }
}
