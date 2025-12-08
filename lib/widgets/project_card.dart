import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';

/// Reusable card widget for displaying project information
/// with modern design: rounded white card, shadow, image banner, and action buttons
class ProjectCard extends StatelessWidget {
  final String imagePathOrUrl;
  final String title;
  final String dates;
  final String? deadline; // Application deadline (optional)
  final VoidCallback onApply;
  final VoidCallback onInfo;
  
  // Admin-only actions (only shown if callbacks are provided)
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showAdminActions;
  
  // Image tap callback (for refreshing cached images)
  final VoidCallback? onImageTap;
  // Loading state for image refresh
  final bool isLoadingImage;
  // Card tap callback (for navigation to detail screen)
  final VoidCallback? onTap;
  // Hero tag for image animation
  final String? heroTag;

  const ProjectCard({
    super.key,
    required this.imagePathOrUrl,
    required this.title,
    required this.dates,
    this.deadline,
    required this.onApply,
    required this.onInfo,
    this.onEdit,
    this.onDelete,
    this.showAdminActions = false,
    this.onImageTap,
    this.isLoadingImage = false,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty string (fallback) - show placeholder directly (always tappable if callback provided)
    if (imagePathOrUrl.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppRadius.large,
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceholderImage(),
            _buildCardContent(),
          ],
        ),
      );
    }
    
    final isNetworkImage = imagePathOrUrl.startsWith('http');
    final isLocalFile = !kIsWeb && !isNetworkImage && imagePathOrUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: AppRadius.large,
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image banner with rounded top corners only
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: AppRadius.large.topLeft,
                ),
                child: Stack(
                children: [
                  // Loading overlay
                  if (isLoadingImage)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  isNetworkImage
                      ? Hero(
                          tag: heroTag ?? 'project_image_${imagePathOrUrl}',
                          child: Image.network(
                            imagePathOrUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Text('Loading...'),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          ),
                        )
                      : isLocalFile
                          ? FutureBuilder<bool>(
                              future: File(imagePathOrUrl).exists(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data == true) {
                                  return Hero(
                                    tag: heroTag ?? 'project_image_${imagePathOrUrl}',
                                    child: Image.file(
                                      File(imagePathOrUrl),
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildPlaceholderImage();
                                      },
                                    ),
                                  );
                                }
                                return _buildPlaceholderImage();
                              },
                            )
                          : Hero(
                              tag: heroTag ?? 'project_image_${imagePathOrUrl}',
                              child: Image.asset(
                                imagePathOrUrl,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage();
                                },
                              ),
                            ),
                ],
                ),
              ),
          
          // Content section
          _buildCardContent(),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          
          // Date range
          Text(
            dates,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          // Deadline (if provided)
          if (deadline != null && deadline!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 6),
                Text(
                  'Deadline: $deadline',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          
          // Admin actions row (if enabled and callbacks provided) - ben visibili in primo piano
          if (showAdminActions && (onEdit != null || onDelete != null)) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 12),
                  if (onDelete != null)
                    ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Action buttons row - MUST be side by side
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Infopack button (yellow background, black text)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryYellow,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text('Infopack'),
                  ),
                ),
                const SizedBox(width: 12),
                // Apply button (blue background, white text)
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Hero(
      tag: heroTag ?? 'project_placeholder_${title}',
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: AppRadius.large.topLeft,
        ),
        child: Container(
          width: double.infinity,
          height: 180,
          color: Colors.grey[300],
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoadingImage)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
