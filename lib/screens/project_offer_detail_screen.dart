import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/project_offer.dart';
import '../theme/app_theme.dart';

/// Detail screen for project offers with scale animation and card-like design
class ProjectOfferDetailScreen extends StatefulWidget {
  final ProjectOffer projectOffer;
  final String imagePathOrUrl;
  final String heroTag;

  const ProjectOfferDetailScreen({
    super.key,
    required this.projectOffer,
    required this.imagePathOrUrl,
    required this.heroTag,
  });

  @override
  State<ProjectOfferDetailScreen> createState() => _ProjectOfferDetailScreenState();
}

class _ProjectOfferDetailScreenState extends State<ProjectOfferDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
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

  Future<void> _openUrl(String url) async {
    final normalized = url.trim().isEmpty
        ? ''
        : (url.startsWith('http') ? url : 'https://$url');
    if (normalized.isEmpty) return;
    final uri = Uri.parse(normalized);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open link')),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return DateFormat('dd MMMM yyyy', 'en_US').format(date);
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return 'TBD';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = widget.imagePathOrUrl.startsWith('http');
    final isLocalFile = !kIsWeb && !isNetworkImage && widget.imagePathOrUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.projectOffer.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image - same style as card (no animation wrapper to allow smooth Hero transition)
            _buildHeroImage(isNetworkImage, isLocalFile),
            
            // Content Card - same style as project card with scale animation
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: AppRadius.large,
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: widget.projectOffer.location,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 20),

                    // Dates Section
                    if (widget.projectOffer.departureDate != null ||
                        widget.projectOffer.returnDate != null ||
                        widget.projectOffer.expiresAt != null) ...[
                      _buildSectionTitle('📅 Project Dates'),
                      const SizedBox(height: 12),
                      if (widget.projectOffer.departureDate != null) ...[
                        _buildDateCard(
                          'Departure',
                          widget.projectOffer.departureDate,
                          Icons.flight_takeoff,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.projectOffer.returnDate != null) ...[
                        _buildDateCard(
                          'Return',
                          widget.projectOffer.returnDate,
                          Icons.flight_land,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.projectOffer.expiresAt != null) ...[
                        _buildDateCard(
                          'Application Deadline',
                          widget.projectOffer.expiresAt,
                          Icons.event_busy,
                          Colors.red,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],

                    // Duration
                    if (widget.projectOffer.duration != null) ...[
                      _buildInfoCard(
                        icon: Icons.schedule,
                        label: 'Duration',
                        value: widget.projectOffer.duration!,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Target Audience
                    if (widget.projectOffer.targeting.isNotEmpty) ...[
                      _buildSectionTitle('👥 Target Audience'),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.people,
                        label: 'Target',
                        value: widget.projectOffer.targeting,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    if (widget.projectOffer.description.isNotEmpty) ...[
                      _buildSectionTitle('📝 Description'),
                      const SizedBox(height: 12),
                      _buildDescriptionCard(widget.projectOffer.description),
                      const SizedBox(height: 20),
                    ],

                    // Benefits
                    if (widget.projectOffer.benefits.isNotEmpty) ...[
                      _buildSectionTitle('✨ Benefits'),
                      const SizedBox(height: 12),
                      ...widget.projectOffer.benefits.map((benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildBenefitItem(benefit),
                          )),
                      const SizedBox(height: 20),
                    ],

                    // Requirements
                    if (widget.projectOffer.requirements.isNotEmpty) ...[
                      _buildSectionTitle('📋 Requirements'),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.checklist,
                        label: 'Requirements',
                        value: widget.projectOffer.requirements,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Contact Info
                    if (widget.projectOffer.instagramAccount.isNotEmpty) ...[
                      _buildSectionTitle('📱 Contact'),
                      const SizedBox(height: 12),
                      _buildContactCard(),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons - same style as card
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(bool isNetworkImage, bool isLocalFile) {
    return Hero(
      tag: widget.heroTag,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: widget.imagePathOrUrl.isEmpty
            ? Container(
                width: double.infinity,
                height: 180,
                color: Colors.grey[300],
                child: Center(
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
              )
            : isNetworkImage
                ? Image.network(
                    widget.imagePathOrUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    cacheWidth: 800, // Same cache size as card to prevent reloading
                    cacheHeight: 450,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      // If image was loaded synchronously (from cache), show immediately
                      // Otherwise show placeholder until loaded
                      if (wasSynchronouslyLoaded || frame != null) {
                        return child;
                      }
                      return Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 64),
                        ),
                      );
                    },
                  )
                : isLocalFile
                    ? Image.file(
                        File(widget.imagePathOrUrl),
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        cacheWidth: 800, // Same cache size as card to prevent reloading
                        cacheHeight: 450,
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          // If image was loaded synchronously (from cache), show immediately
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }
                          // Show placeholder while loading
                          return Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 64),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 64),
                        ),
                      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime? date, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateShort(date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.pink, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instagram',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${widget.projectOffer.instagramAccount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Infopack Button
        if (widget.projectOffer.infoPackUrl.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openUrl(widget.projectOffer.infoPackUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryYellow,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
                elevation: 0,
              ),
              child: const Text('Infopack'),
            ),
          ),
        if (widget.projectOffer.infoPackUrl.isNotEmpty) const SizedBox(height: 12),

        // Apply Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _openUrl(
              widget.projectOffer.applyLink.isNotEmpty
                  ? widget.projectOffer.applyLink
                  : widget.projectOffer.contactInfo,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
              ),
              elevation: 0,
            ),
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}


