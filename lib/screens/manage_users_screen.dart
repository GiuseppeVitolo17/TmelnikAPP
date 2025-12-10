import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../models/ngo.dart';
import '../services/user_role_service.dart';
import '../services/ngo_service.dart';
import '../theme/app_theme.dart';

/// Screen for admins to manage users and assign roles (admin, organizer)
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserRoleService _userRoleService = UserRoleService();
  final NGOService _ngoService = NGOService();
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<UserRole>>(
        stream: _userRoleService.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading users: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _isLoading = true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? [];
          _isLoading = false;

          if (users.isEmpty) {
            return const Center(
              child: Text('No users found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(UserRole user) {
    return FutureBuilder<NGO?>(
      future: user.ngoId != null ? _ngoService.getNGOById(user.ngoId!) : Future.value(null),
      builder: (context, ngoSnapshot) {
        final ngo = ngoSnapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(user.roleType).withOpacity(0.1),
              child: Icon(
                _getRoleIcon(user.roleType),
                color: _getRoleColor(user.roleType),
              ),
            ),
            title: Text(
              user.email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoleBadge(user.roleType),
                    if (user.isAdmin && user.isOrganizer) ...[
                      const SizedBox(width: 8),
                      _buildRoleBadge('organizer'),
                    ],
                  ],
                ),
                if (ngo != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        ngo.name,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(user.isAdmin ? 'Remove Admin' : 'Make Admin'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _toggleAdminRole(user),
                  ),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        user.isOrganizer ? Icons.event : Icons.event_available,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(user.isOrganizer ? 'Remove Organizer' : 'Make Organizer'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _showOrganizerDialog(context, user),
                  ),
                ),
              ],
            ),
            onTap: () => _showUserDetailsDialog(context, user, ngo),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;
    IconData icon;

    switch (role) {
      case 'admin':
        color = Colors.purple;
        label = 'Admin';
        icon = Icons.admin_panel_settings;
        break;
      case 'organizer':
        color = Colors.blue;
        label = 'Organizer';
        icon = Icons.event;
        break;
      default:
        color = Colors.grey;
        label = 'User';
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'organizer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'organizer':
        return Icons.event;
      default:
        return Icons.person;
    }
  }

  Future<void> _toggleAdminRole(UserRole user) async {
    try {
      await _userRoleService.setUserAsAdmin(user.uid, !user.isAdmin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${!user.isAdmin ? 'promoted to' : 'removed from'} admin'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showOrganizerDialog(BuildContext context, UserRole user) async {
    final ngos = await _ngoService.getAllNGOs();
    
    if (ngos.isEmpty && !user.isOrganizer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No NGOs available. Please create an NGO first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedNgoId = user.ngoId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user.isOrganizer ? 'Remove Organizer Role' : 'Assign Organizer Role'),
          content: user.isOrganizer
              ? const Text('Are you sure you want to remove the organizer role from this user?')
              : SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select NGO:'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedNgoId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: ngos.map((ngo) {
                          return DropdownMenuItem(
                            value: ngo.id,
                            child: Text(ngo.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedNgoId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  if (user.isOrganizer) {
                    // Remove organizer role
                    await _userRoleService.setUserAsOrganizer(user.uid, '', false);
                  } else {
                    // Assign organizer role
                    if (selectedNgoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an NGO'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    await _userRoleService.setUserAsOrganizer(user.uid, selectedNgoId!, true);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          user.isOrganizer
                              ? 'Organizer role removed'
                              : 'User assigned as organizer',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(user.isOrganizer ? 'Remove' : 'Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserDetailsDialog(
    BuildContext context,
    UserRole user,
    NGO? ngo,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Role', user.roleType.toUpperCase()),
              _buildDetailRow('Created', _formatDate(user.createdAt)),
              if (ngo != null) ...[
                const Divider(),
                const Text(
                  'NGO Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('NGO Name', ngo.name),
                if (ngo.description.isNotEmpty)
                  _buildDetailRow('Description', ngo.description),
                if (ngo.email != null) _buildDetailRow('NGO Email', ngo.email!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
