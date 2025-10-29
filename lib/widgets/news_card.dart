import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/news_item.dart';

/// Reusable card widget for displaying RSS news items.
/// Matches the app's design system (similar style to ProjectCard).
class NewsCard extends StatelessWidget {
  final NewsItem newsItem;

  const NewsCard({
    super.key,
    required this.newsItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
        border: newsItem.isNew || newsItem.isUpdated
            ? Border.all(
                color: newsItem.isNew ? Colors.green : Colors.orange,
                width: 2,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and status badges row
            Row(
              children: [
                // Date
                Expanded(
                  child: Text(
                    newsItem.formattedDate.isNotEmpty 
                        ? newsItem.formattedDate
                        : newsItem.date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                // New/Updated badges
                if (newsItem.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (newsItem.isUpdated && !newsItem.isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'UPDATED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              newsItem.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Summary (max 3 lines)
            if (newsItem.summary.isNotEmpty)
              Text(
                newsItem.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            if (newsItem.summary.isNotEmpty) const SizedBox(height: 16),
            
            // Read more button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openArticle(newsItem.url),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                ),
                child: const Text(
                  'Read more',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats the date string for display (deprecated - use newsItem.formattedDate instead).
  @Deprecated('Use newsItem.formattedDate instead')
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      // Try to parse RFC 2822 date format (common in RSS)
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      // If parsing fails, return original string or first part
      return dateStr.length > 20 ? dateStr.substring(0, 20) : dateStr;
    }
  }

  /// Opens the article URL in browser.
  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

