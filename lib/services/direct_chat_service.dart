import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class DirectChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  DirectChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });

  /// Phone number masking logic: converts any 10-digit or formatted phone number to XXXXXXXXXX for recipient
  static String maskPhoneNumbers(String input) {
    if (input.isEmpty) return input;
    // Matches 10-digit numbers, numbers with +91/91 prefix, and space/dash formatted 10 digit numbers
    final RegExp phoneRegex = RegExp(
      r'(?:\+?91[\s\.-]?)?(?:[0-9]{10}|[0-9]{5}[\s\.-][0-9]{5}|[0-9]{3}[\s\.-][0-9]{3}[\s\.-][0-9]{4}|[6-9][0-9]{9})',
    );
    return input.replaceAllMapped(phoneRegex, (match) => 'XXXXXXXXXX');
  }

  /// Get display text (masked if received message and contains phone numbers)
  String get displayText {
    if (isMe) {
      // Show masked if user sent phone number to enforce policy, or keep masked for display
      return maskPhoneNumbers(text);
    }
    return maskPhoneNumbers(text);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isMe': isMe,
  };

  factory DirectChatMessage.fromJson(Map<String, dynamic> json) =>
      DirectChatMessage(
        id: json['id'] ?? '',
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        text: json['text'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        isMe: json['isMe'] ?? false,
      );
}

class DirectChatConversation {
  final String peerId;
  final String peerName;
  final String peerRole;
  final String avatarLetter;
  final int colorValue;
  final bool isOnline;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;
  final List<DirectChatMessage> messages;

  DirectChatConversation({
    required this.peerId,
    required this.peerName,
    required this.peerRole,
    required this.avatarLetter,
    required this.colorValue,
    required this.isOnline,
    required this.lastMessage,
    required this.lastTimestamp,
    this.unreadCount = 0,
    required this.messages,
  });

  String get maskedLastMessage =>
      DirectChatMessage.maskPhoneNumbers(lastMessage);

