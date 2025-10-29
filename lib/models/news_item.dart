/// Model for RSS news items from Erasmus+ feed.
/// This is separate from the Firestore News model.
class NewsItem {
  final String title;
  final String summary;
  final String date;
  final String url;

  NewsItem({
    required this.title,
    required this.summary,
    required this.date,
    required this.url,
  });

  /// Creates a NewsItem from an RSS item.
  /// Strips HTML tags from description to get clean text.
  factory NewsItem.fromRssItem(dynamic rssItem) {
    // Handle different RSS library formats
    String title = '';
    String summary = '';
    String date = '';
    String url = '';

    // Try to extract fields using reflection/dynamic access
    try {
      title = rssItem.title?.toString() ?? '';
      url = rssItem.link?.toString() ?? '';
      date = rssItem.pubDate?.toString() ?? '';
      
      // Clean HTML from description
      String rawDescription = rssItem.description?.toString() ?? '';
      summary = rawDescription.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      
      // If summary is empty but rawDescription exists, use it as-is (might be plain text)
      if (summary.isEmpty && rawDescription.isNotEmpty) {
        summary = rawDescription.trim();
      }
    } catch (e) {
      // Fallback if structure is different
      title = rssItem.toString();
    }

    return NewsItem(
      title: title,
      summary: summary,
      date: date,
      url: url,
    );
  }

  @override
  String toString() {
    return 'NewsItem(title: $title, url: $url)';
  }
}

