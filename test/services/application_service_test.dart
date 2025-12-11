import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:tmelnik_app/models/project_application.dart';
import 'package:tmelnik_app/models/project_offer.dart';

void main() {
  group('ProjectApplication Model Tests', () {
    test('ProjectApplication should serialize to Firestore correctly', () {
      final application = ProjectApplication(
        id: 'test-id',
        userId: 'user-123',
        userEmail: 'test@example.com',
        projectId: 'project-123',
        projectTitle: 'Test Project',
        ngoId: 'ngo-123',
        ngoName: 'Test NGO',
        appliedAt: DateTime(2024, 1, 1),
        status: ApplicationStatus.pending,
      );

      final firestoreData = application.toFirestore();

      expect(firestoreData['userId'], 'user-123');
      expect(firestoreData['userEmail'], 'test@example.com');
      expect(firestoreData['projectId'], 'project-123');
      expect(firestoreData['projectTitle'], 'Test Project');
      expect(firestoreData['ngoId'], 'ngo-123');
      expect(firestoreData['status'], 'pending');
      expect(firestoreData['appliedAt'], isNotNull);
    });

    test('ApplicationStatus should have correct display names', () {
      expect(ApplicationStatus.pending.displayName, 'Pending');
      expect(ApplicationStatus.accepted.displayName, 'Accepted');
      expect(ApplicationStatus.rejected.displayName, 'Rejected');
    });

    test('ApplicationStatus should have correct colors', () {
      expect(ApplicationStatus.pending.color, Colors.orange);
      expect(ApplicationStatus.accepted.color, Colors.green);
      expect(ApplicationStatus.rejected.color, Colors.red);
    });

    test('ProjectApplication copyWith should work correctly', () {
      final original = ProjectApplication(
        id: 'test-id',
        userId: 'user-123',
        userEmail: 'test@example.com',
        projectId: 'project-123',
        projectTitle: 'Test Project',
        ngoId: 'ngo-123',
        ngoName: 'Test NGO',
        appliedAt: DateTime(2024, 1, 1),
        status: ApplicationStatus.pending,
      );

      final updated = original.copyWith(
        status: ApplicationStatus.accepted,
      );

      expect(updated.status, ApplicationStatus.accepted);
      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.projectId, original.projectId);
    });
  });

  group('ProjectOffer Model Tests', () {
    test('ProjectOffer should have all required fields', () {
      final offer = ProjectOffer(
        id: 'test-id',
        title: 'Test Project',
        location: 'Test Location',
        description: 'Test Description',
        contactInfo: 'test@example.com',
        instagramAccount: '@test',
        applyLink: 'https://test.com/apply',
        infoPackUrl: 'https://test.com/info',
      );

      expect(offer.id, 'test-id');
      expect(offer.title, 'Test Project');
      expect(offer.location, 'Test Location');
      expect(offer.description, 'Test Description');
      expect(offer.contactInfo, 'test@example.com');
    });
  });
}

