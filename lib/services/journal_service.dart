import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class JournalService {
  static const String _collection = 'journal_entries';
  static JournalService? _instance;
  static JournalService get instance => _instance ??= JournalService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  JournalService._();
  
  String? get _userId => _auth.currentUser?.uid;
  
  bool get isAuthenticated => _userId != null;

  Future<List<JournalEntry>> getAllEntries() async {
    if (!isAuthenticated) return [];
    
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: _userId)
          .get();
      
      final entries = snapshot.docs
          .map((doc) => JournalEntry.fromFirestore(doc))
          .toList();
      
      // Sort by date descending (client-side)
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
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
    if (!isAuthenticated) return false;
    
    try {
      await _firestore
          .collection(_collection)
          .doc(entry.id)
          .set(entry.toFirestore(_userId!));
      return true;
    } catch (e) {
      print('Error adding entry: $e');
      return false;
    }
  }

  Future<bool> updateEntry(JournalEntry entry) async {
    if (!isAuthenticated) return false;
    
    try {
      await _firestore
          .collection(_collection)
          .doc(entry.id)
          .update(entry.toFirestore(_userId!));
      return true;
    } catch (e) {
      print('Error updating entry: $e');
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    if (!isAuthenticated) return false;
    
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting entry: $e');
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

