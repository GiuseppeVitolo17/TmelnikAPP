import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/project_card.dart';
import '../services/image_cache_service.dart';
import '../services/firebase_firestore_service.dart';
import '../services/user_role_service.dart';
import '../services/notification_service.dart';
import '../services/application_service.dart';
import '../models/project_offer.dart';
import '../theme/app_theme.dart';
import 'add_project_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_project_offer_screen.dart';
import 'project_offer_detail_screen.dart';

class ProjectOffersScreen extends StatefulWidget {
  const ProjectOffersScreen({super.key});

  @override
  State<ProjectOffersScreen> createState() => _ProjectOffersScreenState();
}

class _ProjectOffersScreenState extends State<ProjectOffersScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final NotificationService _notificationService = NotificationService();
  final ImageCacheService _imageCacheService = ImageCacheService();
  bool _isAdmin = false;
  bool _isLoadingAdmin = true;
  
  // Track previously seen project IDs to detect new ones
  final Set<String> _seenProjectIds = {};
  // Track image cache refresh timestamps per city to force FutureBuilder rebuild
  final Map<String, int> _imageCacheTimestamps = {};
  // Track loading state per city
  final Map<String, bool> _imageLoadingStates = {};

  @override
  void initState() {
    super.initState();
    // Check admin status in background (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus();
    });
  }

  /// Gets cached image or automatically fetches from API if not in cache
  Future<String?> _getOrFetchCityImage(String city) async {
    // First, try to get from cache
    final cachedImage = await _imageCacheService.getCachedImage(city);
    
    if (cachedImage != null && cachedImage.isNotEmpty) {
      // Image is in cache, return it
      return cachedImage;
    }
    
    // Not in cache - automatically fetch from API
    try {
      debugPrint('🔄 [IMAGE] Auto-fetching image for city: $city (not in cache)');
      final fetchedImage = await _imageCacheService.fetchAndCacheImage(city);
      
      if (fetchedImage != null && fetchedImage.isNotEmpty) {
        // Update timestamp to force rebuild
        if (mounted) {
          setState(() {
            _imageCacheTimestamps[city] = DateTime.now().millisecondsSinceEpoch;
          });
        }
        return fetchedImage;
      }
    } catch (e) {
      debugPrint('❌ [IMAGE] Error auto-fetching image for $city: $e');
    }
    
    // Return null if fetch failed
    return null;
  }

  Future<void> _checkAdminStatus() async {
    // Don't block UI - check in background
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final isAdmin = await userRoleService.isCurrentUserAdmin().timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );
        if (mounted) {
          setState(() {
            _isAdmin = isAdmin;
            _isLoadingAdmin = false;
          });
        }
      } catch (e) {
        // Silent fail - default to non-admin
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _isLoadingAdmin = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoadingAdmin = false;
        });
      }
    }
  }

  /// Check for new projects and show notifications
  void _checkForNewProjects(List<ProjectOffer> currentOffers) {
    for (final offer in currentOffers) {
      // If we haven't seen this project ID before, it's new!
      if (!_seenProjectIds.contains(offer.id) && offer.id.isNotEmpty) {
        _seenProjectIds.add(offer.id);
        
        // Format departure date
        final departureDate = offer.departureDate != null
            ? NotificationService.formatDateForNotification(offer.departureDate!)
            : 'TBD';
        
        // Show notification
        _notificationService.showNewProjectNotification(
          projectName: offer.title,
          cityName: offer.location.isNotEmpty ? offer.location : 'Unknown',
          departureDate: departureDate,
        );
        
        // In-app popups disabled by request
  }
    }
  }

  String _formatDates(ProjectOffer offer) {
    if (offer.departureDate != null && offer.returnDate != null) {
      final depMonth = offer.departureDate!.month;
      final depDay = offer.departureDate!.day;
      final retMonth = offer.returnDate!.month;
      final retDay = offer.returnDate!.day;
      return '$depDay ${_getMonthName(depMonth)} / $retDay ${_getMonthName(retMonth)}';
    } else if (offer.duration != null) {
      return offer.duration!;
    } else {
      return 'Dates TBD';
    }
  }

  String? _formatDeadline(ProjectOffer offer) {
    if (offer.expiresAt != null) {
      final day = offer.expiresAt!.day;
      final month = offer.expiresAt!.month;
      return '$day ${_getMonthName(month)}';
    }
    return null;
  }


  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> _handleDelete(ProjectOffer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteProjectOffer(offer.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting project: $e'),
              backgroundColor: Colors.red,
                  ),
          );
        }
      }
    }
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
        // Fallback using string API
        // ignore: deprecated_member_use
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


  @override
  Widget build(BuildContext context) {
    // Header is now managed by MainNavigationScreen
    // This Scaffold only provides background color
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: StreamBuilder<List<ProjectOffer>>(
        stream: _firestoreService.getProjectOffersStream(),
        builder: (context, snapshot) {
          final firestoreOffers = snapshot.data ?? [];

          // Detect new projects and show notifications
          if (snapshot.hasData && firestoreOffers.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkForNewProjects(firestoreOffers);
            });
          }
          
          return ListView(
                    padding: const EdgeInsets.all(16),
                      children: [
                    // Debug info (remove in production)
                    if (snapshot.hasError)
                            Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                          color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                              ),
                              child: Text(
                          'Error loading projects: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                              ),
                            ),
                    
                    // Firestore projects (created by admins)
              ...firestoreOffers.map((offer) {
                // Get image - use offer.imageUrl if available, otherwise fetch from cache or API
                final hasImageUrl = offer.imageUrl.isNotEmpty;
                
                // Build widget with automatic image fetching if not in cache
                return FutureBuilder<String?>(
                  future: hasImageUrl 
                      ? Future.value(offer.imageUrl)
                      : _getOrFetchCityImage(offer.location), // Auto-fetch if not in cache
                  builder: (context, snapshot) {
                    String imagePath = '';
                    bool isLoading = false;
                    
                    if (hasImageUrl) {
                      imagePath = offer.imageUrl;
                    } else if (snapshot.connectionState == ConnectionState.waiting) {
                      // Loading from cache or fetching from API
                      isLoading = true;
                      imagePath = '';
                    } else if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      // Image found in cache or fetched from API
                      imagePath = snapshot.data!;
                    } else {
                      // No image available (fetch failed or no cache)
                      imagePath = '';
                    }

                    final heroTag = 'project_${offer.id}_${offer.location}';
                    
                    return ProjectCard(
                      imagePathOrUrl: imagePath,
                      title: offer.title,
                      dates: _formatDates(offer),
                      deadline: _formatDeadline(offer),
                      heroTag: heroTag,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectOfferDetailScreen(
                              projectOffer: offer,
                              imagePathOrUrl: imagePath,
                              heroTag: heroTag,
                            ),
                          ),
                        );
                      },
                      onApply: () async {
                        // Save application if user is logged in
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          try {
                            final applicationService = ApplicationService();
                            await applicationService.applyToProject(offer);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Application saved!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            // If already applied, continue to open link
                            if (!e.toString().contains('already applied') && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Note: $e'),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        }
                        // Always open the apply link
                        _openUrl(offer.applyLink.isNotEmpty ? offer.applyLink : offer.contactInfo);
                      },
                      onInfo: () => _openUrl(offer.infoPackUrl),
                      showAdminActions: _isAdmin,
                      onEdit: _isAdmin ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProjectOfferScreen(
                              projectId: offer.id,
                              ),
                        ),
                        ).then((_) => setState(() {}));
                      } : null,
                      onDelete: _isAdmin ? () => _handleDelete(offer) : null,
                      onImageTap: hasImageUrl ? null : () async {
                        // Show loading indicator
                        setState(() {
                          _imageLoadingStates[offer.location] = true;
                        });
                        
                        try {
                          // Fetch and cache new image (manual refresh)
                          await _imageCacheService.fetchAndCacheImage(offer.location);
                          
                          if (mounted) {
                            // Update timestamp to force FutureBuilder rebuild
                            setState(() {
                              _imageCacheTimestamps[offer.location] = DateTime.now().millisecondsSinceEpoch;
                              _imageLoadingStates[offer.location] = false;
                            });
                          }
                        } catch (e) {
                          debugPrint('Error loading image: $e');
                          if (mounted) {
                            setState(() {
                              _imageLoadingStates[offer.location] = false;
                            });
                          }
                        }
                      },
                      isLoadingImage: isLoading || (_imageLoadingStates[offer.location] ?? false),
                    );
                  },
                );
              }),
                                ],
          );
        },
      ),
      floatingActionButton: _isAdmin && !_isLoadingAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProjectScreen(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
                );
  }
}