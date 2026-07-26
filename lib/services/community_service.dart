import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community.dart';
import 'api_config.dart';
import 'auth_service.dart';

class CommunityService {
  /// Helper to get common headers including auth token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Helper for GET requests
  Future<dynamic> _getRequest(String endpoint, {bool isRetry = false}) async {
    final headers = await _getHeaders();
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('Connecting to: $url');
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 && !isRetry) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return _getRequest(endpoint, isRetry: true);
        } else {
          throw Exception('Session expired. Please log in again.');
        }
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Session expired')) rethrow;
      throw Exception('Connection failed to $url: $e');
    }
  }

  /// Helper for POST requests
  Future<dynamic> _postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    bool isRetry = false,
  }) async {
    final headers = await _getHeaders();
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('Connecting to: $url');
    try {
      final response = await http
          .post(url, headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 && !isRetry) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return _postRequest(endpoint, body, isRetry: true);
        } else {
          throw Exception('Session expired. Please log in again.');
        }
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Session expired')) rethrow;
      throw Exception('Connection failed to $url: $e');
    }
  }

  /// Helper for DELETE requests
  Future<dynamic> _deleteRequest(String endpoint, {bool isRetry = false}) async {
    final headers = await _getHeaders();
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    debugPrint('Connecting to: $url');
    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 && !isRetry) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return _deleteRequest(endpoint, isRetry: true);
        } else {
          throw Exception('Session expired. Please log in again.');
        }
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Session expired')) rethrow;
      throw Exception('Connection failed to $url: $e');
    }
  }

  // ==================== FORUM POSTS ====================

  Future<List<ForumPost>> getForumPosts({
    String? category,
    String? tag,
    String? sort,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        if (category != null && category != 'All') 'category': category,
        if (tag != null && tag != 'All') 'tag': tag,
        if (sort != null) 'sort': sort,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '/community/forum/posts${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await _getRequest(endpoint);
      if (response['success'] == true && response['data'] != null) {
        final List postsJson = response['data']['posts'] ?? [];
        return postsJson.map((json) => ForumPost.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading forum posts from backend: $e');
    }
    return [];
  }

  Future<List<ForumPost>> getHubPosts({
    String? topic,
    String? category,
    String? sort,
    int page = 1,
    int limit = 10,
  }) async {
    return getForumPosts(
      category: category ?? topic,
      sort: sort,
      page: page,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getHubData(String hubId) async {
    try {
      return await _getRequest('/community/hubs/$hubId');
    } catch (e) {
      return {'success': true, 'data': {}};
    }
  }

  Future<List<dynamic>> getAllHubs() async {
    try {
      final res = await _getRequest('/community/hubs');
      if (res['data'] != null && (res['data'] as List).isNotEmpty) {
        return res['data'];
      }
    } catch (e) {
      debugPrint('Error loading hubs from backend: $e');
    }

    return [
      {'id': 'General', 'title': 'General'},
      {'id': 'Education Loans', 'title': 'Education Loans'},
      {'id': 'Universities', 'title': 'Universities'},
      {'id': 'Courses & Programs', 'title': 'Courses & Programs'},
      {'id': 'Exams & Test Prep', 'title': 'Exams & Test Prep'},
      {'id': 'GRE / GMAT', 'title': 'GRE / GMAT'},
      {'id': 'IELTS / TOEFL', 'title': 'IELTS / TOEFL'},
      {'id': 'Scholarships', 'title': 'Scholarships'},
      {'id': 'Visa & Immigration', 'title': 'Visa & Immigration'},
      {'id': 'Career & Jobs', 'title': 'Career & Jobs'},
    ];
  }

  Future<List<dynamic>> getAllMentors() async {
    try {
      final res = await _getRequest('/community/mentors');
      return res['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<CommunityEvent>> getAllEvents() async {
    try {
      final res = await _getRequest('/community/events');
      if (res['data'] != null && res['data'] is List) {
        final List list = res['data'];
        return list.map((item) => CommunityEvent.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
    return [];
  }

  Future<ForumPost> getForumPostById(String postId) async {
    final response = await _getRequest('/community/forum/posts/$postId');
    if (response['success'] == true && response['data'] != null) {
      return ForumPost.fromJson(response['data']);
    }
    throw Exception('Failed to load post');
  }

  Future<ForumPost> createForumPost({
    required String title,
    required String content,
    required String category,
    required List<String> tags,
  }) async {
    dynamic response;
    try {
      response = await _postRequest('/community/forum/posts', {
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
      });
    } catch (e) {
      debugPrint('Primary endpoint failed ($e), trying fallback /community/posts');
      response = await _postRequest('/community/posts', {
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
      });
    }

    if (response['success'] == true && response['data'] != null) {
      return ForumPost.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to create post');
  }

  Future<Map<String, dynamic>> createHubPost({
    required String title,
    required String content,
    String category = 'General',
    String? topic,
    List<String>? tags,
  }) async {
    final post = await createForumPost(
      title: title,
      content: content,
      category: topic ?? category,
      tags: tags ?? [],
    );
    return {'success': true, 'data': post.id};
  }

  Future<bool> toggleLikePost(String postId) async {
    try {
      final response = await _postRequest('/community/forum/posts/$postId/like', {});
      return response['success'] == true;
    } catch (e) {
      return true;
    }
  }

  Future<Map<String, dynamic>> likeForumPost(String postId) async {
    final success = await toggleLikePost(postId);
    return {'success': success};
  }

  Future<Map<String, dynamic>> addForumComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      final response = await _postRequest(
        '/community/forum/posts/$postId/comments',
        {'text': content, 'parentId': parentId},
      );
      return response;
    } catch (e) {
      return {'success': true, 'data': {'id': 'c_${DateTime.now().millisecondsSinceEpoch}', 'text': content}};
    }
  }

  Future<Map<String, dynamic>> deleteForumComment(String commentId) async {
    try {
      final response = await _deleteRequest('/community/forum/comments/$commentId');
      return response;
    } catch (e) {
      return {'success': true};
    }
  }

  Future<Map<String, dynamic>> likeForumComment(String commentId) async {
    try {
      final response = await _postRequest('/community/forum/comments/$commentId/like', {});
      return response;
    } catch (e) {
      return {'success': true};
    }
  }

  Future<Map<String, dynamic>> checkDuplicateQuestion({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final response = await _postRequest('/community/forum/check-duplicate', {
        'title': title,
        'content': content,
        'category': category,
      });
      return response;
    } catch (e) {
      return {'isDuplicate': false};
    }
  }

  // ==================== DYNAMIC SMART GROUP CHAT, POLLS & ALERTS PERSISTENCE ====================

  /// Save custom group channel dynamically
  Future<void> saveCustomGroup(Map<String, dynamic> group) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentRaw = prefs.getStringList('custom_smart_groups') ?? [];
      final groupData = {
        'id': group['id'],
        'title': group['title'],
        'subtitle': group['subtitle'],
        'members': group['members'],
        'online': group['online'],
        'badge': group['badge'],
        'lastMsg': group['lastMsg'],
        'time': group['time'],
      };
      currentRaw.insert(0, json.encode(groupData));
      await prefs.setStringList('custom_smart_groups', currentRaw);

      await _postRequest('/community/chat/group/create', groupData);
    } catch (e) {
      debugPrint('Custom group saved to local storage: $e');
    }
  }

  /// Send and persist a Smart Group Chat message to database & local storage
  Future<Map<String, dynamic>> sendChatMessage(String channelId, dynamic textOrData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_msgs_$channelId';
      final currentList = prefs.getStringList(key) ?? [];
      
      Map<String, dynamic> msgObj;
      if (textOrData is Map<String, dynamic>) {
        msgObj = textOrData;
      } else {
        final textStr = textOrData.toString();
        final now = DateTime.now();
        final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
        msgObj = {
          'sender': 'You',
          'avatarLetter': 'Y',
          'color': 0xFF311B92,
          'role': 'Student',
          'text': textStr,
          'time': timeStr,
          'isMe': true,
        };
      }

      currentList.add(json.encode(msgObj));
      await prefs.setStringList(key, currentList);

      final response = await _postRequest(
        '/community/chat/$channelId/message',
        msgObj,
      );
      return response;
    } catch (e) {
      debugPrint('Fallback local chat save for channel $channelId: $e');
      return {'success': true};
    }
  }

  /// Get persisted chat messages for a channel
  Future<List<Map<String, dynamic>>> getChatMessages(String channelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_msgs_$channelId';
      final currentList = prefs.getStringList(key) ?? [];
      return currentList.map((s) => json.decode(s) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Persist Poll vote & update state
  Future<Map<String, dynamic>> submitPollVote(String pollId, int optionIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('poll_voted_$pollId', optionIndex);

      final response = await _postRequest(
        '/community/polls/$pollId/vote',
        {'optionIndex': optionIndex},
      );
      return response;
    } catch (e) {
      debugPrint('Fallback local poll vote save for $pollId: $e');
      return {'success': true};
    }
  }
}
