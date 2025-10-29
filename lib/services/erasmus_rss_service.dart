import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/news_item.dart';

/// Service for fetching and parsing Erasmus+ RSS feed.
/// This service is completely stateless and independent from Firebase.
class ErasmusRssService {
  static const String _rssUrl = 'https://erasmus-plus.ec.europa.eu/rss.xml';
  static const int _maxArticles = 10;

  /// Fetches and parses the Erasmus+ RSS feed.
  /// Returns a list of NewsItem objects, filtered to only include /news/ articles.
  /// Returns empty list if request fails or parsing fails.
  Future<List<NewsItem>> fetchErasmusNews() async {
    debugPrint('📰 [RSS] Starting to fetch Erasmus+ news from $_rssUrl');
    
    try {
      // Fetch RSS feed
      debugPrint('📰 [RSS] Making HTTP request...');
      final response = await http.get(Uri.parse(_rssUrl));
      
      debugPrint('📰 [RSS] HTTP response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        debugPrint('❌ [RSS] HTTP request failed with status ${response.statusCode}');
        return [];
      }

      // Parse XML manually (simple parsing for RSS 2.0)
      final xmlString = utf8.decode(response.bodyBytes);
      debugPrint('📰 [RSS] XML length: ${xmlString.length} characters');
      
      final newsItems = _parseRssXml(xmlString);
      debugPrint('📰 [RSS] Parsed ${newsItems.length} items from RSS');
      
      // Log sample URLs for debugging
      if (newsItems.isNotEmpty) {
        debugPrint('📰 [RSS] Sample URLs from feed:');
        for (int i = 0; i < newsItems.length && i < 5; i++) {
          debugPrint('📰 [RSS]   ${i + 1}. ${newsItems[i].url}');
        }
      }

      // Filter articles: only include /news/ pages, exclude documents, help/support pages
      var filteredItems = newsItems
          .where((item) {
            final url = item.url.toLowerCase();
            // Only include news pages, exclude documents and other pages
            final isRelevant = url.contains('/news/') && 
                            !url.contains('/document/') &&
                            !url.contains('/help') &&
                            !url.contains('/support') &&
                            !url.contains('/eche/');
            
            if (isRelevant) {
              debugPrint('📰 [RSS] ✅ Included news item: ${item.title}');
            } else {
              debugPrint('📰 [RSS] ❌ Excluded: ${item.title} (URL: $url)');
            }
            
            return isRelevant;
          })
          .take(_maxArticles)
          .toList();

      debugPrint('📰 [RSS] Filtered to ${filteredItems.length} news items (excluding documents)');
      
      // If no news items found, try to get any relevant items (excluding documents and help pages)
      if (filteredItems.isEmpty && newsItems.isNotEmpty) {
        debugPrint('⚠️ [RSS] No /news/ items found. Getting most recent items (excluding documents)...');
        filteredItems = newsItems
            .where((item) {
              final url = item.url.toLowerCase();
              final include = !url.contains('/document/') &&
                     !url.contains('/help') && 
                     !url.contains('/support') &&
                     !url.contains('/eche/assessment-type');
              if (include) {
                debugPrint('📰 [RSS] ✅ Included (fallback): ${item.title}');
              }
              return include;
            })
            .take(_maxArticles)
            .toList();
        debugPrint('📰 [RSS] Using ${filteredItems.length} items without strict /news/ filter');
      }
      
      if (filteredItems.isNotEmpty) {
        debugPrint('📰 [RSS] First item: ${filteredItems[0].title}');
        debugPrint('📰 [RSS] First item URL: ${filteredItems[0].url}');
      } else {
        debugPrint('⚠️ [RSS] No items found after filtering. Total parsed: ${newsItems.length}');
        if (newsItems.isNotEmpty) {
          debugPrint('📰 [RSS] Sample URLs: ${newsItems.take(3).map((e) => e.url).join(", ")}');
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

        final title = _cleanXmlText(titleMatch?.group(1) ?? '');
        final url = _cleanXmlText(linkMatch?.group(1) ?? '');
        final pubDateRaw = _cleanXmlText(pubDateMatch?.group(1) ?? '');
        final description = _cleanXmlText(descriptionMatch?.group(1) ?? '');

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
    text = text.replaceAll(RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true), '$1');
    
    // Remove HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode common HTML entities
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    
    return text.trim();
  }
}

