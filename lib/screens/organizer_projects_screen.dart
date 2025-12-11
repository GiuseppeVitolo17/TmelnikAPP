import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_offer.dart';
import '../models/project_application.dart';
import '../models/ngo.dart';
import '../services/firebase_firestore_service.dart';
import '../services/application_service.dart';
import '../services/user_role_service.dart';
import '../services/ngo_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Screen for organizers to view their projects and applications
/// Also available for admins to view all projects with NGO information
class OrganizerProjectsScreen extends StatefulWidget {
  const OrganizerProjectsScreen({super.key});

  @override
  State<OrganizerProjectsScreen> createState() => _OrganizerProjectsScreenState();
}

class _OrganizerProjectsScreenState extends State<OrganizerProjectsScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final ApplicationService _applicationService = ApplicationService();
  final UserRoleService _userRoleService = UserRoleService();
  final NGOService _ngoService = NGOService();
  
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _userNgoId;
  String? _userNgoName;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userRole = await _userRoleService.getUserRole(user.uid);
      setState(() {
        _isAdmin = userRole?.isAdmin ?? false;
        _userNgoId = userRole?.ngoId;
      });

      if (_userNgoId != null) {
        final ngo = await _ngoService.getNGOById(_userNgoId!);
        if (ngo != null) {
          setState(() {
            _userNgoName = ngo.name;
          });
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading user info: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isAdmin ? 'All Projects & Applications' : 'My Projects'),
            if (_userNgoName != null && !_isAdmin)
              Text(
                _userNgoName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ProjectOffer>>(
              stream: _isAdmin
                  ? _firestoreService.getProjectOffersStream()
                  : _firestoreService.getProjectOffersStream().map(
                      (projects) => projects
                          .where((p) => p.ngoId == _userNgoId)
                          .toList(),
                    ),
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
                        Text('Error loading projects: ${snapshot.error}'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final projects = snapshot.data ?? [];

                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isAdmin
                              ? 'No projects found'
                              : 'No projects yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdmin
                              ? 'Projects will appear here when created'
                              : 'Create your first project to get started',
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _buildProjectCard(project);
                  },
                );
              },
            ),
    );
  }

  Widget _buildProjectCard(ProjectOffer project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.work,
            color: AppColors.primaryBlue,
            size: 24,
          ),
        ),
        title: Text(
          project.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  project.location,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (_isAdmin && project.ngoId != null) ...[
              const SizedBox(height: 4),
              FutureBuilder<NGO?>(
                future: _ngoService.getNGOById(project.ngoId!),
                builder: (context, ngoSnapshot) {
                  if (ngoSnapshot.hasData && ngoSnapshot.data != null) {
                    return Row(
                      children: [
                        Icon(Icons.business, size: 14, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          ngoSnapshot.data!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
        trailing: StreamBuilder<List<ProjectApplication>>(
          stream: _applicationService.getApplicationsForProject(project.id),
          builder: (context, appSnapshot) {
            final applications = appSnapshot.data ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: applications.isEmpty
                    ? Colors.grey[100]
                    : AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: applications.isEmpty
                      ? Colors.grey[300]!
                      : AppColors.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: applications.isEmpty
                        ? Colors.grey[600]
                        : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${applications.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: applications.isEmpty
                          ? Colors.grey[600]
                          : AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Project details
                  _buildDetailRow('Location', project.location),
                  if (project.departureDate != null)
                    _buildDetailRow(
                      'Departure',
                      DateFormat('dd/MM/yyyy').format(project.departureDate!),
                    ),
                  if (project.expiresAt != null)
                    _buildDetailRow(
                      'Deadline',
                      DateFormat('dd/MM/yyyy').format(project.expiresAt!),
                    ),
                  const Divider(height: 24),
                  // Applications section
                  const Text(
                    'Applications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ProjectApplication>>(
                    stream: _applicationService.getApplicationsForProject(project.id),
                    builder: (context, appSnapshot) {
                      if (appSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final applications = appSnapshot.data ?? [];

                      if (applications.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'No applications yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: applications.map((app) => _buildApplicationCard(app)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(ProjectApplication application) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: application.status.color.withOpacity(0.1),
            radius: 20,
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
        ],
      ),
    );
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

