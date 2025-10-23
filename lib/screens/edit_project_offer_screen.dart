import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_offer.dart';
import '../services/firebase_firestore_service.dart';

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
  final _instagramController = TextEditingController();
  
  DateTime? _selectedDate;
  DateTime? _departureDate;
  DateTime? _returnDate;
  
  final List<TextEditingController> _benefitControllers = [TextEditingController()];
  bool _isLoading = false;
  ProjectOffer? _projectOffer;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _isLoading = true);
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('project_offers')
          .doc(widget.projectId)
          .get();
      
      if (doc.exists) {
        final offer = ProjectOffer.fromFirestore(doc);
        setState(() {
          _projectOffer = offer;
          _titleController.text = offer.title;
          _locationController.text = offer.location;
          _durationController.text = offer.duration ?? '';
          _targetingController.text = offer.targeting;
          _descriptionController.text = offer.description;
          _instagramController.text = offer.instagramAccount;
          _selectedDate = offer.expiresAt;
          _departureDate = offer.departureDate;
          _returnDate = offer.returnDate;
          
          // Load benefits
          _benefitControllers.clear();
          for (var benefit in offer.benefits) {
            _benefitControllers.add(TextEditingController(text: benefit));
          }
          if (_benefitControllers.isEmpty) {
            _benefitControllers.add(TextEditingController());
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading project: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _targetingController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
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
      setState(() => _selectedDate = picked);
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
      setState(() => _departureDate = picked);
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
      setState(() => _returnDate = picked);
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
        contactInfo: _instagramController.text.trim(), // Use Instagram as contact
        instagramAccount: _instagramController.text.trim(),
        expiresAt: _selectedDate,
        departureDate: _departureDate,
        returnDate: _returnDate,
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
    return Scaffold(
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
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
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
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() => _selectedDate = null);
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
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() => _departureDate = null);
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
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() => _returnDate = null);
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
    );
  }
}

