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
  static const int _maxItemsToParse = 50; // Reduced to 50 for faster parsing - we only need 30 recent items

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
  /// Highly optimized: parses date first, stops early when enough items found.
  List<NewsItem> _parseRssXml(String xml, {required String source}) {
    final List<NewsItem> items = [];
    final now = DateTime.now();
    final cutoffDate = now.subtract(_maxAge);
    
    // Pre-compile regex for better performance
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final pubDateRegex = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true);
    final titleRegex = RegExp(r'<title>(.*?)</title>', dotAll: true);
    final linkRegex = RegExp(r'<link>(.*?)</link>', dotAll: true);
    final descriptionRegex = RegExp(r'<description>(.*?)</description>', dotAll: true);
    final mediaRegex = RegExp('<media:(?:content|thumbnail)[^>]*url=["\\\']([^"\\\']+)["\\\']', dotAll: true);
    final enclosureRegex = RegExp('<enclosure[^>]*type=["\\\']image/[^"\\\']+["\\\'][^>]*url=["\\\']([^"\\\']+)["\\\']', dotAll: true);
    final imgRegex = RegExp('<img[^>]*src=["\\\']([^"\\\']+)["\\\']', dotAll: true);
    
    try {
      // Find all <item> tags - limit to first 50 items for better performance
      final matches = itemRegex.allMatches(xml).take(50);

      for (final match in matches) {
        // Stop if we already have enough recent items
        if (items.length >= _maxArticles) {
          break;
        }
        final itemXml = match.group(1) ?? '';
        
        // OPTIMIZATION: Parse date FIRST to skip old items immediately
        final pubDateMatch = pubDateRegex.firstMatch(itemXml);
        if (pubDateMatch == null) continue; // Skip items without date
        
        final pubDateRaw = _cleanXmlText(pubDateMatch.group(1) ?? '');
        final pubDateTimestamp = NewsItem.parsePubDate(pubDateRaw);
        
        // Skip items without valid date or older than 2 months - EARLY EXIT
        if (pubDateTimestamp == null || !pubDateTimestamp.isAfter(cutoffDate)) {
          continue; // Skip immediately without processing other fields
        }
        
        // Only parse other fields if date is valid and recent
        final titleMatch = titleRegex.firstMatch(itemXml);
        final linkMatch = linkRegex.firstMatch(itemXml);
        final descriptionMatch = descriptionRegex.firstMatch(itemXml);
        
        final title = _cleanXmlText(titleMatch?.group(1) ?? '');
        final url = _cleanXmlText(linkMatch?.group(1) ?? '');
        
        // Skip if no title or URL
        if (title.isEmpty || url.isEmpty) continue;
        
        // Process description only if needed (truncate early)
        String rawDescription = descriptionMatch?.group(1) ?? '';
        // Truncate description early to avoid processing huge HTML
        if (rawDescription.length > 1000) {
          rawDescription = rawDescription.substring(0, 1000);
        }
        final description = _cleanXmlText(rawDescription);
        
        // Extract image URL (simplified - only if needed)
        String imageUrl = '';
        final mediaMatch = mediaRegex.firstMatch(itemXml);
        if (mediaMatch != null) {
          imageUrl = mediaMatch.group(1)?.trim() ?? '';
        } else {
          final enclosureMatch = enclosureRegex.firstMatch(itemXml);
          if (enclosureMatch != null) {
            imageUrl = enclosureMatch.group(1)?.trim() ?? '';
          } else if (rawDescription.isNotEmpty) {
            final imgMatch = imgRegex.firstMatch(rawDescription);
            imageUrl = imgMatch?.group(1)?.trim() ?? '';
          }
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
  /// Optimized: uses StringBuffer for better performance on large texts.
  String _cleanXmlText(String text) {
    if (text.isEmpty) return '';
    
    // Remove CDATA wrapper if present
    text = text.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), r'$1');

    // Strip HTML tags first (before entity decoding for better performance)
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode common HTML entities (optimized order)
    text = text.replaceAll('&amp;', '&'); // Must be first
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&apos;', "'");
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');

    return text.trim();
  }
}
