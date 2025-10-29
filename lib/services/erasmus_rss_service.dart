import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

      // Filter only articles with /news/ in URL OR just take all items if filtering too strict
      var filteredItems = newsItems
          .where((item) => item.url.contains('/news/'))
          .take(_maxArticles)
          .toList();

      debugPrint('📰 [RSS] Filtered to ${filteredItems.length} items with /news/ in URL');
      
      // If no items with /news/, try to get any items from the feed
      if (filteredItems.isEmpty && newsItems.isNotEmpty) {
        debugPrint('⚠️ [RSS] No items found with /news/ filter. Trying without filter...');
        filteredItems = newsItems.take(_maxArticles).toList();
        debugPrint('📰 [RSS] Using ${filteredItems.length} items without filter');
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
  /// Handles RSS 2.0 format.
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
        final pubDate = _cleanXmlText(pubDateMatch?.group(1) ?? '');
        final description = _cleanXmlText(descriptionMatch?.group(1) ?? '');

        // Only add if we have a title and URL
        if (title.isNotEmpty && url.isNotEmpty) {
          items.add(NewsItem(
            title: title,
            summary: description,
            date: pubDate,
            url: url,
          ));
        }
      }
      
      debugPrint('📰 [RSS] Parsed ${items.length} items from XML');
    } catch (e) {
      debugPrint('❌ [RSS] Error parsing XML: $e');
      // Return whatever we've parsed so far
    }

    return items;
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

