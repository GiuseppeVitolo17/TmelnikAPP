import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_application.dart';
import '../models/project_offer.dart';
import '../services/application_service.dart';
import '../services/user_role_service.dart';
import '../services/ngo_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Screen for organizers to view applications to their organization's projects
class ProjectApplicationsScreen extends StatefulWidget {
  final String? ngoId; // Filter by specific NGO (optional)
  
  const ProjectApplicationsScreen({
    super.key,
    this.ngoId,
  });

  @override
  State<ProjectApplicationsScreen> createState() => _ProjectApplicationsScreenState();
}

class _ProjectApplicationsScreenState extends State<ProjectApplicationsScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final UserRoleService _userRoleService = UserRoleService();
  final NGOService _ngoService = NGOService();
  String? _currentUserNgoId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserNGO();
  }

  Future<void> _loadUserNGO() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userRole = await _userRoleService.getUserRole(user.uid);
      if (userRole?.isOrganizer == true && userRole?.ngoId != null) {
        setState(() {
          _currentUserNgoId = userRole!.ngoId;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user NGO: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Get the NGO ID to filter by
  String? get _filterNgoId {
    return widget.ngoId ?? _currentUserNgoId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Project Applications'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filterNgoId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No organization found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You need to be an organizer to view applications',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : StreamBuilder<List<ProjectApplication>>(
                  stream: _applicationService.getApplicationsForNGO(_filterNgoId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error loading applications: ${snapshot.error}'),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final applications = snapshot.data ?? [];

                    if (applications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No applications yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Applications will appear here when users apply to your projects',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    // Group applications by project
                    final groupedByProject = <String, List<ProjectApplication>>{};
                    for (final app in applications) {
                      if (!groupedByProject.containsKey(app.projectId)) {
                        groupedByProject[app.projectId] = [];
                      }
                      groupedByProject[app.projectId]!.add(app);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedByProject.length,
                      itemBuilder: (context, index) {
                        final projectId = groupedByProject.keys.elementAt(index);
                        final projectApplications = groupedByProject[projectId]!;
                        final firstApp = projectApplications.first;

                        return _buildProjectApplicationsCard(
                          projectId: projectId,
                          projectTitle: firstApp.projectTitle,
                          applications: projectApplications,
                        );
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildProjectApplicationsCard({
    required String projectId,
    required String projectTitle,
    required List<ProjectApplication> applications,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
          child: Icon(
            Icons.work,
            color: AppColors.primaryBlue,
          ),
        ),
        title: Text(
          projectTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${applications.length} ${applications.length == 1 ? 'application' : 'applications'}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${applications.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        children: applications.map((app) => _buildApplicationTile(app)).toList(),
      ),
    );
  }

  Widget _buildApplicationTile(ProjectApplication application) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: application.status.color.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: application.status.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  application.userEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      application.status.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      application.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: application.status.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(application.appliedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 20),
            itemBuilder: (context) => [
              if (application.status == ApplicationStatus.pending) ...[
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Accept'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _updateApplicationStatus(application, ApplicationStatus.accepted),
                  ),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.cancel, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Reject'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _updateApplicationStatus(application, ApplicationStatus.rejected),
                  ),
                ),
              ],
              if (application.status != ApplicationStatus.pending)
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Reset to Pending'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _updateApplicationStatus(application, ApplicationStatus.pending),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateApplicationStatus(
    ProjectApplication application,
    ApplicationStatus newStatus,
  ) async {
    try {
      await _applicationService.updateApplicationStatus(application.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${newStatus.displayName.toLowerCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}


