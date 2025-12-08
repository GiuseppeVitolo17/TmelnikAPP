import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/news_item.dart';
import '../screens/news_detail_screen.dart';

/// Reusable card widget for displaying RSS news items.
/// Matches the app's design system (similar style to ProjectCard).
class NewsCard extends StatefulWidget {
  final NewsItem newsItem;
  final int index;

  const NewsCard({
    super.key,
    required this.newsItem,
    this.index = 0,
  });

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 50)),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.newsItem.imageUrl.isNotEmpty;
    final heroTag = 'news_${widget.newsItem.url}_${widget.index}';
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      NewsDetailScreen(
                    newsItem: widget.newsItem,
                    heroTag: heroTag,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 0.1);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;

                    var tween = Tween(begin: begin, end: end).chain(
                      CurveTween(curve: curve),
                    );

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            borderRadius: AppRadius.large,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: AppRadius.large,
                boxShadow: AppShadows.soft,
                border: widget.newsItem.isNew || widget.newsItem.isUpdated
                    ? Border.all(
                        color: widget.newsItem.isNew ? Colors.green : Colors.orange,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image banner (similar to ProjectCard)
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: AppRadius.large.topLeft,
                      ),
                      child: Hero(
                        tag: heroTag,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              widget.newsItem.imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            ),
                            // Gradient overlay for text readability
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
                            // Badges overlay
                            Positioned(
                              top: 12,
                              left: 12,
                              right: 12,
                              child: Row(
                                children: [
                                  // Source badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: widget.newsItem.source == 'Instagram'
                                          ? Colors.pink.withOpacity(0.9)
                                          : Colors.blue.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.newsItem.source == 'Instagram'
                                              ? Icons.camera_alt
                                              : Icons.language,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.newsItem.source,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // New/Updated badges
                                  if (widget.newsItem.isNew)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.fiber_new, size: 14, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'NEW',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (widget.newsItem.isUpdated && !widget.newsItem.isNew)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.update, size: 14, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'UPDATED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Title and date overlay at bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.newsItem.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            offset: Offset(0, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.newsItem.formattedDate.isNotEmpty
                                              ? widget.newsItem.formattedDate
                                              : widget.newsItem.date,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // No image - show card style similar to before
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.newsItem.source == 'Instagram'
                                      ? Colors.pink.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: widget.newsItem.source == 'Instagram'
                                        ? Colors.pink
                                        : Colors.blue,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.newsItem.source == 'Instagram'
                                          ? Icons.camera_alt
                                          : Icons.language,
                                      size: 12,
                                      color: widget.newsItem.source == 'Instagram'
                                          ? Colors.pink[700]
                                          : Colors.blue[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.newsItem.source,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: widget.newsItem.source == 'Instagram'
                                            ? Colors.pink[700]
                                            : Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                widget.newsItem.formattedDate.isNotEmpty
                                    ? widget.newsItem.formattedDate
                                    : widget.newsItem.date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.newsItem.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Content section (only if no image)
                  if (!hasImage)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.newsItem.summary.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.newsItem.summary,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      color: widget.newsItem.source == 'Instagram'
          ? Colors.pink[100]
          : Colors.blue[100],
      child: Center(
        child: Icon(
          widget.newsItem.source == 'Instagram'
              ? Icons.camera_alt
              : Icons.article,
          size: 48,
          color: Colors.grey[600],
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

