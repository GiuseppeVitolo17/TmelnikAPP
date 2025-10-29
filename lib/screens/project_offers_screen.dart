import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/project_card.dart';
import '../services/pexels_service.dart';
import '../services/firebase_firestore_service.dart';
import '../services/user_role_service.dart';
import '../services/notification_service.dart';
import '../models/project_offer.dart';
import '../theme/app_theme.dart';
import 'add_project_screen.dart';
import 'edit_project_offer_screen.dart';

class ProjectOffersScreen extends StatefulWidget {
  const ProjectOffersScreen({super.key});

  @override
  State<ProjectOffersScreen> createState() => _ProjectOffersScreenState();
}

class _ProjectOffersScreenState extends State<ProjectOffersScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final NotificationService _notificationService = NotificationService();
  bool _isAdmin = false;
  bool _isLoadingAdmin = true;
  
  // Track previously seen project IDs to detect new ones
  final Set<String> _seenProjectIds = {};
  
  // Proxy projects (hardcoded examples)
  final List<Map<String, String>> _proxyProjects = [
    {
      'title': 'Project Berlin',
      'dates': '14 July / 19 July',
      'city': 'Berlin',
      'deadline': '10 July', // Application deadline
    },
    {
      'title': 'Project Brno',
      'dates': '17 July / 25 July',
      'city': 'Brno',
      'deadline': '12 July', // Application deadline
    },
    {
      'title': 'Project Krakow',
      'dates': '27 July / 3 August',
      'city': 'Krakow',
      'deadline': '20 July', // Application deadline
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    if (FirebaseAuth.instance.currentUser != null) {
      final isAdmin = await userRoleService.isCurrentUserAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoadingAdmin = false;
        });
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
        
        // Also show in-app SnackBar notification
        if (mounted) {
          final message = NotificationService.getRandomMessage(
            offer.title,
            offer.location.isNotEmpty ? offer.location : 'Unknown',
            departureDate,
          );
          
      ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue[600],
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  // Scroll to project or highlight it
                },
              ),
        ),
      );
    }
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

  String? _formatDeadlineFromString(String? deadlineStr) {
    // For proxy projects, deadline is already formatted
    return deadlineStr;
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

  void _handleApply(String projectTitle, {String? projectId}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apply button tapped for $projectTitle'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleInfo(String projectTitle, {String? projectId}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Infopack button tapped for $projectTitle'),
        duration: const Duration(seconds: 2),
      ),
    );
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
          // Debug logging
          if (snapshot.hasError) {
            debugPrint('❌ StreamBuilder error: ${snapshot.error}');
            debugPrint('❌ Error stack: ${snapshot.error.toString()}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('⏳ StreamBuilder: waiting for data');
          }
          
          final firestoreOffers = snapshot.data ?? [];
          debugPrint('✅ Firestore offers count: ${firestoreOffers.length}');
          debugPrint('✅ Is admin: $_isAdmin');
          if (firestoreOffers.isNotEmpty) {
            debugPrint('✅ First offer: ${firestoreOffers[0].title} (ID: ${firestoreOffers[0].id})');
          }

          // Detect new projects and show notifications
          if (snapshot.hasData && firestoreOffers.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkForNewProjects(firestoreOffers);
            });
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
                    // Debug info (rimuovere in produzione)
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
                    
                    // Proxy projects (hardcoded examples)
                    ..._proxyProjects.map((project) {
                final city = project['city']!;
                final title = project['title']!;
                final dates = project['dates']!;

                return FutureBuilder<String>(
                  future: PexelsService.fetchCityImageUrl(city),
                  builder: (context, snapshot) {
                    String imagePath;
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      imagePath = '';
                    } else if (snapshot.hasData) {
                      imagePath = snapshot.data!;
                    } else {
                      imagePath = '';
                    }

                    return ProjectCard(
                      imagePathOrUrl: imagePath,
                      title: title,
                      dates: dates,
                      deadline: _formatDeadlineFromString(project['deadline']),
                      onApply: () => _handleApply(title),
                      onInfo: () => _handleInfo(title),
                    );
                  },
                );
              }),
              
              // Firestore projects (created by admins)
              ...firestoreOffers.map((offer) {
                // Get image - use offer.imageUrl if available, otherwise fetch from Pexels by location
                final hasImageUrl = offer.imageUrl.isNotEmpty;
                
                return FutureBuilder<String>(
                  future: hasImageUrl 
                      ? Future.value(offer.imageUrl)
                      : PexelsService.fetchCityImageUrl(offer.location),
                  builder: (context, snapshot) {
                    String imagePath = '';
                    
                    if (hasImageUrl) {
                      imagePath = offer.imageUrl;
                    } else if (snapshot.connectionState == ConnectionState.waiting) {
                      imagePath = '';
                    } else if (snapshot.hasData) {
                      imagePath = snapshot.data!;
                    } else {
                      imagePath = '';
                    }

                    return ProjectCard(
                      imagePathOrUrl: imagePath,
                      title: offer.title,
                      dates: _formatDates(offer),
                      deadline: _formatDeadline(offer),
                      onApply: () => _handleApply(offer.title, projectId: offer.id),
                      onInfo: () => _handleInfo(offer.title, projectId: offer.id),
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