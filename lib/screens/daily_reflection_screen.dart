import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_reflection.dart';
import '../services/firebase_firestore_service.dart';
import '../theme/app_theme.dart';

class DailyReflectionScreen extends StatefulWidget {
  const DailyReflectionScreen({super.key});

  @override
  State<DailyReflectionScreen> createState() => _DailyReflectionScreenState();
}

class _DailyReflectionScreenState extends State<DailyReflectionScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final _uuid = const Uuid();
  
  DateTime _selectedDate = DateTime.now();
  DailyReflection? _currentReflection;
  bool _isLoading = true;
  
  // Predefined activity list
  final List<String> _predefinedActivities = [
    'Namegame',
    'Energizer',
    'Activity',
    'Workshop',
    'Team Building',
    'Cultural Exchange',
    'Free Time',
    'Group Discussion',
  ];

  @override
  void initState() {
    super.initState();
    _loadReflection();
  }

  Future<void> _loadReflection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    try {
      final reflection = await _firestoreService.getDailyReflectionForDate(
        user.uid,
        _selectedDate,
      );
      
      if (mounted) {
        setState(() {
          _currentReflection = reflection;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveReflection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final reflection = _currentReflection ?? DailyReflection(
        id: _uuid.v4(),
        userId: user.uid,
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      await _firestoreService.saveDailyReflection(reflection);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reflection saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reflection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectMood(MoodType mood) {
    setState(() {
      _currentReflection = (_currentReflection ?? DailyReflection(
        id: _uuid.v4(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        date: _selectedDate,
        createdAt: DateTime.now(),
      )).copyWith(
        mood: mood,
        updatedAt: DateTime.now(),
      );
    });
    _saveReflection();
  }

  void _addActivity(String activityName) {
    setState(() {
      final activities = List<Activity>.from(_currentReflection?.activities ?? []);
      
      // Check if activity already exists
      if (!activities.any((a) => a.name == activityName)) {
        activities.add(Activity(
          id: _uuid.v4(),
          name: activityName,
        ));
        
        _currentReflection = (_currentReflection ?? DailyReflection(
          id: _uuid.v4(),
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          date: _selectedDate,
          createdAt: DateTime.now(),
        )).copyWith(
          activities: activities,
          updatedAt: DateTime.now(),
        );
        
        _saveReflection();
      }
    });
  }

  void _rateActivity(String activityId, MoodType rating) {
    setState(() {
      final activities = _currentReflection?.activities.map((activity) {
        if (activity.id == activityId) {
          return activity.copyWith(rating: rating);
        }
        return activity;
      }).toList() ?? [];
      
      _currentReflection = (_currentReflection ?? DailyReflection(
        id: _uuid.v4(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        date: _selectedDate,
        createdAt: DateTime.now(),
      )).copyWith(
        activities: activities,
        updatedAt: DateTime.now(),
      );
      
      _saveReflection();
    });
  }

  void _removeActivity(String activityId) {
    setState(() {
      final activities = _currentReflection?.activities
          .where((a) => a.id != activityId)
          .toList() ?? [];
      
      _currentReflection = _currentReflection?.copyWith(
        activities: activities,
        updatedAt: DateTime.now(),
      );
      
      _saveReflection();
    });
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Activity name',
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundGrey,
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _addActivity(value.trim());
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Or select from predefined:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedActivities.map((activity) {
                  return FilterChip(
                    label: Text(activity),
                    onSelected: (selected) {
                      if (selected) {
                        _addActivity(activity);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodButton(String label, String emoji, MoodType mood) {
    final isSelected = _currentReflection?.mood == mood;
    
    return Expanded(
      child: InkWell(
        onTap: () => _selectMood(mood),
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: isSelected 
                  ? AppColors.primaryBlue 
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? AppColors.primaryBlue 
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    final reflection = _currentReflection ?? DailyReflection(
      id: '',
      userId: '',
      date: _selectedDate,
      createdAt: DateTime.now(),
    );
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          // Month section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reflection.monthName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (reflection.moodEmoji.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reflection.moodEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Day section
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  reflection.dayNumber,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              activity.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Rating buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRatingButton('👍', MoodType.happy, activity),
              const SizedBox(width: 8),
              _buildRatingButton('😐', MoodType.neutral, activity),
              const SizedBox(width: 8),
              _buildRatingButton('👎', MoodType.unhappy, activity),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeActivity(activity.id),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton(String emoji, MoodType mood, Activity activity) {
    final isSelected = activity.rating == mood;
    
    return GestureDetector(
      onTap: () => _rateActivity(activity.id, mood),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryBlue 
                : Colors.transparent,
          ),
        ),
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Header is managed by MainNavigationScreen
    // This Scaffold only provides background color
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Spacing below header (like Projects screen)
            const SizedBox(height: 16),
            
            // Mood selection buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildMoodButton('Happy', '👍', MoodType.happy),
                  const SizedBox(width: 12),
                  _buildMoodButton('Neutral', '😐', MoodType.neutral),
                  const SizedBox(width: 12),
                  _buildMoodButton('Unhappy', '👎', MoodType.unhappy),
                ],
              ),
            ),
            
            // Date card
            _buildDateCard(),
            
            // Activities list
            Expanded(
              child: _currentReflection?.activities.isEmpty ?? true
                  ? Center(
                      child: Text(
                        'No activities yet\nTap + to add one',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _currentReflection?.activities.length ?? 0,
                      itemBuilder: (context, index) {
                        final activity = _currentReflection!.activities[index];
                        return _buildActivityItem(activity);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

