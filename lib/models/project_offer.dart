import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectOffer {
  final String id;
  final String title;
  final String description;
  final String targeting;
  final String location;
  final String duration;
  final String requirements;
  final List<String> benefits;
  final String contactInfo;
  final DateTime createdAt;
  final DateTime expiresAt;
  final OfferStatus status;
  final int shareCount;
  final String imageUrl;

  ProjectOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.targeting,
    required this.location,
    required this.duration,
    required this.requirements,
    required this.benefits,
    required this.contactInfo,
    required this.createdAt,
    required this.expiresAt,
    this.status = OfferStatus.active,
    this.shareCount = 0,
    this.imageUrl = '',
  });

  ProjectOffer copyWith({
    String? id,
    String? title,
    String? description,
    String? targeting,
    String? location,
    String? duration,
    String? requirements,
    List<String>? benefits,
    String? contactInfo,
    DateTime? createdAt,
    DateTime? expiresAt,
    OfferStatus? status,
    int? shareCount,
    String? imageUrl,
  }) {
    return ProjectOffer(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targeting: targeting ?? this.targeting,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      shareCount: shareCount ?? this.shareCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targeting': targeting,
      'location': location,
      'duration': duration,
      'requirements': requirements,
      'benefits': benefits,
      'contactInfo': contactInfo,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status.name,
      'shareCount': shareCount,
      'imageUrl': imageUrl,
    };
  }

  factory ProjectOffer.fromJson(Map<String, dynamic> json) {
    return ProjectOffer(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targeting: json['targeting'],
      location: json['location'],
      duration: json['duration'],
      requirements: json['requirements'],
      benefits: List<String>.from(json['benefits'] ?? []),
      contactInfo: json['contactInfo'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      status: OfferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OfferStatus.active,
      ),
      shareCount: json['shareCount'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  // Firestore methods
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targeting': targeting,
      'location': location,
      'duration': duration,
      'requirements': requirements,
      'benefits': benefits,
      'contactInfo': contactInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.name,
      'shareCount': shareCount,
      'imageUrl': imageUrl,
      'isActive': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory ProjectOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectOffer(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      targeting: data['targeting'] ?? '',
      location: data['location'] ?? '',
      duration: data['duration'] ?? '',
      requirements: data['requirements'] ?? '',
      benefits: List<String>.from(data['benefits'] ?? []),
      contactInfo: data['contactInfo'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: OfferStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OfferStatus.active,
      ),
      shareCount: data['shareCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isActive => status == OfferStatus.active && !isExpired;

  String get formattedExpiryDate {
    final now = DateTime.now();
    final difference = expiresAt.difference(now).inDays;
    
    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      return 'Expires today';
    } else if (difference == 1) {
      return 'Expires tomorrow';
    } else if (difference < 7) {
      return 'Expires in $difference days';
    } else {
      return 'Expires ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}';
    }
  }

  String get instagramShareText {
    return '''🚀 ${title}

📍 ${location}
⏰ ${duration}
🎯 ${targeting}

${description}

${benefits.isNotEmpty ? '✅ Benefits:\n${benefits.map((b) => '• $b').join('\n')}' : ''}

📱 Contact: ${contactInfo}

#TmelnikProject #TravelOpportunity #WorkAbroad #${location.replaceAll(' ', '')}''';
  }

  @override
  String toString() {
    return 'ProjectOffer(id: $id, title: $title, location: $location, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectOffer &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.targeting == targeting &&
        other.location == location &&
        other.duration == duration &&
        other.requirements == requirements &&
        other.benefits.toString() == benefits.toString() &&
        other.contactInfo == contactInfo &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.status == status &&
        other.shareCount == shareCount &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        targeting.hashCode ^
        location.hashCode ^
        duration.hashCode ^
        requirements.hashCode ^
        benefits.hashCode ^
        contactInfo.hashCode ^
        createdAt.hashCode ^
        expiresAt.hashCode ^
        status.hashCode ^
        shareCount.hashCode ^
        imageUrl.hashCode;
  }
}

enum OfferStatus {
  active,
  paused,
  expired,
  completed,
}

extension OfferStatusExtension on OfferStatus {
  String get displayName {
    switch (this) {
      case OfferStatus.active:
        return 'Active';
      case OfferStatus.paused:
        return 'Paused';
      case OfferStatus.expired:
        return 'Expired';
      case OfferStatus.completed:
        return 'Completed';
    }
  }

  String get emoji {
    switch (this) {
      case OfferStatus.active:
        return '🟢';
      case OfferStatus.paused:
        return '⏸️';
      case OfferStatus.expired:
        return '🔴';
      case OfferStatus.completed:
        return '✅';
    }
  }
}
