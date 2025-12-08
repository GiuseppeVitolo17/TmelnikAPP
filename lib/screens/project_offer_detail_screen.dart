import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/project_offer.dart';
import '../theme/app_theme.dart';
import '../services/image_cache_service.dart';

/// Professional detail screen for project offers with smooth animations
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ImageCacheService _imageCacheService = ImageCacheService();
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
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

  Future<void> _refreshImage() async {
    setState(() {
      _isLoadingImage = true;
    });

    try {
      final newImagePath = await _imageCacheService.fetchAndCacheImage(widget.projectOffer.location);
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
        if (newImagePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Immagine aggiornata!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return DateFormat('dd MMMM yyyy', 'it_IT').format(date);
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
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primaryBlue,
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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  Hero(
                    tag: widget.heroTag,
                    child: widget.imagePathOrUrl.isEmpty
                        ? Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : isNetworkImage
                            ? Image.network(
                                widget.imagePathOrUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, size: 64),
                                    ),
                                  );
                                },
                              )
                            : isLocalFile
                                ? FutureBuilder<bool>(
                                    future: File(widget.imagePathOrUrl).exists(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data == true) {
                                        return Image.file(
                                          File(widget.imagePathOrUrl),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(Icons.broken_image, size: 64),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.image_outlined, size: 64),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.image_outlined, size: 64),
                                    ),
                                  ),
                  ),
                  // Gradient overlay
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
                  // Refresh button (if no imageUrl)
                  if (widget.projectOffer.imageUrl.isEmpty)
                    Positioned(
                      top: 100,
                      right: 16,
                      child: FloatingActionButton.small(
                        onPressed: _isLoadingImage ? null : _refreshImage,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: _isLoadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, color: AppColors.primaryBlue),
                      ),
                    ),
                ],
              ),
              title: Text(
                widget.projectOffer.title,
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location and Status
                      _buildInfoRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: widget.projectOffer.location,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 20),

                      // Dates Section
                      _buildSectionTitle('📅 Date del Progetto'),
                      const SizedBox(height: 12),
                      if (widget.projectOffer.departureDate != null ||
                          widget.projectOffer.returnDate != null) ...[
                        _buildDateCard(
                          'Partenza',
                          widget.projectOffer.departureDate,
                          Icons.flight_takeoff,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildDateCard(
                          'Ritorno',
                          widget.projectOffer.returnDate,
                          Icons.flight_land,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.projectOffer.duration != null) ...[
                        _buildInfoCard(
                          icon: Icons.schedule,
                          label: 'Durata',
                          value: widget.projectOffer.duration!,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (widget.projectOffer.expiresAt != null) ...[
                        _buildDateCard(
                          'Scadenza Iscrizioni',
                          widget.projectOffer.expiresAt,
                          Icons.event_busy,
                          Colors.red,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Target Audience
                      if (widget.projectOffer.targeting.isNotEmpty) ...[
                        _buildSectionTitle('👥 Pubblico Target'),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.people,
                          label: 'Destinatari',
                          value: widget.projectOffer.targeting,
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Description
                      if (widget.projectOffer.description.isNotEmpty) ...[
                        _buildSectionTitle('📝 Descrizione'),
                        const SizedBox(height: 12),
                        _buildDescriptionCard(widget.projectOffer.description),
                        const SizedBox(height: 20),
                      ],

                      // Benefits
                      if (widget.projectOffer.benefits.isNotEmpty) ...[
                        _buildSectionTitle('✨ Benefici'),
                        const SizedBox(height: 12),
                        ...widget.projectOffer.benefits.map((benefit) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildBenefitItem(benefit),
                            )),
                        const SizedBox(height: 20),
                      ],

                      // Requirements
                      if (widget.projectOffer.requirements.isNotEmpty) ...[
                        _buildSectionTitle('📋 Requisiti'),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.checklist,
                          label: 'Requisiti',
                          value: widget.projectOffer.requirements,
                          color: Colors.teal,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Contact Info
                      if (widget.projectOffer.instagramAccount.isNotEmpty) ...[
                        _buildSectionTitle('📱 Contatti'),
                        const SizedBox(height: 12),
                        _buildContactCard(),
                        const SizedBox(height: 20),
                      ],

                      // Action Buttons
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
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
            child: ElevatedButton.icon(
              onPressed: () => _openUrl(widget.projectOffer.infoPackUrl),
              icon: const Icon(Icons.description),
              label: const Text('Apri Infopack'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryYellow,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        if (widget.projectOffer.infoPackUrl.isNotEmpty) const SizedBox(height: 12),

        // Apply Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openUrl(
              widget.projectOffer.applyLink.isNotEmpty
                  ? widget.projectOffer.applyLink
                  : widget.projectOffer.contactInfo,
            ),
            icon: const Icon(Icons.send),
            label: const Text('Candidati Ora'),
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
    );
  }
}
