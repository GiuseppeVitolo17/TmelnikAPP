import 'package:cloud_firestore/cloud_firestore.dart';

/// User role model for managing permissions
/// Supports: normal user, admin, organizer (with NGO association)
class UserRole {
  final String uid;
  final String email;
  final bool isAdmin;
  final bool isOrganizer; // New role: organizer
  final String? ngoId; // NGO ID if user is organizer
  final DateTime createdAt;

  UserRole({
    required this.uid,
    required this.email,
    required this.isAdmin,
    this.isOrganizer = false,
    this.ngoId,
    required this.createdAt,
  });

  /// Create UserRole from Firestore document
  factory UserRole.fromMap(Map<String, dynamic> map, String uid) {
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return UserRole(
      uid: uid,
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      isOrganizer: map['isOrganizer'] ?? false,
      ngoId: map['ngoId'],
      createdAt: parseCreatedAt(map['createdAt']),
    );
  }

  /// Convert UserRole to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'isAdmin': isAdmin,
      'isOrganizer': isOrganizer,
      'ngoId': ngoId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  UserRole copyWith({
    String? uid,
    String? email,
    bool? isAdmin,
    bool? isOrganizer,
    String? ngoId,
    DateTime? createdAt,
  }) {
    return UserRole(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      ngoId: ngoId ?? this.ngoId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get user role type as string
  String get roleType {
    if (isAdmin) return 'admin';
    if (isOrganizer) return 'organizer';
    return 'user';
  }
}

