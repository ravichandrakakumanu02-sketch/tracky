/// Represents an authenticated Tracky user.
class UserModel {
  final int id;
  final String name;
  final String email;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] as num?)?.toInt() ?? int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      name: (map['name'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : (map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Initials derived from the user's name (e.g. "John Doe" -> "JD", "Alex" -> "A")
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
