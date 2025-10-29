import 'package:cloud_firestore/cloud_firestore.dart';

enum MoodType {
  happy,    // 👍
  neutral,  // 😐
  unhappy,  // 👎
}

class DailyReflection {
  final String id;
  final String userId;
  final DateTime date;
  final MoodType? mood;
  final List<Activity> activities;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyReflection({
    required this.id,
    required this.userId,
    required this.date,
    this.mood,
    this.activities = const [],
    required this.createdAt,
    this.updatedAt,
  });

  DailyReflection copyWith({
    String? id,
    String? userId,
    DateTime? date,
    MoodType? mood,
    List<Activity>? activities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyReflection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'mood': mood?.name,
      'activities': activities.map((a) => a.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory DailyReflection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyReflection(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mood: data['mood'] != null 
          ? MoodType.values.firstWhere(
              (e) => e.name == data['mood'],
              orElse: () => MoodType.neutral,
            )
          : null,
      activities: (data['activities'] as List<dynamic>?)
              ?.map((a) => Activity.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  String get dayNumber {
    return date.day.toString();
  }

  String get moodEmoji {
    switch (mood) {
      case MoodType.happy:
        return '👍';
      case MoodType.neutral:
        return '😐';
      case MoodType.unhappy:
        return '👎';
      case null:
        return '';
    }
  }
}

class Activity {
  final String id;
  final String name;
  final MoodType? rating;

  Activity({
    required this.id,
    required this.name,
    this.rating,
  });

  Activity copyWith({
    String? id,
    String? name,
    MoodType? rating,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating?.name,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      rating: map['rating'] != null
          ? MoodType.values.firstWhere(
              (e) => e.name == map['rating'],
              orElse: () => MoodType.neutral,
            )
          : null,
    );
  }

  String get ratingEmoji {
    switch (rating) {
      case MoodType.happy:
        return '👍';
      case MoodType.neutral:
        return '😐';
      case MoodType.unhappy:
        return '👎';
      case null:
        return '';
    }
  }
}

