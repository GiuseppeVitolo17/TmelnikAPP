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
    _loadNewsOptimized();
  }

  /// Optimized loading: Shows cache immediately, then fetches fresh data in background
  Future<void> _loadNewsOptimized() async {
    debugPrint('📰 [NEWS_SCREEN] ========== _loadNewsOptimized STARTED ==========');
    
    // STEP 1: Show cache immediately (even if expired) - INSTANT UI
    debugPrint('📰 [NEWS_SCREEN] Loading cache for instant display...');
    final cachedNews = await _cacheService.getFromCache();
    
    if (cachedNews.isNotEmpty) {
      debugPrint('📰 [NEWS_SCREEN] ⚡ Showing cached news immediately (${cachedNews.length} items)');
      setState(() {
        _newsItems = cachedNews;
        _isLoading = false; // UI ready immediately!
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    // STEP 2: Fetch fresh data in background (non-blocking)
    debugPrint('📰 [NEWS_SCREEN] 🔄 Fetching fresh news in background...');
    _fetchAndUpdateNews();
  }

  /// Fetches fresh news and updates UI incrementally
  Future<void> _fetchAndUpdateNews() async {
    try {
      final cachedNews = await _cacheService.getFromCache();
      
      await _rssService.fetchErasmusNews(
        onItemFound: (item) async {
          // Add item immediately when found
          if (mounted) {
            // Quick check for new/updated status
            final cachedItem = cachedNews.firstWhere(
              (cached) => cached.url == item.url,
              orElse: () => NewsItem(
                title: '',
                summary: '',
                date: '',
                url: '',
              ),
            );
            
            final isNew = cachedItem.url.isEmpty;
            final isUpdated = cachedItem.url.isNotEmpty && 
                            item.pubDateTimestamp != null && 
                            cachedItem.pubDateTimestamp != null &&
                            item.pubDateTimestamp!.isAfter(cachedItem.pubDateTimestamp!);
            
            final processedItem = item.copyWith(
              isNew: isNew,
              isUpdated: isUpdated,
            );
            
            setState(() {
              // Remove old item if exists, then add new one at the top
              _newsItems.removeWhere((existing) => existing.url == processedItem.url);
              _newsItems.insert(0, processedItem); // Insert at top for newest first
              debugPrint('📰 [NEWS_SCREEN] ⚡ Added item ${_newsItems.length}: ${processedItem.title}');
            });
          }
        },
      ).then((fetchedNews) async {
        if (fetchedNews.isEmpty) {
          debugPrint('📰 [NEWS_SCREEN] ⚠️ No fresh news fetched');
          return;
        }

        // Final comparison and cache update (non-blocking)
        debugPrint('📰 [NEWS_SCREEN] Finalizing cache update...');
        final comparison = await _cacheService.compareWithCache(fetchedNews);
        
        // Update items with final comparison results
        if (mounted) {
          final finalItems = _newsItems.map((item) {
            final isNew = comparison['new']?.any((n) => n.url == item.url) ?? false;
            final isUpdated = comparison['updated']?.any((n) => n.url == item.url) ?? false;
            return item.copyWith(isNew: isNew, isUpdated: isUpdated);
          }).toList();

          // Save to cache (async, non-blocking)
          _cacheService.saveToCache(finalItems).then((_) {
            debugPrint('📰 [NEWS_SCREEN] ✅ Cache updated in background');
          });

          setState(() {
            _newsItems = finalItems;
            _isLoading = false;
          });

          debugPrint('📰 [NEWS_SCREEN] ✅ Updated ${finalItems.length} news items');
        }
      }).catchError((e) {
        debugPrint('📰 [NEWS_SCREEN] ❌ Background fetch error: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ [NEWS_SCREEN] Error in _fetchAndUpdateNews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        
        // Clear current items when starting fresh (but keep loading state)
        setState(() {
          _newsItems = [];
          _isLoading = true;
        });
        
        final fetchedNews = await _rssService.fetchErasmusNews(
          onItemFound: (item) async {
            // Add item immediately when found
            if (mounted) {
              // Check if new/updated asynchronously but add immediately
              final cachedItem = cachedNews.firstWhere(
                (cached) => cached.url == item.url,
                orElse: () => NewsItem(
                  title: '',
                  summary: '',
                  date: '',
                  url: '',
                ),
              );
              
              final isNew = cachedItem.url.isEmpty;
              final isUpdated = cachedItem.url.isNotEmpty && 
                              item.pubDateTimestamp != null && 
                              cachedItem.pubDateTimestamp != null &&
                              item.pubDateTimestamp!.isAfter(cachedItem.pubDateTimestamp!);
              
              final processedItem = item.copyWith(
                isNew: isNew,
                isUpdated: isUpdated,
              );
              
              setState(() {
                if (!_newsItems.any((existing) => existing.url == processedItem.url)) {
                  _newsItems.add(processedItem);
                  debugPrint('📰 [NEWS_SCREEN] ✅ Added item ${_newsItems.length}: ${processedItem.title}');
                }
              });
            }
          },
        );
        debugPrint('📰 [NEWS_SCREEN] Fetched ${fetchedNews.length} news items from RSS');

        // Items were already added via callback, now just finalize
        if (fetchedNews.isEmpty && cachedNews.isNotEmpty) {
          // If fetch failed but we have cache, use cache
          debugPrint('📰 [NEWS_SCREEN] ⚠️ Fetch failed, using cached news');
          setState(() {
            _newsItems = cachedNews;
            _isLoading = false;
          });
        } else if (fetchedNews.isNotEmpty) {
          // Final comparison and cache update
          debugPrint('📰 [NEWS_SCREEN] Finalizing and comparing with cache...');
          final comparison = await _cacheService.compareWithCache(fetchedNews);
          
          // Update items with final comparison results
          final finalItems = _newsItems.map((item) {
            final isNew = comparison['new']?.any((n) => n.url == item.url) ?? false;
            final isUpdated = comparison['updated']?.any((n) => n.url == item.url) ?? false;
            return item.copyWith(isNew: isNew, isUpdated: isUpdated);
          }).toList();

          // Save to cache
          debugPrint('📰 [NEWS_SCREEN] Saving to cache...');
          await _cacheService.saveToCache(finalItems);

          debugPrint('📰 [NEWS_SCREEN] ✅ Loaded ${finalItems.length} news items');
          debugPrint('📰 [NEWS_SCREEN] ✨ New items: ${comparison['new']?.length ?? 0}');
          debugPrint('📰 [NEWS_SCREEN] 🔄 Updated items: ${comparison['updated']?.length ?? 0}');
          debugPrint('📰 [NEWS_SCREEN] 📋 Existing items: ${comparison['existing']?.length ?? 0}');

          setState(() {
            _newsItems = finalItems;
            _isLoading = false;
          });
        } else {
          // No news and no cache
          debugPrint('📰 [NEWS_SCREEN] ⚠️ No news found and no cache available');
          setState(() {
            if (_newsItems.isEmpty) {
              _newsItems = [];
            }
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
      body: _hasError && _newsItems.isEmpty
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
                          onPressed: () => _loadNewsOptimized(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _newsItems.isEmpty && _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
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
                      : Stack(
                          children: [
                            RefreshIndicator(
                              onRefresh: () => _fetchAndUpdateNews(),
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
                            // Show loading indicator at top while fetching in background
                            if (_isLoading && _newsItems.isNotEmpty)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                  ),
                                ),
                              ),
                          ],
                        ),
    );
  }
}
