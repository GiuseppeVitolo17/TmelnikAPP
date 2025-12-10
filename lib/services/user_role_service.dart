import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_role.dart';

/// Service to manage user roles and permissions
class UserRoleService {
  static final UserRoleService _instance = UserRoleService._internal();
  factory UserRoleService() => _instance;
  UserRoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference for user roles
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) {
        // Create user document if it doesn't exist
        await createUserRole(user.uid, user.email ?? '');
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      return data?['isAdmin'] ?? false;
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error checking admin status: $e');
      return false;
    }
  }

  /// Get user role by UID
  Future<UserRole?> getUserRole(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      
      return UserRole.fromMap(doc.data() as Map<String, dynamic>, uid);
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error getting user role: $e');
      return null;
    }
  }

  /// Create or update user role
  Future<void> createUserRole(
    String uid,
    String email, {
    bool isAdmin = false,
    bool isOrganizer = false,
    String? ngoId,
  }) async {
    try {
      final userRole = UserRole(
        uid: uid,
        email: email,
        isAdmin: isAdmin,
        isOrganizer: isOrganizer,
        ngoId: ngoId,
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(uid).set(userRole.toMap(), SetOptions(merge: true));
      debugPrint('✅ [USER_ROLE] User role created/updated: $email (admin: $isAdmin, organizer: $isOrganizer, ngo: $ngoId)');
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error creating user role: $e');
      rethrow;
    }
  }

  /// Set user as admin
  Future<void> setUserAsAdmin(String uid, bool isAdmin) async {
    try {
      await _usersCollection.doc(uid).update({'isAdmin': isAdmin});
      debugPrint('✅ [USER_ROLE] User admin status updated: $uid (admin: $isAdmin)');
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error updating admin status: $e');
      rethrow;
    }
  }

  /// Set user as organizer and assign NGO
  Future<void> setUserAsOrganizer(String uid, String ngoId, bool isOrganizer) async {
    try {
      final updateData = <String, dynamic>{
        'isOrganizer': isOrganizer,
      };
      
      if (isOrganizer) {
        updateData['ngoId'] = ngoId;
      } else {
        updateData['ngoId'] = FieldValue.delete();
      }
      
      await _usersCollection.doc(uid).update(updateData);
      debugPrint('✅ [USER_ROLE] User organizer status updated: $uid (organizer: $isOrganizer, ngo: $ngoId)');
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error updating organizer status: $e');
      rethrow;
    }
  }

  /// Get all users with their roles
  Future<List<UserRole>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error getting all users: $e');
      return [];
    }
  }

  /// Stream of all users (for real-time updates)
  /// OPTIMIZED: Limit to 500 users max to prevent excessive reads
  Stream<List<UserRole>> getUsersStream() {
    return _usersCollection
        .limit(500) // Limit to prevent excessive reads
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList())
        .handleError((error) {
          debugPrint('❌ [USER_ROLE] Error in users stream: $error');
          return <UserRole>[]; // Return empty list on error
        });
  }

  /// Check if current user is organizer
  Future<bool> isCurrentUserOrganizer() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) return false;
      
      final data = doc.data() as Map<String, dynamic>?;
      return data?['isOrganizer'] ?? false;
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error checking organizer status: $e');
      return false;
    }
  }

  /// Get organizer's NGO ID
  Future<String?> getOrganizerNGOId(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>?;
      return data?['ngoId'] as String?;
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error getting organizer NGO: $e');
      return null;
    }
  }

  /// Initialize user role on first login
  Future<void> initializeUserRole(User user) async {
    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) {
        // Create new user with normal permissions
        await createUserRole(user.uid, user.email ?? '');
      }
    } catch (e) {
      print('❌ Error initializing user role: $e');
    }
  }

  /// Stream of current user's admin status
  /// OPTIMIZED: Only listens to current user's document to minimize reads
  Stream<bool> get adminStatusStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    // Only listen to current user's document (minimal reads)
    return _usersCollection
        .doc(user.uid)
        .snapshots()
        .map<bool>((doc) {
          if (!doc.exists) return false;
          final data = doc.data() as Map<String, dynamic>?;
          return data?['isAdmin'] ?? false;
        })
        .handleError((error) {
          debugPrint('❌ [USER_ROLE] Error in admin status stream: $error');
        })
        .cast<bool>();
  }

  /// Get all admin users
  Future<List<UserRole>> getAllAdmins() async {
    try {
      final querySnapshot = await _usersCollection
          .where('isAdmin', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error getting admins: $e');
      return [];
    }
  }

  /// Get all organizers
  Future<List<UserRole>> getAllOrganizers() async {
    try {
      final querySnapshot = await _usersCollection
          .where('isOrganizer', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserRole.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [USER_ROLE] Error getting organizers: $e');
      return [];
    }
  }
}

/// Global instance
final userRoleService = UserRoleService();

