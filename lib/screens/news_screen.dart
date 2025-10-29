import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/erasmus_rss_service.dart';
import '../services/news_cache_service.dart';
import '../models/news_item.dart';
import '../widgets/news_card.dart';
import '../theme/app_theme.dart';

/// Screen displaying latest Erasmus+ news articles from RSS feed.
/// Uses cache for offline support and to identify new/updated articles.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ErasmusRssService _rssService = ErasmusRssService();
  final NewsCacheService _cacheService = NewsCacheService();
  List<NewsItem> _newsItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  /// Loads news from cache first, then fetches fresh data if cache is expired
  Future<void> _loadNews({bool forceRefresh = false}) async {
    debugPrint('📰 [NEWS_SCREEN] ========== _loadNews STARTED ==========');
    debugPrint('📰 [NEWS_SCREEN] forceRefresh: $forceRefresh');
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check cache first
      debugPrint('📰 [NEWS_SCREEN] Checking cache...');
      final cachedNews = await _cacheService.getFromCache();
      final isCacheValid = await _cacheService.isCacheValid();

      debugPrint('📰 [NEWS_SCREEN] Cache valid: $isCacheValid, Cached items: ${cachedNews.length}');

      // If cache is valid and not forcing refresh, show cached data immediately
      if (isCacheValid && !forceRefresh && cachedNews.isNotEmpty) {
        debugPrint('📰 [NEWS_SCREEN] ✅ Using cached news (${cachedNews.length} items)');
        setState(() {
          _newsItems = cachedNews;
          _isLoading = false;
        });
      }

      // Fetch fresh data (unless cache is valid and not forcing refresh)
      if (!isCacheValid || forceRefresh) {
        debugPrint('📰 [NEWS_SCREEN] 🔄 Fetching fresh news from RSS feed...');
        final fetchedNews = await _rssService.fetchErasmusNews();
        debugPrint('📰 [NEWS_SCREEN] Fetched ${fetchedNews.length} news items from RSS');

        if (fetchedNews.isEmpty && cachedNews.isNotEmpty) {
          // If fetch failed but we have cache, use cache
          debugPrint('📰 [NEWS_SCREEN] ⚠️ Fetch failed, using cached news');
          setState(() {
            _newsItems = cachedNews;
            _isLoading = false;
          });
        } else if (fetchedNews.isNotEmpty) {
          // Compare with cache to identify new/updated items
          debugPrint('📰 [NEWS_SCREEN] Comparing with cache to identify new/updated items...');
          final comparison = await _cacheService.compareWithCache(fetchedNews);
          
          // Mark new and updated items
          final processedNews = fetchedNews.map((item) {
            final isNew = comparison['new']?.any((n) => n.url == item.url) ?? false;
            final isUpdated = comparison['updated']?.any((n) => n.url == item.url) ?? false;
            
            return item.copyWith(
              isNew: isNew,
              isUpdated: isUpdated,
            );
          }).toList();

          // Save to cache
          debugPrint('📰 [NEWS_SCREEN] Saving to cache...');
          await _cacheService.saveToCache(processedNews);

          debugPrint('📰 [NEWS_SCREEN] ✅ Loaded ${processedNews.length} news items');
          debugPrint('📰 [NEWS_SCREEN] ✨ New items: ${comparison['new']?.length ?? 0}');
          debugPrint('📰 [NEWS_SCREEN] 🔄 Updated items: ${comparison['updated']?.length ?? 0}');
          debugPrint('📰 [NEWS_SCREEN] 📋 Existing items: ${comparison['existing']?.length ?? 0}');
          
          // Log first few items for debugging
          for (int i = 0; i < processedNews.length && i < 3; i++) {
            final item = processedNews[i];
            debugPrint('📰 [NEWS_SCREEN] Item ${i + 1}: "${item.title}" | NEW: ${item.isNew} | UPDATED: ${item.isUpdated} | URL: ${item.url}');
          }

          setState(() {
            _newsItems = processedNews;
            _isLoading = false;
          });
        } else {
          // No news and no cache
          debugPrint('📰 [NEWS_SCREEN] ⚠️ No news found and no cache available');
          setState(() {
            _newsItems = [];
            _isLoading = false;
          });
        }
      } else {
        // Cache is valid, but fetch in background for next time
        debugPrint('📰 [NEWS_SCREEN] 🔄 Cache valid, fetching in background for next time...');
        _rssService.fetchErasmusNews().then((fetchedNews) async {
          if (fetchedNews.isNotEmpty) {
            debugPrint('📰 [NEWS_SCREEN] Background fetch completed: ${fetchedNews.length} items');
            final comparison = await _cacheService.compareWithCache(fetchedNews);
            final processedNews = fetchedNews.map((item) {
              final isNew = comparison['new']?.any((n) => n.url == item.url) ?? false;
              final isUpdated = comparison['updated']?.any((n) => n.url == item.url) ?? false;
              return item.copyWith(isNew: isNew, isUpdated: isUpdated);
            }).toList();
            await _cacheService.saveToCache(processedNews);
            debugPrint('📰 [NEWS_SCREEN] Background cache updated');
          }
        }).catchError((e) {
          debugPrint('📰 [NEWS_SCREEN] ❌ Background fetch error: $e');
        });
      }
      
      debugPrint('📰 [NEWS_SCREEN] ========== _loadNews COMPLETED ==========');
    } catch (e, stackTrace) {
      debugPrint('❌ [NEWS_SCREEN] ========== ERROR in _loadNews ==========');
      debugPrint('❌ [NEWS_SCREEN] Error: $e');
      debugPrint('❌ [NEWS_SCREEN] Stack trace: $stackTrace');
      
      // Try to load from cache as fallback
      debugPrint('📰 [NEWS_SCREEN] Trying to load from cache as fallback...');
      final cachedNews = await _cacheService.getFromCache();
      
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _newsItems = cachedNews;
        _isLoading = false;
      });
      
      debugPrint('📰 [NEWS_SCREEN] Fallback: ${cachedNews.length} cached items loaded');
    }
  }

  /// Marks news items as seen when user scrolls past them
  void _markNewsAsSeen(List<NewsItem> newsItems) {
    final urls = newsItems.map((item) => item.url).toList();
    _cacheService.markAsSeen(urls);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📰 [NEWS_SCREEN] ========== BUILD STARTED ==========');
    debugPrint('📰 [NEWS_SCREEN] _isLoading: $_isLoading, _hasError: $_hasError, _newsItems.length: ${_newsItems.length}');
    
    // Header is managed by MainNavigationScreen
    // This Scaffold only provides background color
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _hasError && _newsItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading news',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _loadNews(forceRefresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _newsItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.newspaper_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No news available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadNews(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _newsItems.length,
                        itemBuilder: (context, index) {
                          final newsItem = _newsItems[index];
                          
                          // Mark as seen when scrolled into view
                          if (index < 5) {
                            _markNewsAsSeen([newsItem]);
                          }
                          
                          return NewsCard(newsItem: newsItem);
                        },
                      ),
                    ),
    );
  }
}
