import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        await createUserRole(user.uid, user.email ?? '', false);
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      return data?['isAdmin'] ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
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
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Create or update user role
  Future<void> createUserRole(String uid, String email, bool isAdmin) async {
    try {
      final userRole = UserRole(
        uid: uid,
        email: email,
        isAdmin: isAdmin,
        createdAt: DateTime.now(),
      );

      await _usersCollection.doc(uid).set(userRole.toMap(), SetOptions(merge: true));
      print('✅ User role created/updated: $email (admin: $isAdmin)');
    } catch (e) {
      print('❌ Error creating user role: $e');
      rethrow;
    }
  }

  /// Set user as admin
  Future<void> setUserAsAdmin(String uid, bool isAdmin) async {
    try {
      await _usersCollection.doc(uid).update({'isAdmin': isAdmin});
      print('✅ User admin status updated: $uid (admin: $isAdmin)');
    } catch (e) {
      print('❌ Error updating admin status: $e');
      rethrow;
    }
  }

  /// Initialize user role on first login
  Future<void> initializeUserRole(User user) async {
    try {
      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) {
        // Create new user with normal permissions
        await createUserRole(user.uid, user.email ?? '', false);
      }
    } catch (e) {
      print('❌ Error initializing user role: $e');
    }
  }

  /// Stream of current user's admin status
  Stream<bool> get adminStatusStream {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _usersCollection.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['isAdmin'] ?? false;
    });
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
      print('❌ Error getting admins: $e');
      return [];
    }
  }
}

/// Global instance
final userRoleService = UserRoleService();

