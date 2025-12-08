import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/erasmus_rss_service.dart';
import '../services/aggregated_rss_service.dart';
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
  final AggregatedRssService _rssService = AggregatedRssService();
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
    // STEP 1: Show cache immediately (even if expired) - INSTANT UI
    final cachedNews = await _cacheService.getFromCache();
    
    if (cachedNews.isNotEmpty) {
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
    _fetchAndUpdateNews();
  }

  /// Fetches fresh news and updates UI in batches for better performance
  Future<void> _fetchAndUpdateNews() async {
    try {
      final cachedNews = await _cacheService.getFromCache();
      final List<NewsItem> batchItems = [];
      const int batchSize = 5; // Update UI every 5 items
      
        await _rssService.fetchAggregatedNews(
        onItemFound: (item) async {
          // Collect items in batch instead of updating UI for each
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
            
            batchItems.add(processedItem);
            
            // Update UI in batches for better performance
            if (batchItems.length >= batchSize) {
              setState(() {
                for (final item in batchItems) {
                  _newsItems.removeWhere((existing) => existing.url == item.url);
                  _newsItems.insert(0, item);
                }
                batchItems.clear();
              });
            }
          }
        },
      ).then((fetchedNews) async {
        // Add remaining items in batch
        if (batchItems.isNotEmpty && mounted) {
          setState(() {
            for (final item in batchItems) {
              _newsItems.removeWhere((existing) => existing.url == item.url);
              _newsItems.insert(0, item);
            }
            batchItems.clear();
          });
        }
        if (fetchedNews.isEmpty) {
          return;
        }

        // Final comparison and cache update (non-blocking)
        final comparison = await _cacheService.compareWithCache(fetchedNews);
        
        // Update items with final comparison results
        if (mounted) {
          final finalItems = _newsItems.map((item) {
            final isNew = comparison['new']?.any((n) => n.url == item.url) ?? false;
            final isUpdated = comparison['updated']?.any((n) => n.url == item.url) ?? false;
            return item.copyWith(isNew: isNew, isUpdated: isUpdated);
          }).toList();

          // Save to cache (async, non-blocking)
          _cacheService.saveToCache(finalItems).catchError((_) {
            // Silent fail
          });

          setState(() {
            _newsItems = finalItems;
            _isLoading = false;
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Loads news from cache first, then fetches fresh data if cache is expired
  Future<void> _loadNews({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check cache first
      final cachedNews = await _cacheService.getFromCache();
      final isCacheValid = await _cacheService.isCacheValid();

      // If cache is valid and not forcing refresh, show cached data immediately
      if (isCacheValid && !forceRefresh && cachedNews.isNotEmpty) {
        setState(() {
          _newsItems = cachedNews;
          _isLoading = false;
        });
      }

      // Fetch fresh data (unless cache is valid and not forcing refresh)
      if (!isCacheValid || forceRefresh) {
        // Clear current items when starting fresh (but keep loading state)
        setState(() {
          _newsItems = [];
          _isLoading = true;
        });
        
        final fetchedNews = await _rssService.fetchAggregatedNews(
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
                }
              });
            }
          },
        );

        // Items were already added via callback, now just finalize
        if (fetchedNews.isEmpty && cachedNews.isNotEmpty) {
          // If fetch failed but we have cache, use cache
          setState(() {
            _newsItems = cachedNews;
            _isLoading = false;
          });
        } else if (fetchedNews.isNotEmpty) {
          // Final comparison and cache update
          final comparison = await _cacheService.compareWithCache(fetchedNews);
          
          // Update items with final comparison results
          final finalItems = _newsItems.map((item) {
            final isNew = comparison['new']?.any((n) => n.url == item.url) ?? false;
            final isUpdated = comparison['updated']?.any((n) => n.url == item.url) ?? false;
            return item.copyWith(isNew: isNew, isUpdated: isUpdated);
          }).toList();

          // Save to cache (async, non-blocking)
          _cacheService.saveToCache(finalItems).catchError((_) {
            // Silent fail
          });

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
        _rssService.fetchAggregatedNews().then((fetchedNews) async {
          if (fetchedNews.isNotEmpty) {
            final comparison = await _cacheService.compareWithCache(fetchedNews);
            final processedNews = fetchedNews.map((item) {
              final isNew = comparison['new']?.any((n) => n.url == item.url) ?? false;
              final isUpdated = comparison['updated']?.any((n) => n.url == item.url) ?? false;
              return item.copyWith(isNew: isNew, isUpdated: isUpdated);
            }).toList();
            _cacheService.saveToCache(processedNews).catchError((_) {
              // Silent fail
            });
          }
        }).catchError((_) {
          // Silent fail
        });
      }
    } catch (e, stackTrace) {
      // Try to load from cache as fallback
      final cachedNews = await _cacheService.getFromCache();
      
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _newsItems = cachedNews;
        _isLoading = false;
      });
    }
  }

  /// Marks news items as seen when user scrolls past them
  void _markNewsAsSeen(List<NewsItem> newsItems) {
    final urls = newsItems.map((item) => item.url).toList();
    _cacheService.markAsSeen(urls);
  }

  @override
  Widget build(BuildContext context) {
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
                                  
                                  return NewsCard(newsItem: newsItem, index: index);
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
