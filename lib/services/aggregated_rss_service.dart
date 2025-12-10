import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import '../models/news_item.dart';

/// Service for aggregating multiple RSS feeds (Erasmus+ EU and Instagram).
/// Handles fetching, parsing, and merging feeds with proper error handling.
class AggregatedRssService {
  // Feed URLs
  static const String _erasmusRssUrl = 'https://erasmus-plus.ec.europa.eu/rss.xml';
  // Use limit parameter to reduce feed size - RSSHub supports this
  static const String _instagramRssUrl = 'https://rsshub.app/instagram/user/tmelnik_cz?limit=30';
  static const int _maxArticles = 30; // Reduced for faster loading
  static const Duration _maxAge = Duration(days: 60); // Only show items from last 2 months
  static const int _maxItemsToParse = 30; // Reduced to 30 - limit parameter already restricts feed
  
  // Cache for raw XML feed (short TTL to reduce network calls)
  static String? _cachedXml;
  static DateTime? _cacheTimestamp;
  static const Duration _xmlCacheTTL = Duration(minutes: 5); // Cache XML for 5 minutes
  
  /// Clears the XML cache (useful for forcing refresh)
  static void clearXmlCache() {
    _cachedXml = null;
    _cacheTimestamp = null;
    debugPrint('🗑️ [RSS] XML cache cleared');
  }

