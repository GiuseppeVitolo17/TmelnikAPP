import 'package:flutter_test/flutter_test.dart';
import 'package:tmelnik_app/models/user_role.dart';

void main() {
  group('UserRole Model Tests', () {
    test('UserRole should create correctly from map', () {
      final map = {
        'uid': 'user-123',
        'email': 'test@example.com',
        'isAdmin': true,
        'isOrganizer': false,
        'ngoId': 'ngo-123',
      };

      final userRole = UserRole.fromMap(map, 'user-123');

      expect(userRole.uid, 'user-123');
      expect(userRole.email, 'test@example.com');
      expect(userRole.isAdmin, true);
      expect(userRole.isOrganizer, false);
      expect(userRole.ngoId, 'ngo-123');
    });

    test('UserRole should convert to map correctly', () {
      final userRole = UserRole(
        uid: 'user-123',
        email: 'test@example.com',
        isAdmin: true,
        isOrganizer: false,
        ngoId: 'ngo-123',
      );

      final map = userRole.toMap();

      expect(map['uid'], 'user-123');
      expect(map['email'], 'test@example.com');
      expect(map['isAdmin'], true);
      expect(map['isOrganizer'], false);
      expect(map['ngoId'], 'ngo-123');
    });

    test('UserRole copyWith should work correctly', () {
      final original = UserRole(
        uid: 'user-123',
        email: 'test@example.com',
        isAdmin: false,
        isOrganizer: false,
      );

      final updated = original.copyWith(
        isAdmin: true,
        ngoId: 'ngo-123',
      );

      expect(updated.isAdmin, true);
      expect(updated.ngoId, 'ngo-123');
      expect(updated.uid, original.uid);
      expect(updated.email, original.email);
    });
  });
}

