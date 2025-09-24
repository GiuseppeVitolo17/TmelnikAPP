import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_offer.dart';
import '../models/feedback.dart';
import '../models/news.dart';
import '../models/info_item.dart';

class FirebaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Project Offers Collection
  static const String _offersCollection = 'project_offers';
  static const String _feedbackCollection = 'feedback';
  static const String _newsCollection = 'news';
  static const String _infoCollection = 'info_items';
  static const String _usersCollection = 'users';

  // Project Offers
  Stream<List<ProjectOffer>> getProjectOffersStream() {
    return _firestore
        .collection(_offersCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectOffer.fromFirestore(doc))
            .toList());
  }

  Future<List<ProjectOffer>> getProjectOffers() async {
    try {
      final snapshot = await _firestore
          .collection(_offersCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProjectOffer.fromFirestore(doc))
          .toList();
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
}
