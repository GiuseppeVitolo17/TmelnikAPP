import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model representing a user's application to a project offer
class ProjectApplication {
  final String id;
  final String userId; // User who applied
  final String userEmail; // User email for quick reference
  final String projectId; // Project offer ID
  final String projectTitle; // Project title for quick reference
  final String? ngoId; // NGO ID that owns the project
  final DateTime appliedAt; // When the user applied
  final ApplicationStatus status; // Application status

  ProjectApplication({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.projectId,
    required this.projectTitle,
    this.ngoId,
    required this.appliedAt,
    this.status = ApplicationStatus.pending,
  });

  /// Create ProjectApplication from Firestore document
  factory ProjectApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectApplication(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      projectId: data['projectId'] ?? '',
      projectTitle: data['projectTitle'] ?? '',
      ngoId: data['ngoId'],
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ApplicationStatus.pending,
      ),
    );
  }

  /// Convert ProjectApplication to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'ngoId': ngoId,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'status': status.name,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with modified fields
  ProjectApplication copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? projectId,
    String? projectTitle,
    String? ngoId,
    DateTime? appliedAt,
    ApplicationStatus? status,
  }) {
    return ProjectApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      ngoId: ngoId ?? this.ngoId,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
    );
  }
}

/// Application status enum
enum ApplicationStatus {
  pending, // Application submitted, waiting for review
  reviewed, // Application has been reviewed
  accepted, // Application accepted
  rejected, // Application rejected
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.reviewed:
        return 'Reviewed';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  String get emoji {
    switch (this) {
      case ApplicationStatus.pending:
        return '⏳';
      case ApplicationStatus.reviewed:
        return '👀';
      case ApplicationStatus.accepted:
        return '✅';
      case ApplicationStatus.rejected:
        return '❌';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.reviewed:
        return Colors.blue;
      case ApplicationStatus.accepted:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }
}

