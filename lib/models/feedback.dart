import 'package:cloud_firestore/cloud_firestore.dart';

class Feedback {
  final String id;
  final String title;
  final String description;
  final FeedbackType type;
  final String projectId;
  final String userId;
  final int rating;
  final List<String> tags;
  final DateTime createdAt;
  final String location;
  final List<String> images;
  final bool isAnonymous;

  Feedback({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.projectId,
    required this.userId,
    required this.rating,
    required this.tags,
    required this.createdAt,
    required this.location,
    this.images = const [],
    this.isAnonymous = false,
  });

  Feedback copyWith({
    String? id,
    String? title,
    String? description,
    FeedbackType? type,
    String? projectId,
    String? userId,
    int? rating,
    List<String>? tags,
    DateTime? createdAt,
    String? location,
    List<String>? images,
    bool? isAnonymous,
  }) {
    return Feedback(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      images: images ?? this.images,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'projectId': projectId,
      'userId': userId,
      'rating': rating,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
      'images': images,
      'isAnonymous': isAnonymous,
    };
  }

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: FeedbackType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeedbackType.project,
      ),
      projectId: json['projectId'],
      userId: json['userId'],
      rating: json['rating'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      location: json['location'],
      images: List<String>.from(json['images'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
    );
  }

  // Firestore methods
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'projectId': projectId,
      'userId': userId,
      'rating': rating,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'images': images,
      'isAnonymous': isAnonymous,
      'isActive': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory Feedback.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Feedback(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: FeedbackType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FeedbackType.project,
      ),
      projectId: data['projectId'] ?? '',
      userId: data['userId'] ?? '',
      rating: data['rating'] ?? 5,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      isAnonymous: data['isAnonymous'] ?? false,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get ratingStars {
    return '⭐' * rating + '☆' * (5 - rating);
  }

  @override
  String toString() {
    return 'Feedback(id: $id, title: $title, type: $type, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Feedback &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.projectId == projectId &&
        other.userId == userId &&
        other.rating == rating &&
        other.tags.toString() == tags.toString() &&
        other.createdAt == createdAt &&
        other.location == location &&
        other.images.toString() == images.toString() &&
        other.isAnonymous == isAnonymous;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        type.hashCode ^
        projectId.hashCode ^
        userId.hashCode ^
        rating.hashCode ^
        tags.hashCode ^
        createdAt.hashCode ^
        location.hashCode ^
        images.hashCode ^
        isAnonymous.hashCode;
  }
}

enum FeedbackType {
  project,
  travel,
  accommodation,
  transport,
  food,
  culture,
  general,
}

extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.project:
        return 'Project';
      case FeedbackType.travel:
        return 'Travel';
      case FeedbackType.accommodation:
        return 'Accommodation';
      case FeedbackType.transport:
        return 'Transport';
      case FeedbackType.food:
        return 'Food';
      case FeedbackType.culture:
        return 'Culture';
      case FeedbackType.general:
        return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case FeedbackType.project:
        return '🚀';
      case FeedbackType.travel:
        return '✈️';
      case FeedbackType.accommodation:
        return '🏠';
      case FeedbackType.transport:
        return '🚗';
      case FeedbackType.food:
        return '🍽️';
      case FeedbackType.culture:
        return '🎭';
      case FeedbackType.general:
        return '💬';
    }
  }

  String get description {
    switch (this) {
      case FeedbackType.project:
        return 'Share your experience with work projects';
      case FeedbackType.travel:
        return 'Tell us about your travel experiences';
      case FeedbackType.accommodation:
        return 'Review places where you stayed';
      case FeedbackType.transport:
        return 'Rate transportation options';
      case FeedbackType.food:
        return 'Share your food experiences';
      case FeedbackType.culture:
        return 'Describe cultural experiences';
      case FeedbackType.general:
        return 'General feedback and suggestions';
    }
  }
}
