import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';

/// Handles synchronization of attendance mark mutations with idempotent recordId writes.
class AttendanceSyncHandler implements SyncHandler {
  final FirebaseFirestore _firestore;

  AttendanceSyncHandler(this._firestore);

  @override
  Future<void> execute(SyncEntry entry) async {
    final collection = _firestore.collection(FirestoreCollections.attendanceMarks);
    final data = Map<String, dynamic>.from(entry.payload);
    data['lastModifiedAt'] = FieldValue.serverTimestamp();

    if (entry.actionType == 'MARK_ATTENDANCE' || entry.actionType == 'CREATE') {
      await collection.doc(entry.recordId).set(
            data,
            SetOptions(merge: true),
          );
    } else if (entry.actionType == 'CLEAR_ATTENDANCE' || entry.actionType == 'DELETE') {
      await collection.doc(entry.recordId).delete();
    } else {
      await collection.doc(entry.recordId).set(
            data,
            SetOptions(merge: true),
          );
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection(FirestoreCollections.attendanceMarks);

    for (final entry in entries) {
      final data = Map<String, dynamic>.from(entry.payload);
      data['lastModifiedAt'] = FieldValue.serverTimestamp();

      if (entry.actionType == 'CLEAR_ATTENDANCE' || entry.actionType == 'DELETE') {
        batch.delete(collection.doc(entry.recordId));
      } else {
        batch.set(
          collection.doc(entry.recordId),
          data,
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }
}
