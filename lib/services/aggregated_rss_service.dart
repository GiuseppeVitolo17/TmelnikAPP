import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/news_item.dart';

/// Service for aggregating multiple RSS feeds (Erasmus+ EU and Instagram).
/// Handles fetching, parsing, and merging feeds with proper error handling.
class AggregatedRssService {
  // Feed URLs
  static const String _erasmusRssUrl = 'https://erasmus-plus.ec.europa.eu/rss.xml';
  static const String _instagramRssUrl = 'https://rsshub.app/instagram/user/tmelnik_cz';
  static const int _maxArticles = 30; // Reduced for faster loading
  static const Duration _maxAge = Duration(days: 60); // Only show items from last 2 months
  static const int _maxItemsToParse = 100; // Limit XML parsing to first 100 items for performance

  /// Fetches and aggregates news from both Erasmus+ and Instagram feeds.
  /// Returns a unified list sorted by publication date (newest first).
  /// Handles errors gracefully - if one feed fails, the other still works.
  Future<List<NewsItem>> fetchAggregatedNews({
    Function(NewsItem)? onItemFound,
  }) async {
    final List<NewsItem> allNews = [];
    
    // Fetch both feeds in parallel for better performance
    final results = await Future.wait([
      _fetchErasmusFeed().catchError((e) {
        debugPrint('❌ [RSS] Error fetching Erasmus feed: $e');
        return <NewsItem>[]; // Return empty list on error
      }),
      _fetchInstagramFeed().catchError((e) {
        debugPrint('❌ [RSS] Error fetching Instagram feed: $e');
        return <NewsItem>[]; // Return empty list on error
      }),
    ]);

    // Combine results from both feeds
    for (final feedNews in results) {
      allNews.addAll(feedNews);
      
      // Emit items immediately if callback provided
      if (onItemFound != null) {
        for (final item in feedNews) {
          onItemFound(item);
        }
      }
    }

    // Items are already filtered during parsing, but double-check for safety
    final recentNews = allNews.where((item) {
      return item.pubDateTimestamp != null; // Only items with valid dates
    }).toList();

    // Sort by publication date (newest first)
    recentNews.sort((a, b) {
      if (a.pubDateTimestamp == null && b.pubDateTimestamp == null) return 0;
      if (a.pubDateTimestamp == null) return 1; // Items without date go to end
      if (b.pubDateTimestamp == null) return -1;
      return b.pubDateTimestamp!.compareTo(a.pubDateTimestamp!);
    });

    // Limit to max articles
    final limitedNews = recentNews.take(_maxArticles).toList();

    debugPrint('📰 [RSS] Aggregated ${limitedNews.length} news items (Erasmus: ${results[0].length}, Instagram: ${results[1].length})');
    
    return limitedNews;
  }

