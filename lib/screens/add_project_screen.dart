import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_offer.dart';
import '../services/user_role_service.dart';

/// Screen for admins to add new project offers
class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController(); // Opzionale
  final _targetingController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instagramController = TextEditingController();
  final _applyLinkController = TextEditingController();
  final _infoPackController = TextEditingController();
  final _expiresController = TextEditingController();
  DateTime? _selectedDate;
  
  final List<TextEditingController> _benefitControllers = [TextEditingController()];
  bool _isLoading = false;
  DateTime? _departureDate;
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    // Prefill defaults
    _instagramController.text = 'tmelnik_cz';
    _applyLinkController.text =
        'https://docs.google.com/forms/d/e/1FAIpQLScNi27ECIvUlRY6cKdQLUe3TLZ6J2ykh8er6TEFyL3Tpx8ITw/viewform?fbclid=PAZXh0bgNhZW0CMTEAc3J0YwZhcHBfaWQMMjU2MjgxMDQwNTU4AAGnihTWmbYtm8XfzxXjrGxY0E_K5NsgtmL7-T2gXjY5j2MSLZNPqCQvi0a9_nU_aem_R_PhOicwa1l3F3igHYTxag';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _targetingController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _applyLinkController.dispose();
    _infoPackController.dispose();
    _expiresController.dispose();
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
    setState(() {
      _benefitControllers[index].dispose();
      _benefitControllers.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expiresController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectDepartureDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _departureDate = picked;
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? (_departureDate ?? DateTime.now()),
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final benefits = _benefitControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final project = ProjectOffer(
        id: '', // Firestore will generate this
        title: _titleController.text.trim(),
        location: _locationController.text.trim(),
        duration: _durationController.text.trim().isEmpty ? null : _durationController.text.trim(),
        targeting: _targetingController.text.trim(),
        description: _descriptionController.text.trim(),
        requirements: '', // Empty for now
        benefits: benefits,
        contactInfo: _instagramController.text.trim(), // Use Instagram as contact
        instagramAccount: _instagramController.text.trim(),
        applyLink: _applyLinkController.text.trim(),
        infoPackUrl: _infoPackController.text.trim(),
        createdAt: DateTime.now(),
        expiresAt: _selectedDate,
        departureDate: _departureDate,
        returnDate: _returnDate,
      );

      // Save to Firestore - use .add() to get auto-generated ID
      final docRef = await FirebaseFirestore.instance
          .collection('project_offers')
          .add(project.toFirestore());
      
      // Update the document with its own ID for consistency
      await docRef.update({'id': docRef.id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Project added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error adding project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          title: const Text('Add New Project'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: _isLoading
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
                        labelText: 'Project Title *',
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
                        hintText: 'e.g., 3 months (auto-calculated from dates)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetingController,
                      decoration: const InputDecoration(
                        labelText: 'Target Audience *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                        hintText: 'e.g., Students & Young Adults',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Description field with check button below
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 4,
                          textInputAction: TextInputAction.newline, // Enable newline on keyboard
                          keyboardType: TextInputType.multiline, // Enable multiline keyboard
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        // Round check button to close keyboard
                        FloatingActionButton.small(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                          },
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                      ],
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
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
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
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram Account *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.camera_alt),
                        hintText: 'Instagram username or handle',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Application Deadline (optional)',
                          hintText: 'Select deadline date',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: _selectedDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remove date',
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = null;
                                      _expiresController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Not set',
                          style: TextStyle(
                            color: _selectedDate != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDepartureDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '🛫 Departure Date',
                          hintText: 'Select departure date',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.flight_takeoff),
                          suffixIcon: _departureDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remove departure date',
                                  onPressed: () {
                                    setState(() {
                                      _departureDate = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          _departureDate != null
                              ? '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}'
                              : 'Not set',
                          style: TextStyle(
                            color: _departureDate != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectReturnDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '🛬 Return Date',
                          hintText: 'Select return date',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.flight_land),
                          suffixIcon: _returnDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remove return date',
                                  onPressed: () {
                                    setState(() {
                                      _returnDate = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          _returnDate != null
                              ? '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'
                              : 'Not set',
                          style: TextStyle(
                            color: _returnDate != null ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saveProject,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
