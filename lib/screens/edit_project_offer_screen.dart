import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_offer.dart';
import '../services/firebase_firestore_service.dart';
import '../services/user_role_service.dart';
import '../services/ngo_service.dart';

class EditProjectOfferScreen extends StatefulWidget {
  final String projectId;

  const EditProjectOfferScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<EditProjectOfferScreen> createState() => _EditProjectOfferScreenState();
}

class _EditProjectOfferScreenState extends State<EditProjectOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _targetingController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _applyLinkController = TextEditingController();
  final _infoPackController = TextEditingController();
  final _selectedDateController = TextEditingController();
  final _departureDateController = TextEditingController();
  final _returnDateController = TextEditingController();
  
  DateTime? _selectedDate;
  DateTime? _departureDate;
  DateTime? _returnDate;
  
  final List<TextEditingController> _benefitControllers = [TextEditingController()];
  bool _isLoading = false;
  ProjectOffer? _projectOffer;
  String? _instagramAccount; // Will be loaded from user's NGO
  String? _ngoId; // NGO ID for the project
  
  final UserRoleService _userRoleService = UserRoleService();
  final NGOService _ngoService = NGOService();

  @override
  void initState() {
    super.initState();
    // Load project after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProject();
    });
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔍 Loading project with ID: ${widget.projectId}');
      
      if (widget.projectId.isEmpty) {
        debugPrint('❌ Project ID is empty!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Project ID is missing'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('project_offers')
          .doc(widget.projectId)
          .get();
      
      debugPrint('📄 Document exists: ${doc.exists}');
      
      if (doc.exists) {
        final offer = ProjectOffer.fromFirestore(doc);
        debugPrint('✅ Loaded project: ${offer.title} (ID: ${offer.id})');
        debugPrint('   Location: ${offer.location}');
        debugPrint('   Description: ${offer.description.substring(0, offer.description.length > 50 ? 50 : offer.description.length)}...');
        
        setState(() {
          _projectOffer = offer;
          _titleController.text = offer.title;
          _locationController.text = offer.location;
          _durationController.text = offer.duration ?? '';
          _targetingController.text = offer.targeting;
          _descriptionController.text = offer.description;
          // Instagram will be loaded from NGO, not from project
          _applyLinkController.text = offer.applyLink;
          _infoPackController.text = offer.infoPackUrl;
          _selectedDate = offer.expiresAt;
          _departureDate = offer.departureDate;
          _returnDate = offer.returnDate;
          
          // Update date controllers
          _selectedDateController.text = _selectedDate != null
              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
              : '';
          _departureDateController.text = _departureDate != null
              ? '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}'
              : '';
          _returnDateController.text = _returnDate != null
              ? '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'
              : '';
          
          // Load benefits - ensure unique
          _benefitControllers.clear();
          final uniqueBenefits = offer.benefits.toSet().toList(); // Remove duplicates
          for (var benefit in uniqueBenefits) {
            _benefitControllers.add(TextEditingController(text: benefit));
          }
          if (_benefitControllers.isEmpty) {
            _benefitControllers.add(TextEditingController());
          }
        });
        
        debugPrint('✅ Form fields populated successfully');
        
        // Load Instagram from user's NGO if organizer
        await _loadInstagramFromNGO();
      } else {
        debugPrint('❌ Document does not exist for ID: ${widget.projectId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading project: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInstagramFromNGO() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final userRole = await _userRoleService.getUserRole(user.uid);
      if (userRole?.isOrganizer == true && userRole?.ngoId != null) {
        final ngo = await _ngoService.getNGOById(userRole!.ngoId!);
        if (ngo != null) {
          setState(() {
            _ngoId = userRole.ngoId;
            _instagramAccount = ngo.instagramUsername;
          });
          debugPrint('✅ [EDIT_PROJECT] Loaded Instagram from NGO: ${ngo.instagramUsername}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [EDIT_PROJECT] Could not load Instagram from NGO: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _targetingController.dispose();
    _descriptionController.dispose();
    _applyLinkController.dispose();
    _infoPackController.dispose();
    _selectedDateController.dispose();
    _departureDateController.dispose();
    _returnDateController.dispose();
    for (var controller in _benefitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addBenefitField() {
    setState(() {
      _benefitControllers.add(TextEditingController());
    });
  }

  void _removeBenefitField(int index) {
    if (_benefitControllers.length > 1) {
      setState(() {
        _benefitControllers[index].dispose();
        _benefitControllers.removeAt(index);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectDepartureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _departureDate = picked;
        _departureDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? (_departureDate ?? DateTime.now()),
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _returnDate = picked;
        _returnDateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _confirmRemoveDate(String dateType, VoidCallback onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Date'),
        content: Text('Are you sure you want to remove the $dateType? This action cannot be undone.'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_projectOffer == null) return;

    setState(() => _isLoading = true);

    try {
      final benefits = _benefitControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final updatedOffer = _projectOffer!.copyWith(
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        duration: _durationController.text.trim().isEmpty ? null : _durationController.text.trim(),
        targeting: _targetingController.text.trim(),
        description: _descriptionController.text.trim(),
        benefits: benefits,
        contactInfo: _instagramAccount ?? _projectOffer?.instagramAccount ?? 'tmelnik_cz', // Use Instagram from NGO or existing
        instagramAccount: _instagramAccount ?? _projectOffer?.instagramAccount ?? 'tmelnik_cz',
        applyLink: _applyLinkController.text.trim(),
        infoPackUrl: _infoPackController.text.trim(),
        expiresAt: _selectedDate,
        departureDate: _departureDate,
        returnDate: _returnDate,
        ngoId: _ngoId ?? _projectOffer?.ngoId, // Preserve or update NGO ID
      );

      await FirebaseFirestore.instance
          .collection('project_offers')
          .doc(widget.projectId)
          .update(updatedOffer.toFirestore());

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Project updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Project'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: _isLoading && _projectOffer == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _applyLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Apply Link *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _infoPackController,
                      decoration: const InputDecoration(
                        labelText: 'Infopack Link',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                        hintText: 'https://... (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                        hintText: 'e.g., 3 months',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetingController,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Description field with check button inside (bottom right corner)
                    Container(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                              contentPadding: EdgeInsets.only(
                                left: 16,
                                top: 16,
                                right: 50, // Space for check button
                                bottom: 50, // Extra space at bottom for button
                              ),
                            ),
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            keyboardType: TextInputType.multiline,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          // Round check button positioned inside bottom right corner
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Benefits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._benefitControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Benefit ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.check_circle),
                                ),
                              ),
                            ),
                            if (_benefitControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeBenefitField(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    ElevatedButton.icon(
                      onPressed: _addBenefitField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Benefit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Instagram is now automatically loaded from user's NGO
                    if (_instagramAccount != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instagram Account',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@$_instagramAccount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Automatically loaded from your NGO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      onTap: _isLoading ? null : _selectDate,
                      controller: _selectedDateController,
                      decoration: InputDecoration(
                        labelText: 'Application Deadline (optional)',
                        hintText: 'Select deadline date',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: _selectedDate != null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Remove date',
                                onPressed: _isLoading ? null : () {
                                  _confirmRemoveDate('application deadline', () {
                                    setState(() {
                                      _selectedDate = null;
                                      _selectedDateController.clear();
                                    });
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      onTap: _isLoading ? null : _selectDepartureDate,
                      controller: _departureDateController,
                      decoration: InputDecoration(
                        labelText: '🛫 Departure Date',
                        hintText: 'Select departure date',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.flight_takeoff),
                        suffixIcon: _departureDate != null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Remove departure date',
                                onPressed: _isLoading ? null : () {
                                  _confirmRemoveDate('departure date', () {
                                    setState(() {
                                      _departureDate = null;
                                      _departureDateController.clear();
                                    });
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      onTap: _isLoading ? null : _selectReturnDate,
                      controller: _returnDateController,
                      decoration: InputDecoration(
                        labelText: '🛬 Return Date',
                        hintText: 'Select return date',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.flight_land),
                        suffixIcon: _returnDate != null
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Remove return date',
                                onPressed: _isLoading ? null : () {
                                  _confirmRemoveDate('return date', () {
                                    setState(() {
                                      _returnDate = null;
                                      _returnDateController.clear();
                                    });
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

