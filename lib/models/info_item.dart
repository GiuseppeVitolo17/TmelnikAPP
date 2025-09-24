import 'package:cloud_firestore/cloud_firestore.dart';

class InfoItem {
  final String id;
  final String title;
  final String content;
  final InfoCategory category;
  final String author;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int views;
  final int likes;
  final List<String> tags;
  final String imageUrl;
  final bool isImportant;
  final bool isActive;
  final List<String> attachments;
  final String language;

  InfoItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.author,
    required this.createdAt,
    required this.lastUpdated,
    this.views = 0,
    this.likes = 0,
    this.tags = const [],
    this.imageUrl = '',
    this.isImportant = false,
    this.isActive = true,
    this.attachments = const [],
    this.language = 'en',
  });

  InfoItem copyWith({
    String? id,
    String? title,
    String? content,
    InfoCategory? category,
    String? author,
    DateTime? createdAt,
    DateTime? lastUpdated,
    int? views,
    int? likes,
    List<String>? tags,
    String? imageUrl,
    bool? isImportant,
    bool? isActive,
    List<String>? attachments,
    String? language,
  }) {
    return InfoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      isImportant: isImportant ?? this.isImportant,
      isActive: isActive ?? this.isActive,
      attachments: attachments ?? this.attachments,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category.name,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'views': views,
      'likes': likes,
      'tags': tags,
      'imageUrl': imageUrl,
      'isImportant': isImportant,
      'isActive': isActive,
      'attachments': attachments,
      'language': language,
    };
  }

  factory InfoItem.fromJson(Map<String, dynamic> json) {
    return InfoItem(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: InfoCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => InfoCategory.rules,
      ),
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      isImportant: json['isImportant'] ?? false,
      isActive: json['isActive'] ?? true,
      attachments: List<String>.from(json['attachments'] ?? []),
      language: json['language'] ?? 'en',
    );
  }

  String get formattedLastUpdated {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated).inDays;
    
    if (difference == 0) {
      return 'Updated today';
    } else if (difference == 1) {
      return 'Updated yesterday';
    } else if (difference < 7) {
      return 'Updated $difference days ago';
    } else {
      return 'Updated ${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}';
    }
  }

  String get shortContent {
    if (content.length <= 200) return content;
    return '${content.substring(0, 200)}...';
  }

  bool get isRecentlyUpdated => 
      DateTime.now().difference(lastUpdated).inDays < 7;

  @override
  String toString() {
    return 'InfoItem(id: $id, title: $title, category: $category, isImportant: $isImportant)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InfoItem &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.category == category &&
        other.author == author &&
        other.createdAt == createdAt &&
        other.lastUpdated == lastUpdated &&
        other.views == views &&
        other.likes == likes &&
        other.tags.toString() == tags.toString() &&
        other.imageUrl == imageUrl &&
        other.isImportant == isImportant &&
        other.isActive == isActive &&
        other.attachments.toString() == attachments.toString() &&
        other.language == language;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        category.hashCode ^
        author.hashCode ^
        createdAt.hashCode ^
        lastUpdated.hashCode ^
        views.hashCode ^
        likes.hashCode ^
        tags.hashCode ^
        imageUrl.hashCode ^
        isImportant.hashCode ^
        isActive.hashCode ^
        attachments.hashCode ^
        language.hashCode;
  }
}

enum InfoCategory {
  rules,
  tips,
  guidelines,
  safety,
  visa,
  accommodation,
  transport,
  culture,
  language,
  emergency,
  contact,
}

extension InfoCategoryExtension on InfoCategory {
  String get displayName {
    switch (this) {
      case InfoCategory.rules:
        return 'Rules & Regulations';
      case InfoCategory.tips:
        return 'Tips & Advice';
      case InfoCategory.guidelines:
        return 'Guidelines';
      case InfoCategory.safety:
        return 'Safety Information';
      case InfoCategory.visa:
        return 'Visa & Documents';
      case InfoCategory.accommodation:
        return 'Accommodation';
      case InfoCategory.transport:
        return 'Transportation';
      case InfoCategory.culture:
        return 'Culture & Customs';
      case InfoCategory.language:
        return 'Language Support';
      case InfoCategory.emergency:
        return 'Emergency Contacts';
      case InfoCategory.contact:
        return 'Contact Information';
    }
  }

  String get emoji {
    switch (this) {
      case InfoCategory.rules:
        return '📋';
      case InfoCategory.tips:
        return '💡';
      case InfoCategory.guidelines:
        return '📖';
      case InfoCategory.safety:
        return '🛡️';
      case InfoCategory.visa:
        return '📄';
      case InfoCategory.accommodation:
        return '🏠';
      case InfoCategory.transport:
        return '🚗';
      case InfoCategory.culture:
        return '🎭';
      case InfoCategory.language:
        return '🗣️';
      case InfoCategory.emergency:
        return '🚨';
      case InfoCategory.contact:
        return '📞';
    }
  }

  String get description {
    switch (this) {
      case InfoCategory.rules:
        return 'Important rules and regulations to follow';
      case InfoCategory.tips:
        return 'Helpful tips for travelers and workers';
      case InfoCategory.guidelines:
        return 'General guidelines and best practices';
      case InfoCategory.safety:
        return 'Safety information and precautions';
      case InfoCategory.visa:
        return 'Visa requirements and documentation';
      case InfoCategory.accommodation:
        return 'Accommodation options and booking tips';
      case InfoCategory.transport:
        return 'Transportation options and tips';
      case InfoCategory.culture:
        return 'Cultural information and customs';
      case InfoCategory.language:
        return 'Language learning resources';
      case InfoCategory.emergency:
        return 'Emergency contacts and procedures';
      case InfoCategory.contact:
        return 'Contact information and support';
    }
  }
}
