import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/erasmus_rss_service.dart';
import '../models/news_item.dart';
import '../widgets/news_card.dart';
import '../theme/app_theme.dart';

/// Screen displaying latest Erasmus+ news articles from RSS feed.
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('📰 [NEWS_SCREEN] Building NewsScreen widget');
    
    // Header is managed by MainNavigationScreen
    // This Scaffold only provides background color
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: FutureBuilder<List<NewsItem>>(
        future: ErasmusRssService().fetchErasmusNews(),
        builder: (context, snapshot) {
          debugPrint('📰 [NEWS_SCREEN] FutureBuilder state: ${snapshot.connectionState}');
          debugPrint('📰 [NEWS_SCREEN] Has error: ${snapshot.hasError}');
          debugPrint('📰 [NEWS_SCREEN] Has data: ${snapshot.hasData}');
          
          if (snapshot.hasError) {
            debugPrint('📰 [NEWS_SCREEN] Error: ${snapshot.error}');
            debugPrint('📰 [NEWS_SCREEN] Stack trace: ${snapshot.stackTrace}');
          }
          
          if (snapshot.hasData) {
            debugPrint('📰 [NEWS_SCREEN] News items count: ${snapshot.data?.length ?? 0}');
          }
          
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('📰 [NEWS_SCREEN] Showing loading indicator');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (snapshot.hasError) {
            debugPrint('📰 [NEWS_SCREEN] Showing error state');
            return Center(
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
                  ],
                ),
              ),
            );
          }

          // Success state
          final newsItems = snapshot.data ?? [];
          debugPrint('📰 [NEWS_SCREEN] News items: ${newsItems.length}');

          // Empty state
          if (newsItems.isEmpty) {
            debugPrint('📰 [NEWS_SCREEN] Showing empty state');
            return Center(
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
            );
          }

          // News list
          debugPrint('📰 [NEWS_SCREEN] Building list with ${newsItems.length} items');
          return RefreshIndicator(
            onRefresh: () async {
              // Trigger rebuild by using a new Future
              // In a StatefulWidget, we'd call setState here
              // For StatelessWidget, the parent would need to handle refresh
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: newsItems.length,
              itemBuilder: (context, index) {
                return NewsCard(newsItem: newsItems[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
