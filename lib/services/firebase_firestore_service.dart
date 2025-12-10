import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_offer.dart';
import '../models/feedback.dart';
import '../models/news.dart';
import '../models/info_item.dart';
import '../models/daily_reflection.dart';

class FirebaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Project Offers Collection
  static const String _offersCollection = 'project_offers';
  static const String _feedbackCollection = 'feedback';
  static const String _newsCollection = 'news';
  static const String _infoCollection = 'info_items';
  static const String _usersCollection = 'users';
  static const String _dailyReflectionsCollection = 'daily_reflections';

  // Project Offers
  Stream<List<ProjectOffer>> getProjectOffersStream() {
    try {
    return _firestore
        .collection(_offersCollection)
        .snapshots() // Get all projects first, filter client-side
          .map((snapshot) {
            final offers = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    
                    // Check if isActive exists and is true, or if isActive doesn't exist (legacy projects)
                    final isActive = data['isActive'] as bool?;
                    if (isActive == false) {
                      // Skip explicitly inactive projects
                      debugPrint('⏭️ [FIRESTORE] Skipping inactive project: ${doc.id}');
                      return null;
                    }
                    // Include projects with isActive == true or isActive == null (legacy)
                    return ProjectOffer.fromFirestore(doc);
                  } catch (e) {
                    debugPrint('❌ [FIRESTORE] Error parsing project offer ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<ProjectOffer>()
                .toList();
            
            // Sort by createdAt descending (client-side to avoid index requirement)
            offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            debugPrint('📊 [FIRESTORE] Loaded ${offers.length} project offers from ${snapshot.docs.length} total documents');
            return offers;
          })
          .handleError((error) {
            debugPrint('Firestore stream error: $error');
            // Return empty list on error
            return <ProjectOffer>[];
          });
    } catch (e) {
      debugPrint('Error creating stream: $e');
      return Stream.value(<ProjectOffer>[]);
    }
  }

  Future<ProjectOffer?> getProjectOfferById(String id) async {
    try {
      final doc = await _firestore.collection(_offersCollection).doc(id).get();
      if (!doc.exists) return null;
      return ProjectOffer.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting project offer by id: $e');
      return null;
    }
  }

  Future<List<ProjectOffer>> getProjectOffers() async {
    try {
      final snapshot = await _firestore
          .collection(_offersCollection)
          .get(); // Get all projects, filter client-side

      final offers = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              
              // Check if isActive exists and is true, or if isActive doesn't exist (legacy projects)
              final isActive = data['isActive'] as bool?;
              if (isActive == false) {
                // Skip explicitly inactive projects
                debugPrint('⏭️ [FIRESTORE] Skipping inactive project: ${doc.id}');
                return null;
              }
              // Include projects with isActive == true or isActive == null (legacy)
              return ProjectOffer.fromFirestore(doc);
            } catch (e) {
              debugPrint('❌ [FIRESTORE] Error parsing project offer ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ProjectOffer>()
          .toList();
      
      // Sort by createdAt descending (client-side to avoid index requirement)
      offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('📊 [FIRESTORE] Loaded ${offers.length} project offers from ${snapshot.docs.length} total documents');
      return offers;
    } catch (e) {
      throw Exception('Error getting project offers: $e');
    }
  }

  Future<void> addProjectOffer(ProjectOffer offer) async {
    try {
      await _firestore
          .collection(_offersCollection)
          .doc(offer.id)
          .set(offer.toFirestore());
    } catch (e) {
      throw Exception('Error adding project offer: $e');
    }
  }

  Future<void> updateProjectOffer(ProjectOffer offer) async {
    try {
      await _firestore
          .collection(_offersCollection)
          .doc(offer.id)
          .update(offer.toFirestore());
    } catch (e) {
      throw Exception('Error updating project offer: $e');
    }
  }

  Future<void> deleteProjectOffer(String offerId) async {
    try {
      await _firestore
          .collection(_offersCollection)
          .doc(offerId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Error deleting project offer: $e');
    }
  }

  Future<void> incrementShareCount(String offerId) async {
    try {
      await _firestore
          .collection(_offersCollection)
          .doc(offerId)
          .update({
        'shareCount': FieldValue.increment(1),
        'lastSharedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error incrementing share count: $e');
    }
  }

  // Feedback - TODO: Implement when models are ready
  Stream<List<Feedback>> getFeedbackStream() {
    return _firestore
        .collection(_feedbackCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Feedback.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addFeedback(Feedback feedback) async {
    try {
      await _firestore
          .collection(_feedbackCollection)
          .doc(feedback.id)
          .set(feedback.toJson());
    } catch (e) {
      throw Exception('Error adding feedback: $e');
    }
  }

  Future<List<Feedback>> getFeedbackByType(FeedbackType type) async {
    try {
      final snapshot = await _firestore
          .collection(_feedbackCollection)
          .where('type', isEqualTo: type.name)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error getting feedback by type: $e');
    }
  }

  // News
  Stream<List<News>> getNewsStream() {
    return _firestore
        .collection(_newsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => News.fromFirestore(doc))
            .toList());
  }

  Future<void> addNews(News news) async {
    try {
      await _firestore
          .collection(_newsCollection)
          .doc(news.id)
          .set(news.toFirestore());
    } catch (e) {
      throw Exception('Error adding news: $e');
    }
  }

  Future<void> updateNews(News news) async {
    try {
      await _firestore
          .collection(_newsCollection)
          .doc(news.id)
          .update(news.toFirestore());
    } catch (e) {
      throw Exception('Error updating news: $e');
    }
  }

  Future<void> likeNews(String newsId) async {
    try {
      await _firestore
          .collection(_newsCollection)
          .doc(newsId)
          .update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Error liking news: $e');
    }
  }

  // Info Items
  Stream<List<InfoItem>> getInfoItemsStream() {
    return _firestore
        .collection(_infoCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('isImportant', descending: true)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InfoItem.fromFirestore(doc))
            .toList());
  }

  Future<List<InfoItem>> getInfoItemsByCategory(InfoCategory category) async {
    try {
      final snapshot = await _firestore
          .collection(_infoCollection)
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .orderBy('isImportant', descending: true)
          .orderBy('lastUpdated', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => InfoItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting info items by category: $e');
    }
  }

  Future<void> addInfoItem(InfoItem item) async {
    try {
      await _firestore
          .collection(_infoCollection)
          .doc(item.id)
          .set(item.toFirestore());
    } catch (e) {
      throw Exception('Error adding info item: $e');
    }
  }

  Future<void> updateInfoItem(InfoItem item) async {
    try {
      await _firestore
          .collection(_infoCollection)
          .doc(item.id)
          .update({
        ...item.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating info item: $e');
    }
  }

  // Users
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Error getting user data: $e');
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user data: $e');
    }
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final offersSnapshot = await _firestore
          .collection(_offersCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final feedbackSnapshot = await _firestore
          .collection(_feedbackCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final newsSnapshot = await _firestore
          .collection(_newsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return {
        'totalOffers': offersSnapshot.docs.length,
        'totalFeedback': feedbackSnapshot.docs.length,
        'totalNews': newsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Error getting statistics: $e');
    }
  }

  // Daily Reflections
  Future<DailyReflection?> getDailyReflectionForDate(String userId, DateTime date) async {
    try {
      // Normalize date to start of day for comparison
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      final snapshot = await _firestore
          .collection(_dailyReflectionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final reflections = snapshot.docs
          .map((doc) => DailyReflection.fromFirestore(doc))
          .where((r) {
            final rDate = DateTime(r.date.year, r.date.month, r.date.day);
            return rDate.isAtSameMomentAs(normalizedDate);
          })
          .toList();

      return reflections.isNotEmpty ? reflections.first : null;
    } catch (e) {
      debugPrint('Error getting daily reflection: $e');
      return null;
    }
  }

  Future<void> saveDailyReflection(DailyReflection reflection) async {
    try {
      // Check if reflection for this date already exists
      final existing = await getDailyReflectionForDate(reflection.userId, reflection.date);
      
      if (existing != null) {
        // Update existing reflection
        await _firestore
            .collection(_dailyReflectionsCollection)
            .doc(existing.id)
            .update(reflection.copyWith(
              id: existing.id,
              updatedAt: DateTime.now(),
            ).toFirestore());
      } else {
        // Create new reflection
        await _firestore
            .collection(_dailyReflectionsCollection)
            .doc(reflection.id)
            .set(reflection.toFirestore());
      }
    } catch (e) {
      throw Exception('Error saving daily reflection: $e');
    }
  }

  Stream<List<DailyReflection>> getDailyReflectionsStream(String userId) {
    try {
      return _firestore
          .collection(_dailyReflectionsCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final reflections = snapshot.docs
                .map((doc) {
                  try {
                    return DailyReflection.fromFirestore(doc);
                  } catch (e) {
                    debugPrint('Error parsing daily reflection ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<DailyReflection>()
                .toList();
            
            // Sort by date descending
            reflections.sort((a, b) => b.date.compareTo(a.date));
            return reflections;
          })
          .handleError((error) {
            debugPrint('Firestore stream error: $error');
            return <DailyReflection>[];
          });
    } catch (e) {
      debugPrint('Error creating stream: $e');
      return Stream.value(<DailyReflection>[]);
    }
  }
}
