import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/journal_entry.dart';
import '../models/project_offer.dart';
import '../services/journal_service.dart';
import '../services/firebase_firestore_service.dart';
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
      
      setState(() {
        _journalEntries = entries;
        _projects = []; // We're using Firebase ProjectOffer instead
        _projectOffers = offers;
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
    
    // Journal entries
    final entries = _journalEntries.where((entry) =>
      entry.date.year == day.year &&
      entry.date.month == day.month &&
      entry.date.day == day.day
    ).toList();
    
    for (var entry in entries) {
      events.add(CalendarEvent(
        type: EventType.journal,
        title: '${entry.mood} ${entry.content.length > 30 ? entry.content.substring(0, 30) + "..." : entry.content}',
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
      if (offer.expiresAt.year == day.year &&
          offer.expiresAt.month == day.month &&
          offer.expiresAt.day == day.day) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 Personal Diary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              _showAddJournalDialog(_selectedDay);
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add journal entry',
          ),
        ],
      ),
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
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
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
                      if (events.isNotEmpty) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${events.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
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
              onPressed: () => _showAddJournalDialog(_selectedDay),
              icon: const Icon(Icons.add),
              label: const Text('Add journal entry'),
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
                : null,
            onTap: () => _handleEventTap(event),
          ),
        );
      },
    );
  }

  Widget _getEventIcon(CalendarEvent event) {
    switch (event.type) {
      case EventType.journal:
        final entry = event.data as JournalEntry;
        return CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            entry.mood,
            style: const TextStyle(fontSize: 20),
          ),
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
      case EventType.journal:
        final entry = event.data as JournalEntry;
        return Row(
          children: [
            Text(
              entry.mood,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.content.length > 50 
                    ? '${entry.content.substring(0, 50)}...' 
                    : entry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.title)),
      );
    }
  }

  void _showAddJournalDialog(DateTime date) {
    final textController = TextEditingController();
    String selectedMood = '😊';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('📝 New Journal Entry - ${_formatDate(date)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              const Text('How are you feeling?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['😊', '😢', '😴', '🎉', '🙏', '😎', '😤', '❤️'].map((mood) {
                  return ChoiceChip(
                    label: Text(mood, style: const TextStyle(fontSize: 24)),
                    selected: selectedMood == mood,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedMood = mood;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  final entry = JournalEntry(
                    id: _uuid.v4(),
                    date: date,
                    content: textController.text,
                    createdAt: DateTime.now(),
                    mood: selectedMood,
                  );
                  
                  final success = await _journalService.addEntry(entry);
                  if (success && mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Journal entry added!')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editJournalEntry(JournalEntry entry) {
    final textController = TextEditingController(text: entry.content);
    String selectedMood = entry.mood;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('✏️ Edit Journal Entry - ${_formatDate(entry.date)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              const Text('How are you feeling?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['😊', '😢', '😴', '🎉', '🙏', '😎', '😤', '❤️'].map((mood) {
                  return ChoiceChip(
                    label: Text(mood, style: const TextStyle(fontSize: 24)),
                    selected: selectedMood == mood,
                    onSelected: (selected) {
                      setDialogState(() {
                        selectedMood = mood;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Entry?'),
                    content: const Text('Are you sure you want to delete this journal entry?'),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  final updatedEntry = entry.copyWith(
                    content: textController.text,
                    mood: selectedMood,
                    updatedAt: DateTime.now(),
                  );
                  
                  final success = await _journalService.updateEntry(updatedEntry);
                  if (success && mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Journal entry updated!')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJournalDetails(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(entry.mood, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDate(entry.date),
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
  journal,
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

