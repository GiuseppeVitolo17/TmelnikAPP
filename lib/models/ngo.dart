import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a Non-Governmental Organization (NGO)
class NGO {
  final String id;
  final String name;
  final String description;
  final String? instagramUsername;
  final String? website;
  final String? email;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? createdBy; // Admin UID who created this NGO

  NGO({
    required this.id,
    required this.name,
    required this.description,
    this.instagramUsername,
    this.website,
    this.email,
    this.phone,
    this.address,
    this.logoUrl,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.createdBy,
  });

  /// Create NGO from Firestore document
  factory NGO.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NGO(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      instagramUsername: data['instagramUsername'],
      website: data['website'],
      email: data['email'],
      phone: data['phone'],
      address: data['address'],
      logoUrl: data['logoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'],
    );
  }

  /// Convert NGO to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'instagramUsername': instagramUsername,
      'website': website,
      'email': email,
      'phone': phone,
      'address': address,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
      'createdBy': createdBy,
    };
  }

  /// Create a copy with modified fields
  NGO copyWith({
    String? id,
    String? name,
    String? description,
    String? instagramUsername,
    String? website,
    String? email,
    String? phone,
    String? address,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? createdBy,
  }) {
    return NGO(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() {
    return 'NGO(id: $id, name: $name, isActive: $isActive)';
  }
}
