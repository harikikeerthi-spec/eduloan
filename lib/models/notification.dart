class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      type: _parseType(json['type']),
    );
  }

  static NotificationType _parseType(String? type) {
    switch (type) {
      case 'loanUpdate':
        return NotificationType.loanUpdate;
      case 'communityMessage':
        return NotificationType.communityMessage;
      case 'offer':
        return NotificationType.offer;
      default:
        return NotificationType.system;
    }
  }
}

enum NotificationType {
  loanUpdate,
  communityMessage,
  offer,
  system,
}
