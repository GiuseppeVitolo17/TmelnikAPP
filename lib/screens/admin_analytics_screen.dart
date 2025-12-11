import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/application_service.dart';
import '../services/user_role_service.dart';
import '../services/ngo_service.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApplicationService _applicationService = ApplicationService();
  final UserRoleService _userRoleService = UserRoleService();
  final NGOService _ngoService = NGOService();
  
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all statistics in parallel
      final results = await Future.wait([
        _getTotalUsers(),
        _getTotalProjects(),
        _getTotalApplications(),
        _getApplicationsByStatus(),
        _getApplicationsByNGO(),
        _getRecentApplications(10),
        _getProjectsByStatus(),
      ]);

      setState(() {
        _statistics = {
          'totalUsers': results[0],
          'totalProjects': results[1],
          'totalApplications': results[2],
          'applicationsByStatus': results[3],
          'applicationsByNGO': results[4],
          'recentApplications': results[5],
          'projectsByStatus': results[6],
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getTotalProjects() async {
    final snapshot = await _firestore.collection('project_offers').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getTotalApplications() async {
    final snapshot = await _firestore.collection('project_applications').count().get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, int>> _getApplicationsByStatus() async {
    final snapshot = await _firestore.collection('project_applications').get();
    final statusCount = <String, int>{
      'pending': 0,
      'accepted': 0,
      'rejected': 0,
    };
    
    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] as String? ?? 'pending';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    
    return statusCount;
  }

  Future<List<Map<String, dynamic>>> _getApplicationsByNGO() async {
    final applications = await _firestore.collection('project_applications').get();
    final ngoCount = <String, int>{};
    
    for (var doc in applications.docs) {
      final ngoId = doc.data()['ngoId'] as String?;
      if (ngoId != null) {
        ngoCount[ngoId] = (ngoCount[ngoId] ?? 0) + 1;
      }
    }
    
    // Get NGO names
    final ngoStats = <Map<String, dynamic>>[];
    for (var entry in ngoCount.entries) {
      try {
        final ngo = await _ngoService.getNGOById(entry.key);
        ngoStats.add({
          'ngoId': entry.key,
          'ngoName': ngo?.name ?? 'Unknown NGO',
          'count': entry.value,
        });
      } catch (e) {
        ngoStats.add({
          'ngoId': entry.key,
          'ngoName': 'Unknown NGO',
          'count': entry.value,
        });
      }
    }
    
    ngoStats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return ngoStats.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> _getRecentApplications(int limit) async {
    final snapshot = await _firestore
        .collection('project_applications')
        .orderBy('appliedAt', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'userEmail': data['userEmail'] ?? 'Unknown',
        'projectTitle': data['projectTitle'] ?? 'Unknown',
        'status': data['status'] ?? 'pending',
        'appliedAt': (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  Future<Map<String, int>> _getProjectsByStatus() async {
    final snapshot = await _firestore.collection('project_offers').get();
    int active = 0;
    int inactive = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['isActive'] == true) {
        active++;
      } else {
        inactive++;
      }
    }
    
    return {'active': active, 'inactive': inactive};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewCards(),
                    const SizedBox(height: 16),
                    
                    // Applications by Status
                    _buildApplicationsByStatus(),
                    const SizedBox(height: 16),
                    
                    // Projects by Status
                    _buildProjectsByStatus(),
                    const SizedBox(height: 16),
                    
                    // Applications by NGO
                    _buildApplicationsByNGO(),
                    const SizedBox(height: 16),
                    
                    // Recent Applications
                    _buildRecentApplications(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            '${_statistics['totalUsers'] ?? 0}',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Projects',
            '${_statistics['totalProjects'] ?? 0}',
            Icons.work,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Applications',
            '${_statistics['totalApplications'] ?? 0}',
            Icons.assignment,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsByStatus() {
    final statusData = _statistics['applicationsByStatus'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Applications by Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow('Pending', statusData['pending'] ?? 0, Colors.orange),
          const SizedBox(height: 12),
          _buildStatusRow('Accepted', statusData['accepted'] ?? 0, Colors.green),
          const SizedBox(height: 12),
          _buildStatusRow('Rejected', statusData['rejected'] ?? 0, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    final total = (_statistics['totalApplications'] as int? ?? 1);
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsByStatus() {
    final projectsData = _statistics['projectsByStatus'] as Map<String, int>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Projects by Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'Active',
                  '${projectsData['active'] ?? 0}',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  'Inactive',
                  '${projectsData['inactive'] ?? 0}',
                  Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsByNGO() {
    final ngoData = _statistics['applicationsByNGO'] as List<Map<String, dynamic>>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top NGOs by Applications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (ngoData.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No applications yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...ngoData.map((ngo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ngo['ngoName'] as String? ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${ngo['count']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildRecentApplications() {
    final recent = _statistics['recentApplications'] as List<Map<String, dynamic>>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Applications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No recent applications',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ...recent.map((app) => _buildRecentApplicationItem(app)),
        ],
      ),
    );
  }

  Widget _buildRecentApplicationItem(Map<String, dynamic> app) {
    final status = app['status'] as String? ?? 'pending';
    final appliedAt = app['appliedAt'] as DateTime? ?? DateTime.now();
    
    Color statusColor;
    String statusEmoji;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusEmoji = '✅';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusEmoji = '❌';
        break;
      default:
        statusColor = Colors.orange;
        statusEmoji = '⏳';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app['projectTitle'] as String? ?? 'Unknown Project',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$statusEmoji ${status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            app['userEmail'] as String? ?? 'Unknown User',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, yyyy HH:mm').format(appliedAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

