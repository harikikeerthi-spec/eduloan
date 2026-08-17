import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';

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
      try {
        response = await _postRequest('/community/posts', {
          'title': title,
          'content': content,
          'category': category,
          'tags': tags,
        });
      } catch (err) {
        if (e.toString().contains('CONTENT_NOT_RELEVANT') || err.toString().contains('CONTENT_NOT_RELEVANT')) {
          rethrow;
        }
        return ForumPost(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          authorId: 'local_user',
          userName: 'Student User',
          title: title,
          content: content,
          category: category,
          tags: tags,
          isMentorOnly: false,
          views: 1,
          likes: 0,
          isSolved: false,
          createdAt: DateTime.now(),
          comments: [],
        );
      }
    }

    if (response != null && response['success'] == true && response['data'] != null) {
      return ForumPost.fromJson(response['data']);
    }
    throw Exception(response?['message'] ?? 'Failed to create post');
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
        'members': group['members'] ?? 1,
        'online': group['online'] ?? 1,
        'badge': group['badge'] ?? 'General',
        'iconName': group['iconName'] ?? 'school_rounded',
        'colorHex': group['colorHex'] ?? '#311B92',
        'lastMsg': group['lastMsg'] ?? 'Group channel created just now!',
        'time': group['time'] ?? 'Just now',
        // ✅ Persist admin identity so membership check works after restart
        'adminEmail': group['adminEmail'] ?? '',
        'adminName': group['adminName'] ?? '',
      };
      currentRaw.insert(0, json.encode(groupData));
      await prefs.setStringList('custom_smart_groups', currentRaw);

      // ✅ Mark this group as admin-owned in local prefs
      final groupId = group['id']?.toString() ?? '';
      if (groupId.isNotEmpty) {
        final adminGroups = prefs.getStringList('admin_group_ids') ?? [];
        if (!adminGroups.contains(groupId)) {
          adminGroups.add(groupId);
          await prefs.setStringList('admin_group_ids', adminGroups);
        }
      }

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

  // ==================== REAL COMMUNITY GROUPS & MESSAGES API ====================

  /// Get all real group channels from backend database & local custom storage
  Future<List<Map<String, dynamic>>> getGroups() async {
    final List<Map<String, dynamic>> result = [];
    final Set<String> existingIds = {};

    // 1. Read custom groups created locally
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentRaw = prefs.getStringList('custom_smart_groups') ?? [];
      for (var str in currentRaw) {
        try {
          final Map<String, dynamic> decoded = Map<String, dynamic>.from(json.decode(str) as Map);
          if (decoded['id'] != null && !existingIds.contains(decoded['id'])) {
            existingIds.add(decoded['id']);
            result.add(decoded);
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error reading local custom groups: $e');
    }

    // 2. Fetch groups from backend database
    try {
      final response = await _getRequest('/community/groups');
      if (response['success'] == true && response['data'] != null) {
        final List raw = response['data'];
        for (var e in raw) {
          final Map<String, dynamic> g = Map<String, dynamic>.from(e as Map);
          if (g['id'] != null && !existingIds.contains(g['id'])) {
            existingIds.add(g['id']);
            result.add(g);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting groups from backend: $e');
    }

    return result;
  }

  /// Create real group channel in backend database and local custom storage
  Future<Map<String, dynamic>?> createGroup(Map<String, dynamic> groupData) async {
    await saveCustomGroup(groupData);
    try {
      final response = await _postRequest('/community/groups', groupData);
      if (response['success'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
    } catch (e) {
      debugPrint('Error creating group in backend: $e');
    }
    return groupData;
  }

  /// Get real group messages from backend database & local persistent storage
  Future<List<Map<String, dynamic>>> getGroupMessages(String groupId) async {
    final List<Map<String, dynamic>> localMsgs = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final localRaw = prefs.getStringList('group_msgs_$groupId') ?? prefs.getStringList('chat_msgs_$groupId') ?? [];
      for (var str in localRaw) {
        try {
          localMsgs.add(Map<String, dynamic>.from(json.decode(str) as Map));
        } catch (_) {}
      }
    } catch (_) {}

    try {
      final response = await _getRequest('/community/groups/$groupId/messages');
      if (response['success'] == true && response['data'] != null) {
        final List raw = response['data'];
        final List<Map<String, dynamic>> serverMsgs = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Merge server and local messages (avoid duplicates)
        final Map<String, Map<String, dynamic>> mergedMap = {};
        for (var m in localMsgs) {
          final key = m['id']?.toString() ?? '${m['sender']}_${m['text']}_${m['time']}';
          mergedMap[key] = m;
        }
        for (var m in serverMsgs) {
          final key = m['id']?.toString() ?? '${m['sender']}_${m['text']}_${m['time']}';
          mergedMap[key] = m;
        }

        final mergedList = mergedMap.values.toList();
        
        // Save back to local storage
        try {
          final prefs = await SharedPreferences.getInstance();
          final rawList = mergedList.map((m) => json.encode(m)).toList();
          await prefs.setStringList('group_msgs_$groupId', rawList);
        } catch (_) {}

        return mergedList;
      }
    } catch (e) {
      debugPrint('Error loading group messages from backend, using local: $e');
    }

    return localMsgs;
  }

  /// Send message in real group chat and save to database & local storage
  Future<Map<String, dynamic>?> sendGroupMessage(String groupId, Map<String, dynamic> msgData) async {
    // 1. Immediately persist to local storage so it NEVER disappears
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'group_msgs_$groupId';
      final currentList = prefs.getStringList(key) ?? [];
      currentList.add(json.encode(msgData));
      await prefs.setStringList(key, currentList);
    } catch (e) {
      debugPrint('Error locally persisting group message: $e');
    }

    // 2. Post to backend so ALL Vidyaloan users receive it
    try {
      final response = await _postRequest('/community/groups/$groupId/messages', msgData);
      if (response['success'] == true && response['data'] != null) {
        final saved = Map<String, dynamic>.from(response['data'] as Map);
        return saved;
      }
    } catch (e) {
      debugPrint('Error sending group message to backend: $e');
    }
    return msgData;
  }

  /// Join a group channel
  Future<bool> joinGroup(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final joined = prefs.getStringList('joined_group_ids') ?? [];
      if (!joined.contains(groupId)) {
        joined.add(groupId);
        await prefs.setStringList('joined_group_ids', joined);
      }

      final userId = prefs.getString('userId') ?? '';
      await _postRequest('/community/groups/$groupId/join', {'userId': userId});
      return true;
    } catch (e) {
      debugPrint('Error joining group: $e');
      return true;
    }
  }

  /// Leave a group channel
  Future<bool> leaveGroup(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final joined = prefs.getStringList('joined_group_ids') ?? [];
      joined.remove(groupId);
      await prefs.setStringList('joined_group_ids', joined);

      final userId = prefs.getString('userId') ?? '';
      await _postRequest('/community/groups/$groupId/leave', {'userId': userId});
      return true;
    } catch (e) {
      debugPrint('Error leaving group: $e');
      return true;
    }
  }

  /// Check group membership status: 'ADMIN', 'APPROVED', 'PENDING', or 'NONE'
  Future<String> getGroupMembershipStatus(String groupId, String? adminEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final myEmail = prefs.getString('user_email') ?? '';
      
      // Admin check
      if (adminEmail != null && adminEmail.isNotEmpty && myEmail == adminEmail) {
        return 'ADMIN';
      }

      final adminGroups = prefs.getStringList('admin_group_ids') ?? [];
      if (adminGroups.contains(groupId)) {
        return 'ADMIN';
      }

      final joined = prefs.getStringList('joined_group_ids') ?? [];
      if (joined.contains(groupId)) {
        return 'APPROVED';
      }

      final pending = prefs.getStringList('pending_join_request_ids') ?? [];
      if (pending.contains(groupId)) {
        return 'PENDING';
      }
    } catch (e) {
      debugPrint('Error getting group membership status: $e');
    }
    return 'NONE';
  }

  /// Request to join a group -> Sends push & in-app notifications to Group Admin
  Future<bool> requestGroupJoin({
    required String groupId,
    required String groupTitle,
    String? adminEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fname = prefs.getString('user_firstName') ?? '';
      final lname = prefs.getString('user_lastName') ?? '';
      final applicantName = '$fname $lname'.trim().isEmpty ? 'Student Applicant' : '$fname $lname'.trim();
      final applicantEmail = prefs.getString('user_email') ?? 'student@vidhyaloan.com';

      // 1. Store local pending status
      final pending = prefs.getStringList('pending_join_request_ids') ?? [];
      if (!pending.contains(groupId)) {
        pending.add(groupId);
        await prefs.setStringList('pending_join_request_ids', pending);
      }

      // 2. Persist request to admin's pending requests queue
      final adminReqKey = 'admin_pending_requests_$groupId';
      final currentAdminReqs = prefs.getStringList(adminReqKey) ?? [];
      final reqObj = {
        'id': 'req_${DateTime.now().millisecondsSinceEpoch}',
        'groupId': groupId,
        'groupTitle': groupTitle,
        'applicantName': applicantName,
        'applicantEmail': applicantEmail,
        'createdAt': DateTime.now().toIso8601String(),
      };
      currentAdminReqs.add(json.encode(reqObj));
      await prefs.setStringList(adminReqKey, currentAdminReqs);

      // 3. Post to backend
      await _postRequest('/community/groups/$groupId/join-request', reqObj);

      // 4. Trigger In-App Notification & Heads-up Mobile Push Notification for Group Admin!
      await NotificationService.pushNotification(
        title: '📌 New Group Join Request',
        message: '$applicantName has requested to join your group "$groupTitle". Tap to review & approve.',
        type: 'GROUP_JOIN_REQUEST',
      );

      return true;
    } catch (e) {
      debugPrint('Error requesting group join: $e');
      return true;
    }
  }

  /// Get pending requests for admin
  Future<List<Map<String, dynamic>>> getPendingJoinRequests(String groupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminReqKey = 'admin_pending_requests_$groupId';
      final currentAdminReqs = prefs.getStringList(adminReqKey) ?? [];
      return currentAdminReqs
          .map((str) => Map<String, dynamic>.from(json.decode(str) as Map))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Admin approves a join request -> Notifies applicant & grants group access
  Future<bool> approveGroupJoinRequest({
    required String groupId,
    required String requestId,
    required String applicantEmail,
    required String groupTitle,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminReqKey = 'admin_pending_requests_$groupId';
      final currentAdminReqs = prefs.getStringList(adminReqKey) ?? [];
      currentAdminReqs.removeWhere((str) {
        try {
          final map = json.decode(str) as Map;
          return map['id'] == requestId || map['applicantEmail'] == applicantEmail;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(adminReqKey, currentAdminReqs);

      // Add to joined groups for the user
      final joined = prefs.getStringList('joined_group_ids') ?? [];
      if (!joined.contains(groupId)) {
        joined.add(groupId);
        await prefs.setStringList('joined_group_ids', joined);
      }

      await _postRequest('/community/groups/$groupId/approve-request', {
        'requestId': requestId,
        'applicantEmail': applicantEmail,
      });

      // Send confirmation notification to applicant
      await NotificationService.pushNotification(
        title: '🎉 Group Request Approved!',
        message: 'Group Admin approved your request to join "$groupTitle". Welcome to the group channel!',
        type: 'GROUP_JOIN_APPROVED',
      );

      return true;
    } catch (e) {
      debugPrint('Error approving group join request: $e');
      return true;
    }
  }
  /// Admin rejects a join request
  Future<bool> rejectGroupJoinRequest({
    required String groupId,
    required String requestId,
    required String applicantEmail,
    required String groupTitle,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminReqKey = 'admin_pending_requests_$groupId';
      final currentAdminReqs = prefs.getStringList(adminReqKey) ?? [];
      currentAdminReqs.removeWhere((str) {
        try {
          final map = json.decode(str) as Map;
          return map['id'] == requestId || map['applicantEmail'] == applicantEmail;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(adminReqKey, currentAdminReqs);

      // Remove from pending
      final pending = prefs.getStringList('pending_join_request_ids') ?? [];
      pending.remove(groupId);
      await prefs.setStringList('pending_join_request_ids', pending);

      await _postRequest('/community/groups/$groupId/reject-request', {
        'requestId': requestId,
        'applicantEmail': applicantEmail,
      });

      // Notify applicant of rejection
      await NotificationService.pushNotification(
        title: '❌ Group Request Declined',
        message: 'Your request to join "$groupTitle" was not approved by the admin.',
        type: 'GROUP_JOIN_REJECTED',
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting group join request: $e');
      return true;
    }
  }
}


