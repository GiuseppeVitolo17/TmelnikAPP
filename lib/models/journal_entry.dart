import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String mood; // 😊 😢 😴 🎉 🙏 etc.
  final List<String> tags;

  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.mood = '😊',
    this.tags = const [],
  });

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mood,
    List<String>? tags,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'mood': mood,
      'tags': tags,
    };
  }

  // Firestore methods
  Map<String, dynamic> toFirestore(String userId) {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'mood': mood,
      'tags': tags,
    };
  }

  factory JournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntry(
      id: data['id'] ?? doc.id,
      date: DateTime.parse(data['date']),
      content: data['content'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
      mood: data['mood'] ?? '😊',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      mood: json['mood'] ?? '😊',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, date: $date, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.id == id &&
        other.date == date &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.mood == mood &&
        other.tags.toString() == tags.toString();
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        content.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        mood.hashCode ^
        tags.hashCode;
  }
}

