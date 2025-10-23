import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';

class JournalService {
  static const String _journalKey = 'journal_entries';
  static JournalService? _instance;
  static JournalService get instance => _instance ??= JournalService._();
  
  JournalService._();

  Future<List<JournalEntry>> getAllEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getStringList(_journalKey) ?? [];
      
      return entriesJson
          .map((json) => JournalEntry.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print('Error loading journal entries: $e');
      return [];
    }
  }

  Future<List<JournalEntry>> getEntriesForDate(DateTime date) async {
    try {
      final allEntries = await getAllEntries();
      return allEntries.where((entry) {
        return entry.date.year == date.year &&
               entry.date.month == date.month &&
               entry.date.day == date.day;
      }).toList();
    } catch (e) {
      print('Error loading entries for date: $e');
      return [];
    }
  }

  Future<JournalEntry?> getEntryById(String id) async {
    try {
      final entries = await getAllEntries();
      return entries.firstWhere(
        (entry) => entry.id == id,
        orElse: () => throw Exception('Entry not found'),
      );
    } catch (e) {
      print('Error getting entry: $e');
      return null;
    }
  }

  Future<bool> addEntry(JournalEntry entry) async {
    try {
      final entries = await getAllEntries();
      entries.add(entry);
      return await _saveEntries(entries);
    } catch (e) {
      print('Error adding entry: $e');
      return false;
    }
  }

  Future<bool> updateEntry(JournalEntry entry) async {
    try {
      final entries = await getAllEntries();
      final index = entries.indexWhere((e) => e.id == entry.id);
      
      if (index == -1) {
        print('Entry not found for update');
        return false;
      }
      
      entries[index] = entry.copyWith(updatedAt: DateTime.now());
      return await _saveEntries(entries);
    } catch (e) {
      print('Error updating entry: $e');
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      final entries = await getAllEntries();
      entries.removeWhere((entry) => entry.id == id);
      return await _saveEntries(entries);
    } catch (e) {
      print('Error deleting entry: $e');
      return false;
    }
  }

  Future<bool> _saveEntries(List<JournalEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = entries.map((entry) => jsonEncode(entry.toJson())).toList();
      return await prefs.setStringList(_journalKey, entriesJson);
    } catch (e) {
      print('Error saving entries: $e');
      return false;
    }
  }

  Future<List<JournalEntry>> searchEntries(String query) async {
    try {
      final entries = await getAllEntries();
      final lowerQuery = query.toLowerCase();
      return entries.where((entry) {
        return entry.content.toLowerCase().contains(lowerQuery) ||
               entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      print('Error searching entries: $e');
      return [];
    }
  }
}

