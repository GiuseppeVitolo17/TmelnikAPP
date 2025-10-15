/// User role model for managing permissions
class UserRole {
  final String uid;
  final String email;
  final bool isAdmin;
  final DateTime createdAt;

  UserRole({
    required this.uid,
    required this.email,
    required this.isAdmin,
    required this.createdAt,
  });

  /// Create UserRole from Firestore document
  factory UserRole.fromMap(Map<String, dynamic> map, String uid) {
    return UserRole(
      uid: uid,
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }

  /// Convert UserRole to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  UserRole copyWith({
    String? uid,
    String? email,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return UserRole(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

