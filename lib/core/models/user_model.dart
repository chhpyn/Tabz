class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.profileImageUrl,
  });

  /// Create a UserModel from Firestore document data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
    );
  }

  /// Convert UserModel to Firestore document data
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
    };
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get firstName => name.split(' ').first;

  /// Displayed username always has the @ prefix
  String get displayUsername => username.startsWith('@') ? username : '@$username';
}
