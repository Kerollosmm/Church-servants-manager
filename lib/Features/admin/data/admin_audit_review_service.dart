import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';

class AdminAuditReviewEntry {
  const AdminAuditReviewEntry({
    required this.eventType,
    required this.actorName,
    required this.teamId,
    required this.sessionId,
    required this.occurredAt,
    this.targetStudentId,
  });

  final String eventType;
  final String actorName;
  final String teamId;
  final String sessionId;
  final DateTime occurredAt;
  final String? targetStudentId;
}

class AdminManagedAccountFollowUp {
  const AdminManagedAccountFollowUp({
    required this.uid,
    required this.name,
    required this.email,
  });

  final String uid;
  final String name;
  final String email;
}

class AdminAuditReviewService {
  AdminAuditReviewService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // FIX [014-US4]: expose bounded admin review streams instead of raw backend inspection.
  Stream<List<AdminAuditReviewEntry>> watchRecentAttendanceAudit({
    int limit = 8,
  }) {
    return _firestore
        .collectionGroup(FirestoreCollections.attendanceAuditEvents)
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                final occurredAt =
                    (data['occurredAt'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return AdminAuditReviewEntry(
                  eventType: (data['eventType'] as String?) ?? 'unknown',
                  actorName: (data['actorName'] as String?) ?? 'Unknown',
                  teamId: (data['teamId'] as String?) ?? '',
                  sessionId: (data['sessionId'] as String?) ?? '',
                  occurredAt: occurredAt,
                  targetStudentId: data['targetStudentId'] as String?,
                );
              })
              .toList(growable: false),
        );
  }

  Stream<List<AdminManagedAccountFollowUp>> watchPendingRestoreAccounts({
    int limit = 8,
  }) {
    return _firestore
        .collection(FirestoreCollections.users)
        .where('restorePendingPasswordReset', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where((data) => data['isArchived'] != true)
              .map(
                (data) => AdminManagedAccountFollowUp(
                  uid: (data['uid'] as String?) ?? '',
                  name: (data['name'] as String?) ?? 'Unknown',
                  email: (data['email'] as String?) ?? '',
                ),
              )
              .toList(growable: false),
        );
  }
}
