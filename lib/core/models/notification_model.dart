enum NotificationType { newExpense, settlementReminder, groupRequest, friendRequest }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? groupId;
  final String? groupEmoji;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.groupId,
    this.groupEmoji,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'groupId': groupId,
      'groupEmoji': groupEmoji,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.newExpense,
      ),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      groupId: map['groupId'],
      groupEmoji: map['groupEmoji'],
      isRead: map['isRead'] ?? false,
    );
  }
}
