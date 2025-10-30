import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/news_item.dart';

/// Service for fetching and parsing Erasmus+ RSS feed.
/// This service is completely stateless and independent from Firebase.
class ErasmusRssService {
  static const String _rssUrl = 'https://erasmus-plus.ec.europa.eu/rss.xml';
  static const int _maxArticles = 50; // Increased to catch more news items

  /// Fetches and parses the Erasmus+ RSS feed incrementally.
  /// Calls onItemFound callback for each valid news item found.
  /// Returns the complete list of news items when done.
  Future<List<NewsItem>> fetchErasmusNews({
    Function(NewsItem)? onItemFound,
  }) async {
    debugPrint('📰 [RSS] Starting to fetch Erasmus+ news from $_rssUrl');
    
    try {
      // Fetch RSS feed
      debugPrint('📰 [RSS] Making HTTP request...');
      
      // For web, we need to handle CORS issues
      // Use a CORS proxy or fetch with proper headers
      Uri requestUri;
      if (kIsWeb) {
        // Use a CORS proxy for web (you may need to replace this with your own proxy)
        // Alternatively, you could set up a backend endpoint
        final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(_rssUrl)}';
        requestUri = Uri.parse(proxyUrl);
        debugPrint('📰 [RSS] Using CORS proxy for web: $proxyUrl');
      } else {
        requestUri = Uri.parse(_rssUrl);
      }
      
      final response = await http.get(requestUri);
      
      debugPrint('📰 [RSS] HTTP response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('❌ [RSS] HTTP request failed with status ${response.statusCode}');
        return [];
      }

      // Parse XML manually (simple parsing for RSS 2.0)
      final xmlString = utf8.decode(response.bodyBytes);
      debugPrint('📰 [RSS] XML length: ${xmlString.length} characters');
      
      // Parse and filter incrementally - show items as they are found
      final List<NewsItem> filteredItems = [];
      final allItems = _parseRssXml(xmlString);
      debugPrint('📰 [RSS] Parsed ${allItems.length} items from RSS');
      
      // Log all URLs found for debugging
      debugPrint('📰 [RSS] All URLs found in feed:');
      for (int i = 0; i < allItems.length && i < 20; i++) {
        final item = allItems[i];
        final hasNews = item.url.toLowerCase().contains('/news/');
        final hasDocument = item.url.toLowerCase().contains('/document/');
        final hasHelp = item.url.toLowerCase().contains('/help');
        final hasEche = item.url.toLowerCase().contains('/eche/');
        debugPrint('📰 [RSS]   ${i + 1}. ${hasNews ? "✅NEWS" : hasDocument ? "📄DOC" : hasHelp ? "❓HELP" : hasEche ? "📋ECHE" : "❓OTHER"} ${item.url}');
      }
      
      // Filter and emit items one by one
      // IMPORTANT: Only filter by /news/ pattern, don't exclude other patterns too aggressively
      final useFallback = allItems.where((item) {
        final url = item.url.toLowerCase();
        return url.contains('/news/') && 
               !url.contains('/document/');
      }).isEmpty;
      
      final filterCriteria = useFallback ? (NewsItem item) {
        // Fallback: exclude only documents and eche assessments, but allow help pages if they're news-like
        final url = item.url.toLowerCase();
        return !url.contains('/document/') &&
               !url.contains('/eche/assessment-type');
      } : (NewsItem item) {
        // Primary: only /news/ pages, exclude documents
        final url = item.url.toLowerCase();
        return url.contains('/news/') && 
               !url.contains('/document/');
      };
      
      for (final item in allItems) {
        if (filteredItems.length >= _maxArticles) break;
        
        if (filterCriteria(item)) {
          filteredItems.add(item);
          debugPrint('📰 [RSS] ✅ Found news item ${filteredItems.length}/${_maxArticles}: ${item.title}');
          
          // Emit item immediately if callback provided
          if (onItemFound != null) {
            onItemFound(item);
          }
        }
      }
      
      debugPrint('📰 [RSS] Filtered to ${filteredItems.length} news items (excluding documents)');
      
      // IMPORTANT: Warn if feed seems incomplete
      if (filteredItems.length == 1 && allItems.isNotEmpty) {
        debugPrint('⚠️ [RSS] WARNING: Only 1 news item found in feed. Feed may be incomplete or outdated.');
        debugPrint('⚠️ [RSS] The RSS feed contains only ${allItems.length} total items.');
        debugPrint('⚠️ [RSS] Recent news may not be included in the official RSS feed.');
      }
      
      if (filteredItems.isNotEmpty) {
        debugPrint('📰 [RSS] First item: ${filteredItems[0].title}');
        debugPrint('📰 [RSS] First item URL: ${filteredItems[0].url}');
        if (filteredItems[0].pubDateTimestamp != null) {
          debugPrint('📰 [RSS] First item date: ${filteredItems[0].pubDateTimestamp}');
        }
      } else {
        debugPrint('⚠️ [RSS] No items found after filtering. Total parsed: ${allItems.length}');
        if (allItems.isNotEmpty) {
          debugPrint('📰 [RSS] Sample URLs: ${allItems.take(3).map((e) => e.url).join(", ")}');
        }
      }

      return filteredItems;
    } catch (e, stackTrace) {
      debugPrint('❌ [RSS] Error fetching news: $e');
      debugPrint('❌ [RSS] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Parses RSS XML string and extracts news items.
  /// Handles RSS 2.0 format with proper date parsing.
  List<NewsItem> _parseRssXml(String xml) {
    final List<NewsItem> items = [];
    
    try {
      // Find all <item> tags
      final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
      final matches = itemRegex.allMatches(xml);

      for (final match in matches) {
        final itemXml = match.group(1) ?? '';
        
        // Extract fields using regex
        final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(itemXml);
        final linkMatch = RegExp(r'<link>(.*?)</link>', dotAll: true).firstMatch(itemXml);
        final pubDateMatch = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(itemXml);
        final descriptionMatch = RegExp(r'<description>(.*?)</description>', dotAll: true).firstMatch(itemXml);
        // Try to extract preview image from common RSS tags before stripping HTML
        final mediaMatch = RegExp(r'<media:(?:content|thumbnail)[^>]*url=["\']([^"\']+)["\']', dotAll: true)
            .firstMatch(itemXml);
        final enclosureMatch = RegExp(r'<enclosure[^>]*type=["\']image/[^"\']+["\'][^>]*url=["\']([^"\']+)["\']', dotAll: true)
            .firstMatch(itemXml);
        String rawDescription = descriptionMatch?.group(1) ?? '';
        final imgInDescriptionMatch = RegExp(r'<img[^>]*src=["\']([^"\']+)["\']', dotAll: true)
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

        // Fallback: try to fetch Open Graph image from the article page
        if (imageUrl.isEmpty && url.isNotEmpty) {
          try {
            final pageResp = await http
                .get(Uri.parse(url))
                .timeout(const Duration(seconds: 3));
            if (pageResp.statusCode == 200) {
              final html = utf8.decode(pageResp.bodyBytes);
              final ogImg = RegExp(
                r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']',
                caseSensitive: false,
              ).firstMatch(html);
              if (ogImg != null) {
                imageUrl = ogImg.group(1)!.trim();
                debugPrint('📰 [RSS] Extracted og:image for ${title.substring(0, math.min(20, title.length))}: $imageUrl');
              }
            }
          } catch (_) {
            // Ignore fallback errors silently
          }
        }

        // Only add if we have a title and URL
        if (title.isNotEmpty && url.isNotEmpty) {
          // Parse the publication date
          final pubDateTimestamp = NewsItem.parsePubDate(pubDateRaw);
          
          // Format date for display
          final formattedDate = pubDateTimestamp != null
              ? _formatDateForDisplay(pubDateTimestamp)
              : pubDateRaw;

          items.add(NewsItem(
            title: title,
            summary: description,
            date: formattedDate,
            url: url,
            imageUrl: imageUrl,
            pubDateTimestamp: pubDateTimestamp,
          ));
        }
      }
      
      debugPrint('📰 [RSS] Parsed ${items.length} items from XML');
      
      // Sort by date (newest first)
      items.sort((a, b) {
        if (a.pubDateTimestamp == null && b.pubDateTimestamp == null) return 0;
        if (a.pubDateTimestamp == null) return 1;
        if (b.pubDateTimestamp == null) return -1;
        return b.pubDateTimestamp!.compareTo(a.pubDateTimestamp!);
      });
      
    } catch (e, stackTrace) {
      debugPrint('❌ [RSS] Error parsing XML: $e');
      debugPrint('❌ [RSS] Stack trace: $stackTrace');
      // Return whatever we've parsed so far
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

    // First decode common HTML entities
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');

    // Now strip any HTML tags that may have appeared after decoding
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    return text.trim();
  }
}

