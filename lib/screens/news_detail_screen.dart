import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_item.dart';
import '../theme/app_theme.dart';

/// Detail screen for news items with full description
class NewsDetailScreen extends StatelessWidget {
  final NewsItem newsItem;
  final String heroTag;

  const NewsDetailScreen({
    super.key,
    required this.newsItem,
    required this.heroTag,
  });

  Future<void> _openArticle(BuildContext context, String url) async {
    try {
      final sanitized = url.trim();
      final normalized = sanitized.startsWith('http') ? sanitized : 'https://$sanitized';
      final uri = Uri.parse(normalized);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = newsItem.imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: hasImage ? 300 : 150,
            pinned: true,
            backgroundColor: newsItem.source == 'Instagram' 
                ? Colors.pink 
                : AppColors.primaryBlue,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? Hero(
                      tag: heroTag,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            newsItem.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: newsItem.source == 'Instagram'
                                    ? Colors.pink[100]
                                    : Colors.blue[100],
                                child: Center(
                                  child: Icon(
                                    newsItem.source == 'Instagram'
                                        ? Icons.camera_alt
                                        : Icons.article,
                                    size: 64,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: newsItem.source == 'Instagram'
                          ? Colors.pink
                          : AppColors.primaryBlue,
                      child: Center(
                        child: Icon(
                          newsItem.source == 'Instagram'
                              ? Icons.camera_alt
                              : Icons.article,
                          size: 64,
                          color: Colors.white70,
                        ),
                      ),
                    ),
              title: Text(
                newsItem.source,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 72, bottom: 16, right: 16),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: newsItem.source == 'Instagram'
                          ? Colors.pink.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: newsItem.source == 'Instagram'
                            ? Colors.pink
                            : Colors.blue,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          newsItem.source == 'Instagram'
                              ? Icons.camera_alt
                              : Icons.language,
                          size: 16,
                          color: newsItem.source == 'Instagram'
                              ? Colors.pink[700]
                              : Colors.blue[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          newsItem.source,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: newsItem.source == 'Instagram'
                                ? Colors.pink[700]
                                : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    newsItem.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        newsItem.formattedDate.isNotEmpty
                            ? newsItem.formattedDate
                            : newsItem.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (newsItem.summary.isNotEmpty) ...[
                    const Text(
                      'Descrizione',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Text(
                        newsItem.summary,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Open article button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openArticle(context, newsItem.url),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Apri articolo completo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
