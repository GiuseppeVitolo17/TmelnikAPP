import 'package:flutter/material.dart';
import '../models/ngo.dart';
import '../services/ngo_service.dart';
import '../theme/app_theme.dart';
import 'manage_users_screen.dart';

/// Screen for admins to manage NGOs (create, edit, delete)
class ManageNGOScreen extends StatefulWidget {
  const ManageNGOScreen({super.key});

  @override
  State<ManageNGOScreen> createState() => _ManageNGOScreenState();
}

class _ManageNGOScreenState extends State<ManageNGOScreen> {
  final NGOService _ngoService = NGOService();
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text('Manage NGOs'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<NGO>>(
        stream: _ngoService.getNGOsStream(),
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
                  Text('Error loading NGOs: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _isLoading = true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final ngos = snapshot.data ?? [];
          _isLoading = false;

          if (ngos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No NGOs found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddNGODialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First NGO'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ngos.length,
            itemBuilder: (context, index) {
              final ngo = ngos[index];
              return _buildNGOCard(ngo);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNGODialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add NGO'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildNGOCard(NGO ngo) {
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
      child: InkWell(
        onTap: () => _viewNGOUsers(context, ngo),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    ngo.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      if (ngo.description.isNotEmpty)
                        Text(
                          ngo.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (ngo.instagramUsername != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '@${ngo.instagramUsername!}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (ngo.email != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    ngo.email!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ngo.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ngo.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                color: ngo.isActive ? Colors.green[700] : Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.people,
                    color: AppColors.primaryBlue.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: PopupMenuButton<void>(
            icon: const Icon(Icons.settings, size: 20, color: Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppColors.primaryBlue),
                    SizedBox(width: 12),
                    Text('Edit Details', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _showEditNGODialog(context, ngo),
                ),
              ),
              PopupMenuItem<void>(
                child: Row(
                  children: [
                    Icon(
                      ngo.isActive ? Icons.block : Icons.check_circle,
                      size: 20,
                      color: ngo.isActive ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ngo.isActive ? 'Deactivate' : 'Activate',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _toggleNGOStatus(ngo),
                ),
              ),
              if (ngo.isActive) ...[
                const PopupMenuDivider(),
                PopupMenuItem<void>(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _showDeleteDialog(context, ngo),
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
    );
  }

  void _showAddNGODialog(BuildContext context) {
    _showNGODialog(context, null);
  }

  void _showEditNGODialog(BuildContext context, NGO ngo) {
    _showNGODialog(context, ngo);
  }

  void _showNGODialog(BuildContext context, NGO? existingNGO) {
    final nameController = TextEditingController(text: existingNGO?.name ?? '');
    final descriptionController = TextEditingController(text: existingNGO?.description ?? '');
    final instagramController = TextEditingController(text: existingNGO?.instagramUsername ?? '');
    final emailController = TextEditingController(text: existingNGO?.email ?? '');
    final phoneController = TextEditingController(text: existingNGO?.phone ?? '');
    final addressController = TextEditingController(text: existingNGO?.address ?? '');
    final websiteController = TextEditingController(text: existingNGO?.website ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingNGO == null ? 'Create NGO' : 'Edit NGO'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.camera_alt),
                  hintText: '@username',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                if (existingNGO == null) {
                  // Create new NGO
                  final ngo = NGO(
                    id: '', // Will be generated by Firestore
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    instagramUsername: instagramController.text.trim().isEmpty
                        ? null
                        : instagramController.text.trim().replaceFirst('@', ''),
                    website: websiteController.text.trim().isEmpty
                        ? null
                        : websiteController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  await _ngoService.createNGO(ngo);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('NGO created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Return true to indicate NGO was created
                    Navigator.pop(context, true);
                  }
                } else {
                  // Update existing NGO
                  final updatedNGO = existingNGO.copyWith(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    instagramUsername: instagramController.text.trim().isEmpty
                        ? null
                        : instagramController.text.trim().replaceFirst('@', ''),
                    website: websiteController.text.trim().isEmpty
                        ? null
                        : websiteController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    updatedAt: DateTime.now(),
                  );

                  await _ngoService.updateNGO(updatedNGO);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('NGO updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
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
            child: Text(existingNGO == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNGOStatus(NGO ngo) async {
    try {
      await _ngoService.updateNGO(ngo.copyWith(
        isActive: !ngo.isActive,
        updatedAt: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NGO ${ngo.isActive ? 'deactivated' : 'activated'} successfully'),
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

  void _viewNGOUsers(BuildContext context, NGO ngo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageUsersScreen(filterByNgoId: ngo.id, ngoName: ngo.name),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, NGO ngo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete NGO'),
        content: Text('Are you sure you want to delete "${ngo.name}"? This will deactivate the NGO.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _ngoService.deleteNGO(ngo.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('NGO deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting NGO: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
