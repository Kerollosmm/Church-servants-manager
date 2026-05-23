import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/models/pastoral_record_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_pastoral_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Concrete implementation of [IPastoralRepository] backed by Firestore.
///
/// Pastoral records live at: /Students/{studentId}/PastoralRecords/{recordId}
class PastoralRepository implements IPastoralRepository {
  final FirebaseFirestore _firestore;

  PastoralRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Returns the sub-collection reference for a student's pastoral records.
  CollectionReference<Map<String, dynamic>> _recordsCollection(
    String studentId,
  ) {
    return _firestore
        .collection(FirestoreCollections.students)
        .doc(studentId)
        .collection(FirestoreCollections.pastoralRecords);
  }

  @override
  Future<void> syncOfflineCreate(Map<String, dynamic> payload) async {
    final recordId = payload['recordId'] as String?;
    final studentId = payload['studentId'] as String?;

    if (recordId == null || studentId == null) {
      developer.log(
        'syncOfflineCreate: missing recordId or studentId in payload',
        name: 'PastoralRepository',
      );
      return;
    }

    // Use recordId as document ID for idempotent writes.
    await _recordsCollection(studentId).doc(recordId).set(payload);
    developer.log(
      'Synced pastoral record $recordId for student $studentId',
      name: 'PastoralRepository',
    );
  }

  @override
  Future<List<PastoralRecordModel>> getRecordsForStudent(
    String studentId,
  ) async {
    final snapshot = await _recordsCollection(studentId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PastoralRecordModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<List<PastoralRecordModel>> getAllRecords({int limit = 50}) async {
    // Cross-collection group query for admin dashboard.
    final snapshot = await _firestore
        .collectionGroup(FirestoreCollections.pastoralRecords)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => PastoralRecordModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
