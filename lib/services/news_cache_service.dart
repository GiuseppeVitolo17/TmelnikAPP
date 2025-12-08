import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_item.dart';

/// Professional service for managing news cache and tracking new/updated articles.
/// 
/// This service:
/// - Caches news items locally using SharedPreferences
/// - Tracks seen/read news by URL
/// - Identifies new and updated articles by comparing pubDates
/// - Provides efficient cache management with expiration
class NewsCacheService {
  static const String _cacheKey = 'aggregated_news_cache';
  static const String _seenNewsKey = 'aggregated_seen_news';
  static const String _lastFetchKey = 'aggregated_last_fetch';
  static const String _cacheCreationKey = 'aggregated_cache_creation';
  static const Duration _cacheExpiration = Duration(hours: 1); // For refresh check
  static const Duration _cacheMaxAge = Duration(days: 60); // 2 months - auto cleanup

  /// Saves news items to cache with timestamps
  /// Automatically cleans old items (> 2 months) before saving
  Future<void> saveToCache(List<NewsItem> newsItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Filter out items older than 2 months
      final validItems = newsItems.where((item) {
        if (item.pubDateTimestamp == null) return true; // Keep items without date
        final age = now.difference(item.pubDateTimestamp!);
        return age < _cacheMaxAge;
      }).toList();
      
      // Check if this is first cache creation
      final cacheCreation = prefs.getInt(_cacheCreationKey);
      if (cacheCreation == null) {
        await prefs.setInt(_cacheCreationKey, now.millisecondsSinceEpoch);
      } else {
        // Check if cache is older than 2 months - reset it
        final cacheAge = now.difference(
          DateTime.fromMillisecondsSinceEpoch(cacheCreation)
        );
        if (cacheAge >= _cacheMaxAge) {
          // Reset cache - clear everything
          await clearCache();
          await prefs.setInt(_cacheCreationKey, now.millisecondsSinceEpoch);
          debugPrint('🔄 [CACHE] Cache reset after 2 months');
        }
      }
      
      // Convert news items to JSON
      final newsJson = validItems.map((item) => {
        'title': item.title,
        'summary': item.summary,
        'date': item.date,
        'url': item.url,
        'imageUrl': item.imageUrl,
        'pubDateTimestamp': item.pubDateTimestamp?.millisecondsSinceEpoch,
        'source': item.source,
      }).toList();
      
      await prefs.setString(_cacheKey, jsonEncode(newsJson));
      await prefs.setInt(_lastFetchKey, now.millisecondsSinceEpoch);
      
      if (validItems.length < newsItems.length) {
        debugPrint('💾 [CACHE] Saved ${validItems.length} news items (removed ${newsItems.length - validItems.length} items older than 2 months)');
      } else {
        debugPrint('💾 [CACHE] Saved ${validItems.length} news items to cache');
      }
    } catch (e) {
      debugPrint('❌ [CACHE] Error saving to cache: $e');
    }
  }

  /// Retrieves cached news items, filtering out items older than 2 months
  Future<List<NewsItem>> getFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);
      
      if (cacheString == null) {
        return [];
      }

      final now = DateTime.now();
      final newsJson = jsonDecode(cacheString) as List<dynamic>;
      final newsItems = newsJson.map((json) {
        final map = json as Map<String, dynamic>;
        return NewsItem(
          title: map['title'] ?? '',
          summary: map['summary'] ?? '',
          date: map['date'] ?? '',
          url: map['url'] ?? '',
          imageUrl: map['imageUrl'] ?? '',
          pubDateTimestamp: map['pubDateTimestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['pubDateTimestamp'] as int)
              : null,
          source: map['source'] ?? 'EU',
        );
      }).where((item) {
        // Filter out items older than 2 months
        if (item.pubDateTimestamp == null) return true;
        final age = now.difference(item.pubDateTimestamp!);
        return age < _cacheMaxAge;
      }).toList();
      
      // If we filtered items, save the cleaned cache
      if (newsItems.length < newsJson.length) {
        saveToCache(newsItems).catchError((_) {});
      }
      
      return newsItems;
    } catch (e) {
      return [];
    }
  }

  /// Checks if cache is valid (not expired)
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt(_lastFetchKey);
      
      if (lastFetch == null) {
        return false;
      }

      final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
      final now = DateTime.now();
      final isValid = now.difference(lastFetchTime) < _cacheExpiration;
      
      debugPrint('💾 [CACHE] Cache validity: $isValid (age: ${now.difference(lastFetchTime).inMinutes} minutes)');
      return isValid;
    } catch (e) {
      debugPrint('❌ [CACHE] Error checking cache validity: $e');
      return false;
    }
  }

  /// Marks news items as seen
  Future<void> markAsSeen(List<String> urls) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenUrls = prefs.getStringList(_seenNewsKey) ?? [];
      
      for (final url in urls) {
        if (!seenUrls.contains(url)) {
          seenUrls.add(url);
        }
      }
      
      await prefs.setStringList(_seenNewsKey, seenUrls);
      debugPrint('👁️ [CACHE] Marked ${urls.length} news items as seen');
    } catch (e) {
      debugPrint('❌ [CACHE] Error marking as seen: $e');
    }
  }

  /// Checks if a news item is seen
  Future<bool> isSeen(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenUrls = prefs.getStringList(_seenNewsKey) ?? [];
      return seenUrls.contains(url);
    } catch (e) {
      debugPrint('❌ [CACHE] Error checking seen status: $e');
      return false;
    }
  }

  /// Gets list of seen news URLs
  Future<List<String>> getSeenUrls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_seenNewsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Compares fetched news with cached news to identify new/updated items
  /// Returns a map with 'new' and 'updated' lists
  Future<Map<String, List<NewsItem>>> compareWithCache(List<NewsItem> fetchedNews) async {
    try {
      final cachedNews = await getFromCache();
      final seenUrls = await getSeenUrls();
      
      final Map<String, NewsItem> cachedByUrl = {};
      for (final item in cachedNews) {
        cachedByUrl[item.url] = item;
      }

      final List<NewsItem> newItems = [];
      final List<NewsItem> updatedItems = [];
      final List<NewsItem> existingItems = [];

      for (final fetchedItem in fetchedNews) {
        final cachedItem = cachedByUrl[fetchedItem.url];
        
        if (cachedItem == null) {
          // This is a completely new item
          newItems.add(fetchedItem);
        } else {
          // Check if the date was updated
          final fetchedDate = fetchedItem.pubDateTimestamp;
          final cachedDate = cachedItem.pubDateTimestamp;
          
          if (fetchedDate != null && cachedDate != null) {
            if (fetchedDate.isAfter(cachedDate)) {
              // Item exists but has a newer publication date
              updatedItems.add(fetchedItem);
            } else {
              // Item exists and hasn't changed
              existingItems.add(fetchedItem);
            }
          } else {
            // Can't compare dates, treat as existing
            existingItems.add(fetchedItem);
          }
        }
      }

      debugPrint('📊 [CACHE] Comparison: ${newItems.length} new, ${updatedItems.length} updated, ${existingItems.length} existing');
      
      return {
        'new': newItems,
        'updated': updatedItems,
        'existing': existingItems,
      };
    } catch (e) {
      debugPrint('❌ [CACHE] Error comparing with cache: $e');
      return {
        'new': fetchedNews,
        'updated': [],
        'existing': [],
      };
    }
  }

  /// Clears all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastFetchKey);
      debugPrint('🗑️ [CACHE] Cache cleared');
    } catch (e) {
      debugPrint('❌ [CACHE] Error clearing cache: $e');
    }
  }

  /// Clears seen news history
  Future<void> clearSeenHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_seenNewsKey);
      debugPrint('🗑️ [CACHE] Seen history cleared');
    } catch (e) {
      debugPrint('❌ [CACHE] Error clearing seen history: $e');
    }
  }
}

