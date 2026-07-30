import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles offline servant mutations by replaying them against Firestore.
class ServantSyncHandler implements SyncHandler {
  final FirebaseFirestore _firestore;

  ServantSyncHandler({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.servants);

  @override
  Future<void> execute(SyncEntry entry) async {
    switch (entry.actionType) {
      case 'CREATE_SERVANT':
      case 'UPDATE_SERVANT':
        // Legacy CREATE_SERVANT entries are handled here.
        await _executeUpsert(entry);
        break;
      case 'ARCHIVE_SERVANT':
        await _executeArchive(entry);
        break;
      case 'RESTORE_SERVANT':
        await _executeRestore(entry);
        break;
      default:
        throw UnimplementedError(
          'Action type ${entry.actionType} not supported by ServantSyncHandler',
        );
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    await Future.wait(entries.map(execute));
  }

  /// CREATE_SERVANT and UPDATE_SERVANT both use set(merge: true).
  /// Role is set from the payload (NOT forced to 'servant').
  /// updatedAt is always serverTimestamp.
  /// createdAt is preserved as Timestamp.fromDate if present in payload.
  Future<void> _executeUpsert(SyncEntry entry) async {
    final payload = Map<String, dynamic>.from(entry.payload);
    final docId = payload.remove('docId') as String?;
    if (docId == null || docId.isEmpty) {
      developer.log(
        'ServantSyncHandler._executeUpsert: entry ${entry.id} missing docId',
        name: 'ServantSyncHandler',
      );
      return;
    }

    // Translate timestamps
    final createdAtString = payload.remove('createdAt') as String?;
    if (createdAtString != null) {
      final parsed = DateTime.tryParse(createdAtString);
      if (parsed != null) {
        payload['createdAt'] = Timestamp.fromDate(parsed);
      }
    }
    payload['updatedAt'] = FieldValue.serverTimestamp();

    await _usersCollection.doc(docId).set(payload, SetOptions(merge: true));
  }

  /// ARCHIVE_SERVANT: set isArchived=true, archivedAt=serverTimestamp.
  /// Does NOT touch role, assignedTeamIds, groupId, or any other field.
  Future<void> _executeArchive(SyncEntry entry) async {
    final docId = entry.payload['docId'] as String?;
    if (docId == null || docId.isEmpty) {
      developer.log(
        'ServantSyncHandler._executeArchive: entry ${entry.id} missing docId',
        name: 'ServantSyncHandler',
      );
      return;
    }

    await _usersCollection.doc(docId).set({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedByUserId': entry.payload['archivedByUserId'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// RESTORE_SERVANT: set isArchived=false, restoredAt=serverTimestamp.
  /// Optionally update assignedTeamId/assignedTeamIds if present in payload.
  /// Does NOT touch role.
  Future<void> _executeRestore(SyncEntry entry) async {
    final docId = entry.payload['docId'] as String?;
    if (docId == null || docId.isEmpty) {
      developer.log(
        'ServantSyncHandler._executeRestore: entry ${entry.id} missing docId',
        name: 'ServantSyncHandler',
      );
      return;
    }

    final data = <String, dynamic>{
      'isArchived': false,
      'restoredAt': FieldValue.serverTimestamp(),
      'restoredByUserId': entry.payload['restoredByUserId'],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final assignedTeamId = entry.payload['assignedTeamId'];
    if (assignedTeamId != null) {
      data['assignedTeamId'] = assignedTeamId;
    }
    final assignedTeamIds = entry.payload['assignedTeamIds'];
    if (assignedTeamIds != null) {
      data['assignedTeamIds'] = assignedTeamIds;
    }

    await _usersCollection.doc(docId).set(data, SetOptions(merge: true));
  }
}
