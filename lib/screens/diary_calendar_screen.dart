import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../models/project_offer.dart';
import '../models/daily_reflection.dart';
import '../services/journal_service.dart';
import '../services/firebase_firestore_service.dart';
import '../theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class DiaryCalendarScreen extends StatefulWidget {
  const DiaryCalendarScreen({super.key});

  @override
  State<DiaryCalendarScreen> createState() => _DiaryCalendarScreenState();
}

class _DiaryCalendarScreenState extends State<DiaryCalendarScreen> {
  final JournalService _journalService = JournalService.instance;
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final _uuid = const Uuid();
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  List<JournalEntry> _journalEntries = [];
  List<ProjectOffer> _projectOffers = [];
  List<DailyReflection> _dailyReflections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _journalService.getAllEntries();
      // Note: Using ProjectOffer from Firebase instead of local Projects
      final offers = await _firestoreService.getProjectOffers();
      
      // Load Daily Reflections for current user
      final user = FirebaseAuth.instance.currentUser;
      List<DailyReflection> reflections = [];
      if (user != null) {
        final allReflections = await _firestoreService.getDailyReflectionsStream(user.uid).first;
        reflections = allReflections;
      }
      
      debugPrint('📅 [CALENDAR] Loaded ${entries.length} journal entries, ${offers.length} projects, ${reflections.length} daily reflections');
      
      setState(() {
        _journalEntries = entries;
        _projectOffers = offers;
        _dailyReflections = reflections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final events = <CalendarEvent>[];
    
    // Daily Reflections (from Daily Reflection screen)
    final reflections = _dailyReflections.where((reflection) =>
      reflection.date.year == day.year &&
      reflection.date.month == day.month &&
      reflection.date.day == day.day
    ).toList();
    
    for (var reflection in reflections) {
      String title = 'Daily Reflection';
      if (reflection.mood != null) {
        title = '${reflection.moodEmoji} Daily Reflection';
      }
      if (reflection.activities.isNotEmpty) {
        title += ' (${reflection.activities.length} activities)';
      }
      
      events.add(CalendarEvent(
        type: EventType.reflection,
        title: title,
        data: reflection,
      ));
    }
    
    // Journal entries (notes)
    final entries = _journalEntries.where((entry) =>
      entry.date.year == day.year &&
      entry.date.month == day.month &&
      entry.date.day == day.day
    ).toList();
    
    for (var entry in entries) {
      final title = entry.content.length > 30 
          ? '${entry.content.substring(0, 30)}...' 
          : entry.content;
      events.add(CalendarEvent(
        type: EventType.journal,
        title: title,
        data: entry,
      ));
    }
    
    // Project offers - departure, return, and deadline dates
    for (var offer in _projectOffers) {
      // Departure dates
      if (offer.departureDate != null &&
          offer.departureDate!.year == day.year &&
          offer.departureDate!.month == day.month &&
          offer.departureDate!.day == day.day) {
        events.add(CalendarEvent(
          type: EventType.departure,
          title: '🛫 Departure: ${offer.title}',
          data: offer,
        ));
      }
      
      // Return dates
      if (offer.returnDate != null &&
          offer.returnDate!.year == day.year &&
          offer.returnDate!.month == day.month &&
          offer.returnDate!.day == day.day) {
        events.add(CalendarEvent(
          type: EventType.returnDate,
          title: '🛬 Return: ${offer.title}',
          data: offer,
        ));
      }
      
      // Deadline dates
      if (offer.expiresAt != null &&
          offer.expiresAt!.year == day.year &&
          offer.expiresAt!.month == day.month &&
          offer.expiresAt!.day == day.day) {
        events.add(CalendarEvent(
          type: EventType.deadline,
          title: '⏰ Deadline: ${offer.title}',
          data: offer,
        ));
      }
    }
    
    return events;
  }

  @override
  Widget build(BuildContext context) {
    // Header is managed by MainNavigationScreen
    // This Scaffold only provides background color
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    // Selected day: blue background with white text
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    // Today: light blue background
                    todayDecoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                    todayTextStyle: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                    // Regular day styling
                    defaultTextStyle: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    // Weekend styling
                    weekendTextStyle: TextStyle(
                      color: Colors.grey[600],
                    ),
                    // Outside month days
                    outsideTextStyle: TextStyle(
                      color: Colors.grey[300],
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: AppColors.textPrimary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      // Get emoji for first event
                      String emoji = '📅';
                      
                      final firstEvent = events.first as CalendarEvent;
                      final isSelected = isSameDay(date, _selectedDay);
                      
                      switch (firstEvent.type) {
                        case EventType.reflection:
                          final reflection = firstEvent.data as DailyReflection;
                          emoji = reflection.moodEmoji.isNotEmpty 
                              ? reflection.moodEmoji 
                              : '📝';
                          // Emoji Unicode sono già colorate, non possiamo cambiarle
                          break;
                        case EventType.journal:
                          emoji = '📝';
                          break;
                        case EventType.departure:
                          emoji = '🛫';
                          break;
                        case EventType.returnDate:
                          emoji = '🛬';
                          break;
                        case EventType.deadline:
                          emoji = '⏰';
                          break;
                      }
                      
                      // Show emoji positioned at bottom center to avoid overlap with date numbers
                      // Use smaller size and proper positioning
                      return Positioned(
                        bottom: 2,
                        right: 4,
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.0, // Remove extra line height
                            shadows: isSelected ? [
                              const Shadow(
                                color: Colors.black54,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ] : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                // Events for selected day
                Expanded(
                  child: _buildEventsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No events for this day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddNoteDialog(_selectedDay),
              icon: const Icon(Icons.add),
              label: const Text('Add note'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _getEventIcon(event),
            title: Text(event.title),
            subtitle: _getEventSubtitle(event),
            trailing: event.type == EventType.journal
                ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editJournalEntry(event.data as JournalEntry),
                  )
                : event.type == EventType.reflection
                    ? IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _showReflectionDetails(event.data as DailyReflection),
                      )
                    : null,
            onTap: () => _handleEventTap(event),
          ),
        );
      },
    );
  }

