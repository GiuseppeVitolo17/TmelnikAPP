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
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
        border: newsItem.isNew || newsItem.isUpdated
            ? Border.all(
                color: newsItem.isNew ? Colors.green : Colors.orange,
                width: 2,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (newsItem.imageUrl.isNotEmpty)
              Positioned.fill(
                child: Stack(
                  children: [
                    Image.network(
                      newsItem.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              color: newsItem.imageUrl.isEmpty ? AppColors.cardBackground : Colors.transparent,
            ),
            Padding(
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
                      color: newsItem.imageUrl.isNotEmpty ? Colors.white70 : Colors.grey[600],
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: newsItem.imageUrl.isNotEmpty ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Summary (max 3 lines)
            if (newsItem.summary.isNotEmpty)
              Text(
                newsItem.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: newsItem.imageUrl.isNotEmpty ? Colors.white70 : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            if (newsItem.summary.isNotEmpty) const SizedBox(height: 16),
            
            // Read more button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openArticle(context, newsItem.url),
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

  /// Opens the article URL in browser with Android-friendly fallbacks.
  Future<void> _openArticle(BuildContext context, String url) async {
    try {
      final sanitized = url.trim();
      final normalized = sanitized.startsWith('http') ? sanitized : 'https://$sanitized';
      final uri = Uri.parse(normalized);

      // Try external browser first
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }

      // Fallback to platform default (may open a chooser)
      final okDefault = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (okDefault) return;

      // Last resort: try in-app web view if available
      final okInApp = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (okInApp) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the link on this device')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }
}

