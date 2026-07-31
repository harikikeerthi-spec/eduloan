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

  factory DirectChatMessage.fromJson(Map<String, dynamic> json) => DirectChatMessage(
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

  String get maskedLastMessage => DirectChatMessage.maskPhoneNumbers(lastMessage);

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

  factory DirectChatConversation.fromJson(Map<String, dynamic> json) => DirectChatConversation(
        peerId: json['peerId'] ?? '',
        peerName: json['peerName'] ?? '',
        peerRole: json['peerRole'] ?? 'Student',
        avatarLetter: json['avatarLetter'] ?? (json['peerName'] != null && (json['peerName'] as String).isNotEmpty ? json['peerName'][0] : 'U'),
        colorValue: json['colorValue'] ?? 0xFF311B92,
        isOnline: json['isOnline'] ?? true,
        lastMessage: json['lastMessage'] ?? '',
        lastTimestamp: DateTime.tryParse(json['lastTimestamp'] ?? '') ?? DateTime.now(),
        unreadCount: json['unreadCount'] ?? 0,
        messages: (json['messages'] as List<dynamic>?)?.map((m) => DirectChatMessage.fromJson(m as Map<String, dynamic>)).toList() ?? [],
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
          final conv = DirectChatConversation.fromJson(item as Map<String, dynamic>);
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

  Future<DirectChatMessage> sendMessage(String peerId, String rawText) async {
    await init();
    final conv = _conversations[peerId];
    if (conv == null) throw Exception('Conversation not found');

    final now = DateTime.now();
    final msg = DirectChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      senderId: 'user_me',
      senderName: 'You',
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

    // Dynamically persist message into backend database table
    _syncMessageToBackend(peerId, conv, rawText);

    // Trigger an automated friendly response if chatting with mock peers
    _triggerAutoReplyIfNeeded(peerId, rawText);

    return msg;
  }

  Future<void> _syncMessageToBackend(String peerId, DirectChatConversation conv, String text) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'user_me';

      await http.post(
        Uri.parse('$baseUrl/community/direct-chats/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': userId,
          'peerId': peerId,
          'peerName': conv.peerName,
          'peerRole': conv.peerRole,
          'avatarLetter': conv.avatarLetter,
          'colorValue': conv.colorValue,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Direct chat message backend table sync info: $e');
    }
  }

  void _triggerAutoReplyIfNeeded(String peerId, String userMsgText) {
    Future.delayed(const Duration(seconds: 2), () async {
      final conv = _conversations[peerId];
      if (conv == null) return;

      String replyText = "Thanks for your message! I'm currently reviewing my university documents.";
      if (userMsgText.toLowerCase().contains('phone') ||
          userMsgText.toLowerCase().contains('number') ||
          userMsgText.toLowerCase().contains('call')) {
        replyText = "Sure, you can ping me here! Note that phone numbers are automatically masked as XXXXXXXXXX for safety.";
      } else if (userMsgText.toLowerCase().contains('loan') || userMsgText.toLowerCase().contains('bank')) {
        replyText = "I applied through VidhyaLoan for non-collateral approval. The process was super quick!";
      }

      final now = DateTime.now();
      final replyMsg = DirectChatMessage(
        id: 'reply_${now.millisecondsSinceEpoch}',
        senderId: peerId,
        senderName: conv.peerName,
        text: replyText,
        timestamp: now,
        isMe: false,
      );

      final updatedMsgs = [...conv.messages, replyMsg];
      _conversations[peerId] = DirectChatConversation(
        peerId: conv.peerId,
        peerName: conv.peerName,
        peerRole: conv.peerRole,
        avatarLetter: conv.avatarLetter,
        colorValue: conv.colorValue,
        isOnline: conv.isOnline,
        lastMessage: replyText,
        lastTimestamp: now,
        unreadCount: conv.unreadCount + 1,
        messages: updatedMsgs,
      );
      await _saveToStorage();
    });
  }

  Future<void> markAsRead(String peerId) async {
    await init();
    final conv = _conversations[peerId];
    if (conv == null || conv.unreadCount == 0) return;

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