  /// Fetches and parses the Erasmus+ RSS feed
  Future<List<NewsItem>> _fetchErasmusFeed() async {
    try {
      Uri requestUri;
      if (kIsWeb) {
        // Use CORS proxy for web
        final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(_erasmusRssUrl)}';
        requestUri = Uri.parse(proxyUrl);
      } else {
        requestUri = Uri.parse(_erasmusRssUrl);
      }

      final response = await http.get(requestUri).timeout(
        const Duration(seconds: 5), // Reduced timeout for faster failure
        onTimeout: () {
          throw Exception('Erasmus feed request timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erasmus feed returned status ${response.statusCode}');
      }

      final xmlString = utf8.decode(response.bodyBytes);
      final items = _parseRssXml(xmlString, source: 'EU');
      
      // Filter Erasmus feed (only /news/ items, exclude documents)
      // Note: Date filtering already done during parsing for performance
      final filteredItems = items.where((item) {
        final url = item.url.toLowerCase();
        return url.contains('/news/') && !url.contains('/document/');
      }).take(_maxArticles).toList();

      debugPrint('✅ [RSS] Fetched ${filteredItems.length} items from Erasmus feed');
      return filteredItems;
    } catch (e, stackTrace) {
      debugPrint('❌ [RSS] Error fetching Erasmus feed: $e');
      debugPrint('❌ [RSS] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetches and parses the Instagram RSS feed
  Future<List<NewsItem>> _fetchInstagramFeed() async {
    try {
      Uri requestUri;
      if (kIsWeb) {
        // Use CORS proxy for web
        final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(_instagramRssUrl)}';
        requestUri = Uri.parse(proxyUrl);
      } else {
        requestUri = Uri.parse(_instagramRssUrl);
      }

      final response = await http.get(requestUri).timeout(
        const Duration(seconds: 5), // Reduced timeout for faster failure
        onTimeout: () {
          throw Exception('Instagram feed request timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Instagram feed returned status ${response.statusCode}');
      }

      final xmlString = utf8.decode(response.bodyBytes);
      final items = _parseRssXml(xmlString, source: 'Instagram');
      
      // Limit Instagram items (date filtering already done during parsing)
      final limitedItems = items.take(_maxArticles).toList();

      debugPrint('✅ [RSS] Fetched ${limitedItems.length} items from Instagram feed');
      return limitedItems;
    } catch (e, stackTrace) {
      debugPrint('❌ [RSS] Error fetching Instagram feed: $e');
      debugPrint('❌ [RSS] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Parses RSS XML string and extracts news items.
  /// Supports both Erasmus+ and Instagram RSS formats.
  /// Optimized: stops parsing when enough recent items are found.
  List<NewsItem> _parseRssXml(String xml, {required String source}) {
    final List<NewsItem> items = [];
    final now = DateTime.now();
    final cutoffDate = now.subtract(_maxAge);
    
    try {
      // Find all <item> tags - limit to first N items for performance
      final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
      final matches = itemRegex.allMatches(xml).take(_maxItemsToParse);

      for (final match in matches) {
        // Stop if we already have enough recent items
        if (items.length >= _maxArticles) {
          break;
        }
        final itemXml = match.group(1) ?? '';
        
        // Extract fields using regex
        final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(itemXml);
        final linkMatch = RegExp(r'<link>(.*?)</link>', dotAll: true).firstMatch(itemXml);
        final pubDateMatch = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(itemXml);
        final descriptionMatch = RegExp(r'<description>(.*?)</description>', dotAll: true).firstMatch(itemXml);
        
        // Try to extract image from various RSS formats
        final mediaMatch = RegExp('<media:(?:content|thumbnail)[^>]*url=["\\\']([^"\\\']+)["\\\']', dotAll: true)
            .firstMatch(itemXml);
        final enclosureMatch = RegExp('<enclosure[^>]*type=["\\\']image/[^"\\\']+["\\\'][^>]*url=["\\\']([^"\\\']+)["\\\']', dotAll: true)
            .firstMatch(itemXml);
        String rawDescription = descriptionMatch?.group(1) ?? '';
        final imgInDescriptionMatch = RegExp('<img[^>]*src=["\\\']([^"\\\']+)["\\\']', dotAll: true)
            .firstMatch(rawDescription);

        final title = _cleanXmlText(titleMatch?.group(1) ?? '');
        final url = _cleanXmlText(linkMatch?.group(1) ?? '');
        final pubDateRaw = _cleanXmlText(pubDateMatch?.group(1) ?? '');
        final description = _cleanXmlText(rawDescription);
        String imageUrl = (mediaMatch?.group(1) ??
                         enclosureMatch?.group(1) ??
                         imgInDescriptionMatch?.group(1) ??
                         '')
            .trim();

        // Only add if we have a title and URL
        if (title.isNotEmpty && url.isNotEmpty) {
          // Parse the publication date
          final pubDateTimestamp = NewsItem.parsePubDate(pubDateRaw);
          
          // Skip items without date or older than 2 months (already filtered above)
          if (pubDateTimestamp == null || !pubDateTimestamp.isAfter(cutoffDate)) {
            continue; // Skip items without valid date or too old
          }
          
          // Format date for display
          final formattedDate = _formatDateForDisplay(pubDateTimestamp);

          items.add(NewsItem(
            title: title,
            summary: description,
            date: formattedDate,
            url: url,
            imageUrl: imageUrl,
            pubDateTimestamp: pubDateTimestamp,
            source: source,
          ));
        }
      }
      
      debugPrint('📰 [RSS] Parsed ${items.length} items from $source feed');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [RSS] Error parsing $source XML: $e');
      debugPrint('❌ [RSS] Stack trace: $stackTrace');
    }

    return items;
  }

  /// Formats date for display
  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Format as "dd MMM yyyy"
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  /// Cleans XML/HTML tags and entities from text.
  String _cleanXmlText(String text) {
    // Remove CDATA wrapper if present
    text = text.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), r'$1');

    // Decode common HTML entities
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&apos;', "'");

    // Strip any HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    return text.trim();
  }
}
