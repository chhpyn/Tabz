class GroupModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> memberIds;
  final List<String> pendingMemberIds;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.memberIds,
    required this.pendingMemberIds,
    required this.createdAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '🏠',
      description: map['description'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      pendingMemberIds: List<String>.from(map['pendingMemberIds'] ?? []),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'description': description,
      'memberIds': memberIds,
      'pendingMemberIds': pendingMemberIds,
      'createdAt': createdAt,
    };
  }
}