  Map<String, dynamic> toJson() => {
    'peerId': peerId,
    'peerName': peerName,
    'peerRole': peerRole,
    'avatarLetter': avatarLetter,
    'colorValue': colorValue,
    'isOnline': isOnline,
    'lastMessage': lastMessage,
    'lastTimestamp': lastTimestamp.toIso8601String(),
    'unreadCount': unreadCount,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory DirectChatConversation.fromJson(Map<String, dynamic> json) =>
      DirectChatConversation(
        peerId: json['peerId'] ?? '',
        peerName: json['peerName'] ?? '',
        peerRole: json['peerRole'] ?? 'Student',
        avatarLetter:
            json['avatarLetter'] ??
            (json['peerName'] != null && (json['peerName'] as String).isNotEmpty
                ? json['peerName'][0]
                : 'U'),
        colorValue: json['colorValue'] ?? 0xFF311B92,
        isOnline: json['isOnline'] ?? true,
        lastMessage: json['lastMessage'] ?? '',
        lastTimestamp:
            DateTime.tryParse(json['lastTimestamp'] ?? '') ?? DateTime.now(),
        unreadCount: json['unreadCount'] ?? 0,
        messages:
            (json['messages'] as List<dynamic>?)
                ?.map(
                  (m) => DirectChatMessage.fromJson(m as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}

class DirectChatService {
  static final DirectChatService _instance = DirectChatService._internal();
  factory DirectChatService() => _instance;
  DirectChatService._internal();

  static const String _storageKey = 'p2p_direct_chats_v1';

  final Map<String, DirectChatConversation> _conversations = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = json.decode(raw);
        for (var item in list) {
          final conv = DirectChatConversation.fromJson(
            item as Map<String, dynamic>,
          );
          _conversations[conv.peerId] = conv;
        }
      }
    } catch (e) {
      debugPrint('Error loading direct chats: $e');
    }

    // Filter out legacy mock conversations if present
    _conversations.remove('peer_rohan_101');
    _conversations.remove('peer_priya_102');
    _conversations.remove('peer_arun_103');
    await _saveToStorage();
    _initialized = true;
  }

  String _normalizeId(String id) {
    if (id.isEmpty) return '';
    return id.toLowerCase().trim().replaceAll(RegExp(r'^(peer_|user_)'), '');
  }

  bool _isSameUser(String? id1, String? id2) {
    if (id1 == null || id2 == null) return false;
    if (id1 == id2) return true;
    return _normalizeId(id1) == _normalizeId(id2);
  }

  Future<String> getMyUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('userId') ?? prefs.getString('user_id') ?? prefs.getString('id');
      if (id != null && id.isNotEmpty) return id;
      final email = prefs.getString('user_email') ?? prefs.getString('email');
      if (email != null && email.isNotEmpty) {
        return 'user_${email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      }
      final phone = prefs.getString('user_phone') ?? prefs.getString('phone');
      if (phone != null && phone.isNotEmpty) {
        return 'user_${phone.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      }
      final fname = prefs.getString('user_firstName') ?? prefs.getString('firstName') ?? prefs.getString('user_name') ?? prefs.getString('name') ?? '';
      final lname = prefs.getString('user_lastName') ?? prefs.getString('lastName') ?? '';
      final fullName = '$fname $lname'.trim();
      if (fullName.isNotEmpty) {
        return 'user_${fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
      }

      var guestId = prefs.getString('persistent_chat_user_id');
      if (guestId == null || guestId.isEmpty) {
        guestId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('persistent_chat_user_id', guestId);
      }
      return guestId;
    } catch (_) {
      return 'user_me';
    }
  }

  Future<String> getMyUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fname = prefs.getString('user_firstName') ?? prefs.getString('firstName') ?? prefs.getString('user_name') ?? prefs.getString('name') ?? '';
      final lname = prefs.getString('user_lastName') ?? prefs.getString('lastName') ?? '';
      final fullName = '$fname $lname'.trim();
      if (fullName.isNotEmpty) return fullName;
      final email = prefs.getString('user_email') ?? prefs.getString('email');
      if (email != null && email.isNotEmpty) {
        return email.split('@')[0];
      }
      return 'Student';
    } catch (_) {
      return 'Student';
    }
  }

  String getConversationId(String myId, String peerId) {
    final norm1 = _normalizeId(myId);
    final norm2 = _normalizeId(peerId);
    final p1 = norm1.compareTo(norm2) < 0 ? norm1 : norm2;
    final p2 = norm1.compareTo(norm2) < 0 ? norm2 : norm1;
    return 'conv_${p1}_$p2';
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _conversations.values.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(list));
    } catch (e) {
      debugPrint('Error saving direct chats: $e');
    }
  }

  Future<List<DirectChatConversation>> getConversations() async {
    await init();
    final myId = await getMyUserId();

    // Fetch latest conversations from backend server
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/community/direct-chats?userId=$myId'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List rawList = decoded['data'];
          for (var item in rawList) {
            final Map<String, dynamic> c = Map<String, dynamic>.from(
              item as Map,
            );
            final String peerId = c['peerId']?.toString() ??
                (c['participant1Id'] == myId
                    ? c['participant2Id']
                    : c['participant1Id']) ??
                '';
            if (peerId.isEmpty || _isSameUser(peerId, myId)) continue;

            final existing = _conversations[peerId];
            final lastMsg = c['lastMessage'] ?? existing?.lastMessage ?? '';
            final lastTime =
                DateTime.tryParse(
                  c['lastMessageAt'] ?? c['lastTimestamp'] ?? '',
                )?.toLocal() ??
                existing?.lastTimestamp ??
                DateTime.now();

            _conversations[peerId] = DirectChatConversation(
              peerId: peerId,
              peerName: c['peerName'] ?? existing?.peerName ?? 'Student Member',
              peerRole: c['peerRole'] ?? existing?.peerRole ?? 'Student',
              avatarLetter: c['avatarLetter'] ?? existing?.avatarLetter ?? (c['peerName'] != null && c['peerName'].toString().isNotEmpty ? c['peerName'].toString()[0].toUpperCase() : 'S'),
              colorValue: c['colorValue'] ?? existing?.colorValue ?? 0xFF311B92,
              isOnline: c['isOnline'] ?? existing?.isOnline ?? true,
              lastMessage: lastMsg,
              lastTimestamp: lastTime,
              unreadCount: (c['unreadCount'] is int)
                  ? c['unreadCount']
                  : (existing?.unreadCount ?? 0),
              messages: existing?.messages ?? [],
            );
          }
          await _saveToStorage();
        }
      }
    } catch (e) {
      debugPrint('Error syncing direct conversations from server: $e');
    }

    final list = _conversations.values.toList();
    list.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
    return list;
  }

  Future<DirectChatConversation> getOrCreateConversation({
    required String peerId,
    required String peerName,
    String? peerRole,
    String? avatarLetter,
    int? colorValue,
  }) async {
    await init();
    if (_conversations.containsKey(peerId)) {
      return _conversations[peerId]!;
    }

    final letter = (avatarLetter != null && avatarLetter.isNotEmpty)
        ? avatarLetter
        : (peerName.isNotEmpty ? peerName[0].toUpperCase() : 'U');

    final newConv = DirectChatConversation(
      peerId: peerId,
      peerName: peerName,
      peerRole: peerRole ?? 'Student Member',
      avatarLetter: letter,
      colorValue: colorValue ?? 0xFF311B92,
      isOnline: true,
      lastMessage: 'Chat started',
      lastTimestamp: DateTime.now(),
      unreadCount: 0,
      messages: [],
    );

    _conversations[peerId] = newConv;
    await _saveToStorage();
    return newConv;
  }

  /// Get real-time messages for a peer conversation from backend + local cache
  Future<List<DirectChatMessage>> getMessagesForPeer(String peerId) async {
    await init();
    final conv = _conversations[peerId];
    final localMsgs = conv?.messages ?? [];
    final myId = await getMyUserId();
    final conversationId = getConversationId(myId, peerId);

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/community/direct-chats/$conversationId/messages?userId=$myId',
            ),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['data'] is List) {
          final List rawList = decoded['data'];
          final List<DirectChatMessage> serverMsgs = rawList.map((m) {
            final senderId = m['senderId']?.toString() ?? '';
            final isMe = _isSameUser(senderId, myId) || m['isMe'] == true;
            return DirectChatMessage(
              id: m['id']?.toString() ?? '',
              senderId: senderId,
              senderName:
                  m['senderName'] ??
                  (isMe ? 'You' : (conv?.peerName ?? 'Student')),
              text: m['text'] ?? m['content'] ?? '',
              timestamp:
                  DateTime.tryParse(m['timestamp'] ?? m['createdAt'] ?? '')?.toLocal() ??
                  DateTime.now(),
              isMe: isMe,
            );
          }).toList();

          // Smart merge and deduplication
          final Map<String, DirectChatMessage> mergedMap = {};
          final allMessages = [...localMsgs, ...serverMsgs];
          
          for (var m in allMessages) {
            final existingKey = mergedMap.keys.firstWhere(
              (k) {
                final existing = mergedMap[k]!;
                if (existing.id.isNotEmpty && m.id.isNotEmpty && existing.id == m.id) {
                  return true;
                }
                final bool sameSender = _isSameUser(existing.senderId, m.senderId);
                final bool sameText = existing.text.trim() == m.text.trim();
                final bool closeTime = (existing.timestamp.difference(m.timestamp).inSeconds).abs() < 20;
                return sameSender && sameText && closeTime;
              },
              orElse: () => '',
            );

            if (existingKey.isNotEmpty) {
              if (m.id.isNotEmpty) {
                mergedMap[existingKey] = m;
              }
            } else {
              final key = m.id.isNotEmpty
                  ? m.id
                  : '${m.senderId}_${m.text}_${m.timestamp.millisecondsSinceEpoch}';
              mergedMap[key] = m;
            }
          }

          final mergedList = mergedMap.values.toList();
          mergedList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          if (conv != null) {
            _conversations[peerId] = DirectChatConversation(
              peerId: conv.peerId,
              peerName: conv.peerName,
              peerRole: conv.peerRole,
              avatarLetter: conv.avatarLetter,
              colorValue: conv.colorValue,
              isOnline: conv.isOnline,
              lastMessage: mergedList.isNotEmpty
                  ? mergedList.last.text
                  : conv.lastMessage,
              lastTimestamp: mergedList.isNotEmpty
                  ? mergedList.last.timestamp
                  : conv.lastTimestamp,
              unreadCount: 0,
              messages: mergedList,
            );
            await _saveToStorage();
          }

          return mergedList;
        }
      }
    } catch (e) {
      debugPrint('Error loading peer direct messages from server: $e');
    }

    return localMsgs;
  }

  Future<DirectChatMessage> sendMessage(String peerId, String rawText) async {
    await init();
    final conv = _conversations[peerId];
    if (conv == null) throw Exception('Conversation not found');

    final myId = await getMyUserId();
    final myName = await getMyUserName();
    final now = DateTime.now();
    final msgId = 'dmsg_${now.millisecondsSinceEpoch}_${(1000 + (now.microsecond % 9000))}';
    final msg = DirectChatMessage(
      id: msgId,
      senderId: myId,
      senderName: myName,
      text: rawText,
      timestamp: now,
      isMe: true,
    );

    final updatedMessages = [...conv.messages, msg];
    final updatedConv = DirectChatConversation(
      peerId: conv.peerId,
      peerName: conv.peerName,
      peerRole: conv.peerRole,
      avatarLetter: conv.avatarLetter,
      colorValue: conv.colorValue,
      isOnline: conv.isOnline,
      lastMessage: rawText,
      lastTimestamp: now,
      unreadCount: 0,
      messages: updatedMessages,
    );

    _conversations[peerId] = updatedConv;
    await _saveToStorage();

    // Dynamically persist message into backend database & broadcast to peer
    _syncMessageToBackend(peerId, conv, rawText, myId, myName, msgId);

    return msg;
  }

  Future<void> _syncMessageToBackend(
    String peerId,
    DirectChatConversation conv,
    String text,
    String myId,
    String myName,
    String msgId,
  ) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();

      await http
          .post(
            Uri.parse('$baseUrl/community/direct-chats/send'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'id': msgId,
              'senderId': myId,
              'senderName': myName,
              'peerId': peerId,
              'peerName': conv.peerName,
              'peerRole': conv.peerRole,
              'avatarLetter': conv.avatarLetter,
              'colorValue': conv.colorValue,
              'text': text,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Direct chat message backend table sync info: $e');
    }
  }

  Future<void> markAsRead(String peerId) async {
    await init();
    final conv = _conversations[peerId];
    if (conv == null) return;

    _conversations[peerId] = DirectChatConversation(
      peerId: conv.peerId,
      peerName: conv.peerName,
      peerRole: conv.peerRole,
      avatarLetter: conv.avatarLetter,
      colorValue: conv.colorValue,
      isOnline: conv.isOnline,
      lastMessage: conv.lastMessage,
      lastTimestamp: conv.lastTimestamp,
      unreadCount: 0,
      messages: conv.messages,
    );
    await _saveToStorage();

    try {
      final myId = await getMyUserId();
      final conversationId = getConversationId(myId, peerId);
      final baseUrl = await ApiConfig.getBaseUrl();
      await http
          .post(
            Uri.parse('$baseUrl/community/direct-chats/$conversationId/read'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': myId}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<int> getTotalUnreadCount() async {
    await init();
    int count = 0;
    for (var c in _conversations.values) {
      count += c.unreadCount;
    }
    return count;
  }
}
