class News {
  final String id;
  final String title;
  final String content;
  final NewsType type;
  final String author;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String> tags;
  final String imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final bool isPinned;
  final bool isActive;
  final List<String> attachments;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.author,
    required this.createdAt,
    this.expiresAt,
    this.tags = const [],
    this.imageUrl = '',
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isPinned = false,
    this.isActive = true,
    this.attachments = const [],
  });

  News copyWith({
    String? id,
    String? title,
    String? content,
    NewsType? type,
    String? author,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? tags,
    String? imageUrl,
    int? likes,
    int? comments,
    int? shares,
    bool? isPinned,
    bool? isActive,
    List<String>? attachments,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'tags': tags,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'isPinned': isPinned,
      'isActive': isActive,
      'attachments': attachments,
    };
  }

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: NewsType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NewsType.news,
      ),
      author: json['author'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isActive: json['isActive'] ?? true,
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  bool get isHot => DateTime.now().difference(createdAt).inHours < 24;

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inHours;
    
    if (difference < 1) {
      return 'Just now';
    } else if (difference < 24) {
      return '$difference hours ago';
    } else {
      final days = difference ~/ 24;
      if (days == 1) {
        return 'Yesterday';
      } else if (days < 7) {
        return '$days days ago';
      } else {
        return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
      }
    }
  }

  String get shortContent {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  @override
  String toString() {
    return 'News(id: $id, title: $title, type: $type, isHot: $isHot)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is News &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.type == type &&
        other.author == author &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.tags.toString() == tags.toString() &&
        other.imageUrl == imageUrl &&
        other.likes == likes &&
        other.comments == comments &&
        other.shares == shares &&
        other.isPinned == isPinned &&
        other.isActive == isActive &&
        other.attachments.toString() == attachments.toString();
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        type.hashCode ^
        author.hashCode ^
        createdAt.hashCode ^
        expiresAt.hashCode ^
        tags.hashCode ^
        imageUrl.hashCode ^
        likes.hashCode ^
        comments.hashCode ^
        shares.hashCode ^
        isPinned.hashCode ^
        isActive.hashCode ^
        attachments.hashCode;
  }
}

enum NewsType {
  news,
  announcement,
  questionnaire,
  event,
  tip,
  warning,
  success,
}

extension NewsTypeExtension on NewsType {
  String get displayName {
    switch (this) {
      case NewsType.news:
        return 'News';
      case NewsType.announcement:
        return 'Announcement';
      case NewsType.questionnaire:
        return 'Questionnaire';
      case NewsType.event:
        return 'Event';
      case NewsType.tip:
        return 'Tip';
      case NewsType.warning:
        return 'Warning';
      case NewsType.success:
        return 'Success Story';
    }
  }

  String get emoji {
    switch (this) {
      case NewsType.news:
        return '📰';
      case NewsType.announcement:
        return '📢';
      case NewsType.questionnaire:
        return '📝';
      case NewsType.event:
        return '🎉';
      case NewsType.tip:
        return '💡';
      case NewsType.warning:
        return '⚠️';
      case NewsType.success:
        return '🏆';
    }
  }

  String get description {
    switch (this) {
      case NewsType.news:
        return 'Latest news and updates';
      case NewsType.announcement:
        return 'Important announcements';
      case NewsType.questionnaire:
        return 'Polls and surveys';
      case NewsType.event:
        return 'Upcoming events';
      case NewsType.tip:
        return 'Helpful tips and advice';
      case NewsType.warning:
        return 'Important warnings';
      case NewsType.success:
        return 'Success stories and achievements';
    }
  }
}
