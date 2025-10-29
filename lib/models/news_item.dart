import 'package:intl/intl.dart';

/// Model for RSS news items from Erasmus+ feed.
/// This is separate from the Firestore News model.
class NewsItem {
  final String title;
  final String summary;
  final String date;
  final String url;
  final DateTime? pubDateTimestamp;
  final bool isNew; // Flag to indicate if this is a new article
  final bool isUpdated; // Flag to indicate if this article was updated

  NewsItem({
    required this.title,
    required this.summary,
    required this.date,
    required this.url,
    this.pubDateTimestamp,
    this.isNew = false,
    this.isUpdated = false,
  });

  NewsItem copyWith({
    String? title,
    String? summary,
    String? date,
    String? url,
    DateTime? pubDateTimestamp,
    bool? isNew,
    bool? isUpdated,
  }) {
    return NewsItem(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      date: date ?? this.date,
      url: url ?? this.url,
      pubDateTimestamp: pubDateTimestamp ?? this.pubDateTimestamp,
      isNew: isNew ?? this.isNew,
      isUpdated: isUpdated ?? this.isUpdated,
    );
  }

  /// Parses RFC 822 date format (e.g., "Mon, 11 Apr 2022 08:47:34 +0000")
  static DateTime? parsePubDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      // Common RSS date formats
      final formats = [
        'EEE, dd MMM yyyy HH:mm:ss Z', // Mon, 11 Apr 2022 08:47:34 +0000
        'EEE, dd MMM yyyy HH:mm:ss zzz', // Alternative with timezone name
        'dd MMM yyyy HH:mm:ss Z', // 11 Apr 2022 08:47:34 +0000
        'yyyy-MM-ddTHH:mm:ssZ', // ISO 8601
        'yyyy-MM-ddTHH:mm:ss.SSSZ', // ISO 8601 with milliseconds
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateString);
        } catch (e) {
          // Try next format
          continue;
        }
      }

      // Fallback: try DateTime.parse
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Formats the date for display
  String get formattedDate {
    if (pubDateTimestamp != null) {
      final now = DateTime.now();
      final difference = now.difference(pubDateTimestamp!);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('dd MMM yyyy').format(pubDateTimestamp!);
      }
    }
    
    // Fallback to raw date string if parsing failed
    return date;
  }

  @override
  String toString() {
    return 'NewsItem(title: $title, url: $url, pubDate: $pubDateTimestamp)';
  }
}

