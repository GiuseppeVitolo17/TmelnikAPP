import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/ngo.dart';

/// Service for managing NGOs (Non-Governmental Organizations)
class NGOService {
  static final NGOService _instance = NGOService._internal();
  factory NGOService() => _instance;
  NGOService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _ngosCollection = 'ngos';

  /// Get all active NGOs
  Future<List<NGO>> getAllNGOs({bool includeInactive = false}) async {
    try {
      Query query = _firestore.collection(_ngosCollection);
      
      if (!includeInactive) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      final snapshot = await query.orderBy('name').get();
      
      return snapshot.docs
          .map((doc) => NGO.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ [NGO_SERVICE] Error getting NGOs: $e');
      return [];
    }
  }

  /// Get NGO by ID
  Future<NGO?> getNGOById(String ngoId) async {
    try {
      final doc = await _firestore.collection(_ngosCollection).doc(ngoId).get();
      if (!doc.exists) return null;
      return NGO.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [NGO_SERVICE] Error getting NGO: $e');
      return null;
    }
  }

  /// Create a new NGO (admin only)
  Future<String> createNGO(NGO ngo) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create NGO');
      }

      final ngoWithCreator = ngo.copyWith(
        createdBy: user.uid,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_ngosCollection)
          .add(ngoWithCreator.toFirestore());

      debugPrint('✅ [NGO_SERVICE] Created NGO: ${ngo.name} (ID: ${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [NGO_SERVICE] Error creating NGO: $e');
      rethrow;
    }
  }

  /// Update an existing NGO (admin only)
  Future<void> updateNGO(NGO ngo) async {
    try {
      await _firestore
          .collection(_ngosCollection)
          .doc(ngo.id)
          .update(ngo.copyWith(updatedAt: DateTime.now()).toFirestore());

      debugPrint('✅ [NGO_SERVICE] Updated NGO: ${ngo.name}');
    } catch (e) {
      debugPrint('❌ [NGO_SERVICE] Error updating NGO: $e');
      rethrow;
    }
  }

  /// Delete an NGO (admin only) - soft delete by setting isActive to false
  Future<void> deleteNGO(String ngoId) async {
    try {
      await _firestore
          .collection(_ngosCollection)
          .doc(ngoId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [NGO_SERVICE] Deleted NGO: $ngoId');
    } catch (e) {
      debugPrint('❌ [NGO_SERVICE] Error deleting NGO: $e');
      rethrow;
    }
  }

  /// Stream of all NGOs (for real-time updates)
  /// OPTIMIZED: Uses server-side filtering to reduce reads
  Stream<List<NGO>> getNGOsStream({bool includeInactive = false}) {
    Query query = _firestore.collection(_ngosCollection);
    
    if (!includeInactive) {
      // Server-side filter to reduce Firebase reads
      query = query.where('isActive', isEqualTo: true);
    }
    
    // Limit to 100 NGOs max to prevent excessive reads
    return query
        .orderBy('name')
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NGO.fromFirestore(doc))
            .toList());
  }

  /// Get NGOs assigned to a specific organizer
  Future<List<NGO>> getNGOsByOrganizer(String organizerUid) async {
    try {
      // Get user role to find their NGO
      final userDoc = await _firestore.collection('users').doc(organizerUid).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data();
      final ngoId = userData?['ngoId'] as String?;
      
      if (ngoId == null) return [];

      final ngo = await getNGOById(ngoId);
      return ngo != null ? [ngo] : [];
    } catch (e) {
      debugPrint('❌ [NGO_SERVICE] Error getting NGOs by organizer: $e');
      return [];
    }
  }
}

/// Global instance
final ngoService = NGOService();