  Widget _getEventIcon(CalendarEvent event) {
    switch (event.type) {
      case EventType.reflection:
        final reflection = event.data as DailyReflection;
        return CircleAvatar(
          backgroundColor: Colors.purple,
          child: Text(
            reflection.moodEmoji.isNotEmpty ? reflection.moodEmoji : '📝',
            style: const TextStyle(fontSize: 20),
          ),
        );
      case EventType.journal:
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text('📝', style: TextStyle(fontSize: 20)),
        );
      case EventType.departure:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Text('🛫', style: TextStyle(fontSize: 20)),
        );
      case EventType.returnDate:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text('🛬', style: TextStyle(fontSize: 20)),
        );
      case EventType.deadline:
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.alarm, color: Colors.white),
        );
    }
  }

  Widget? _getEventSubtitle(CalendarEvent event) {
    switch (event.type) {
      case EventType.reflection:
        final reflection = event.data as DailyReflection;
        if (reflection.activities.isNotEmpty) {
          return Text('${reflection.activities.length} activities - ${reflection.activities.take(2).map((a) => a.name).join(", ")}');
        }
        return reflection.mood != null 
            ? Text('Mood: ${reflection.moodEmoji}')
            : const Text('Daily reflection');
      case EventType.journal:
        final entry = event.data as JournalEntry;
        return Text(
          entry.content.length > 50 
              ? '${entry.content.substring(0, 50)}...' 
              : entry.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case EventType.departure:
        final offer = event.data as ProjectOffer;
        return Text('Departure for ${offer.title}');
      case EventType.returnDate:
        final offer = event.data as ProjectOffer;
        return Text('Return from ${offer.title}');
      case EventType.deadline:
        final offer = event.data as ProjectOffer;
        return Text('Application deadline for ${offer.title}');
    }
  }

  void _handleEventTap(CalendarEvent event) {
    if (event.type == EventType.journal) {
      _showJournalDetails(event.data as JournalEntry);
    } else if (event.type == EventType.reflection) {
      _showReflectionDetails(event.data as DailyReflection);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.title)),
      );
    }
  }

  void _showAddNoteDialog(DateTime date) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.note_add, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📝 Add Note - ${_formatDate(date)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'Write your note...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (textController.text.isNotEmpty) {
                          final now = DateTime.now();
                          final entry = JournalEntry(
                            id: _uuid.v4(),
                            date: date,
                            content: textController.text,
                            createdAt: now,
                            mood: '📝', // Simple note icon
                            humor: '', // No humor field
                          );
                          
                          final success = await _journalService.addEntry(entry);
                          if (success && mounted) {
                            Navigator.pop(context);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Note added!')),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddJournalDialog(DateTime date) {
    _showAddNoteDialog(date); // Redirect to note dialog
  }

  void _editJournalEntry(JournalEntry entry) {
    final textController = TextEditingController(text: entry.content);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.medium,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✏️ Edit Note - ${_formatDate(entry.date)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'Write your note...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Note?'),
                            content: const Text('Are you sure you want to delete this note?'),
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
                        
                        if (confirmed == true && mounted) {
                          await _journalService.deleteEntry(entry.id);
                          Navigator.pop(context);
                          _loadData();
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            if (textController.text.isNotEmpty) {
                              final now = DateTime.now();
                              final updatedEntry = entry.copyWith(
                                content: textController.text,
                                updatedAt: now,
                                humor: '', // No humor field
                              );
                              
                              final success = await _journalService.updateEntry(updatedEntry);
                              if (success && mounted) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Note updated!')),
                                );
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReflectionDetails(DailyReflection reflection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(
              reflection.moodEmoji.isNotEmpty ? reflection.moodEmoji : '📝',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Daily Reflection - ${_formatDate(reflection.date)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reflection.mood != null) ...[
              Text(
                'Mood: ${reflection.moodEmoji}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            if (reflection.activities.isNotEmpty) ...[
              const Text(
                'Activities:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...reflection.activities.map((activity) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(activity.name),
                    if (activity.rating != null) ...[
                      const SizedBox(width: 8),
                      Text(activity.ratingEmoji),
                    ],
                  ],
                ),
              )),
            ] else
              const Text('No activities recorded'),
            const SizedBox(height: 16),
            Text(
              'Created: ${_formatDateTime(reflection.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
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

  void _showJournalDetails(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Note - ${_formatDate(entry.date)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.content),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 4,
                children: entry.tags.map((tag) => Chip(
                  label: Text(tag),
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Created: ${_formatDateTime(entry.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (entry.updatedAt != null)
              Text(
                'Updated: ${_formatDateTime(entry.updatedAt!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editJournalEntry(entry);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

enum EventType {
  reflection,  // Daily Reflection
  journal,     // Notes
  departure,
  returnDate,
  deadline,
}

class CalendarEvent {
  final EventType type;
  final String title;
  final dynamic data;

  CalendarEvent({
    required this.type,
    required this.title,
    required this.data,
  });
}