  /// Fetches and aggregates news from both Erasmus+ and Instagram feeds.
  /// Returns a unified list sorted by publication date (newest first).
  /// Handles errors gracefully - if one feed fails, the other still works.
  /// NOTE: Erasmus feed disabled due to performance issues - only Instagram is used
  Future<List<NewsItem>> fetchAggregatedNews({
    Function(NewsItem)? onItemFound,
    Function(int current, int total)? onProgress,
  }) async {
    final List<NewsItem> allNews = [];
    
    // Only fetch Instagram feed - Erasmus feed disabled for performance
    // Fetch Instagram feed with progress tracking
    try {
      final instagramNews = await _fetchInstagramFeed(onProgress: onProgress);
      allNews.addAll(instagramNews);
      
      // Emit items immediately if callback provided
      if (onItemFound != null) {
        for (final item in instagramNews) {
          onItemFound(item);
        }
      }
    } catch (e) {
      debugPrint('❌ [RSS] Error fetching Instagram feed: $e');
    }
    
    // Erasmus feed disabled - was causing slow loading
    // Uncomment below if needed in future:
    /*
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
    */

    // Items are already filtered during parsing, but double-check for safety
    // Ensure we only keep items from the last 2 months
    final now = DateTime.now();
    final cutoffDate = now.subtract(_maxAge);
    final recentNews = allNews.where((item) {
      if (item.pubDateTimestamp == null) return false; // Skip items without date
      return item.pubDateTimestamp!.isAfter(cutoffDate); // Only items from last 2 months
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

    debugPrint('📰 [RSS] Aggregated ${limitedNews.length} news items (Instagram only - Erasmus disabled)');
    
    return limitedNews;
  }

  /// Fetches and parses the Erasmus+ RSS feed
  /// DISABLED: Unused - feed was causing performance issues
  // ignore: unused_element
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
  /// Uses intelligent caching to reduce network calls
  Future<List<NewsItem>> _fetchInstagramFeed({
    Function(int current, int total)? onProgress,
  }) async {
    try {
      String xmlString;
      final now = DateTime.now();
      
      // Check if we have valid cached XML
      if (_cachedXml != null && 
          _cacheTimestamp != null && 
          now.difference(_cacheTimestamp!) < _xmlCacheTTL) {
        debugPrint('📦 [RSS] Using cached Instagram feed XML (age: ${now.difference(_cacheTimestamp!).inSeconds}s)');
        xmlString = _cachedXml!;
        // Report progress: using cache (skip network fetch)
        onProgress?.call(40, 100);
      } else {
        // Report progress: starting fetch (10%)
        onProgress?.call(10, 100);
        
        Uri requestUri;
        if (kIsWeb) {
          // Use CORS proxy for web
          final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(_instagramRssUrl)}';
          requestUri = Uri.parse(proxyUrl);
        } else {
          requestUri = Uri.parse(_instagramRssUrl);
        }

        final response = await http.get(requestUri).timeout(
          const Duration(seconds: 8), // Slightly increased for reliability
          onTimeout: () {
            throw Exception('Instagram feed request timeout');
          },
        );

        // Report progress: fetch complete (30%)
        onProgress?.call(30, 100);

        if (response.statusCode != 200) {
          throw Exception('Instagram feed returned status ${response.statusCode}');
        }

        xmlString = utf8.decode(response.bodyBytes);
        
        // Cache the XML for future use
        _cachedXml = xmlString;
        _cacheTimestamp = now;
        debugPrint('💾 [RSS] Cached Instagram feed XML (${xmlString.length} bytes)');
      }
      
      // Report progress: parsing started (40%)
      onProgress?.call(40, 100);
      
      final items = _parseRssXml(
        xmlString, 
        source: 'Instagram',
        onProgress: onProgress,
      );
      
      // Limit Instagram items (date filtering already done during parsing)
      final limitedItems = items.take(_maxArticles).toList();

      // Report progress: complete (100%)
      onProgress?.call(100, 100);

      debugPrint('✅ [RSS] Fetched ${limitedItems.length} items from Instagram feed');
      return limitedItems;
    } catch (e, stackTrace) {
      debugPrint('❌ [RSS] Error fetching Instagram feed: $e');
      debugPrint('❌ [RSS] Stack trace: $stackTrace');
      
      // If error and we have cached XML, try to use it even if expired
      if (_cachedXml != null) {
        debugPrint('🔄 [RSS] Attempting to use expired cache as fallback');
        try {
          onProgress?.call(40, 100);
          final items = _parseRssXml(
            _cachedXml!,
            source: 'Instagram',
            onProgress: onProgress,
          );
          final limitedItems = items.take(_maxArticles).toList();
          onProgress?.call(100, 100);
          debugPrint('✅ [RSS] Used expired cache: ${limitedItems.length} items');
          return limitedItems;
        } catch (cacheError) {
          debugPrint('❌ [RSS] Cache fallback also failed: $cacheError');
        }
      }
      
      return [];
    }
  }

  /// Parses RSS XML string and extracts news items.
  /// Supports both Erasmus+ and Instagram RSS formats.
  /// Highly optimized: parses date first, stops early when enough items found.
  List<NewsItem> _parseRssXml(
    String xml, {
    required String source,
    Function(int current, int total)? onProgress,
  }) {
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
      // Find all <item> tags - limit to first 30 items (feed already limited by RSSHub limit parameter)
      final matches = itemRegex.allMatches(xml).take(_maxItemsToParse).toList();
      final totalMatches = matches.length;
      int processedCount = 0;
      int recentItemsFound = 0; // Track how many recent items we've found

      for (final match in matches) {
        processedCount++;
        
        // Report progress: 40% (fetch) + 60% (parsing) = 40 + (processedCount/totalMatches * 60)
        if (onProgress != null && totalMatches > 0) {
          final parsingProgress = (processedCount / totalMatches * 60).round();
          onProgress(40 + parsingProgress, 100);
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
        
        // Early exit optimization: if we've found enough recent items, stop parsing
        recentItemsFound++;
        if (recentItemsFound >= _maxArticles) {
          // We have enough recent items, but continue to check if there are more recent ones
          // Actually, since feed is sorted by date (newest first), we can break
          // But let's process a few more to be safe (in case of edge cases)
          if (items.length >= _maxArticles) {
            break;
          }
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
        // Truncate description early to avoid processing huge HTML (reduced from 1000 to 500)
        if (rawDescription.length > 500) {
          rawDescription = rawDescription.substring(0, 500);
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
  /// Highly optimized for performance with early exits and minimal allocations.
  String _cleanXmlText(String text) {
    if (text.isEmpty) return '';
    
    // Early exit for very short texts (common case)
    if (text.length < 10) {
      return text.trim();
    }
    
    // Remove CDATA wrapper if present (single pass)
    if (text.contains('CDATA')) {
      text = text.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), r'$1');
    }

    // Strip HTML tags first (before entity decoding for better performance)
    // Only do this if we detect HTML tags
    if (text.contains('<')) {
      text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    }

    // Decode common HTML entities (optimized order - check if needed first)
    if (text.contains('&')) {
      // Use replaceAllMapped for better performance on large strings
      text = text.replaceAll('&amp;', '&'); // Must be first
      text = text.replaceAll('&lt;', '<');
      text = text.replaceAll('&gt;', '>');
      text = text.replaceAll('&quot;', '"');
      text = text.replaceAll('&apos;', "'");
      text = text.replaceAll('&#39;', "'");
      text = text.replaceAll('&nbsp;', ' ');
    }

    return text.trim();
  }
}


