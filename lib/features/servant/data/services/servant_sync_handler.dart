import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
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
    try {
      final payload = entry.payload;
      final docId = payload['docId'] as String? ?? payload['uid'] as String?;
      if (docId == null || docId.isEmpty) {
        developer.log(
          'CREATE_SERVANT entry ${entry.id} missing docId',
          name: 'ServantSyncHandler',
        );
        return;
      }

      final data = Map<String, dynamic>.from(payload);
      data.remove('docId');
      data['role'] = UserRole.servant.name;
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _usersCollection.doc(docId).set(data, SetOptions(merge: true));
      developer.log(
        'Synced servant $docId from queue',
        name: 'ServantSyncHandler',
      );
    } catch (e) {
      developer.log(
        'Failed to sync servant entry ${entry.id}',
        error: e,
        name: 'ServantSyncHandler',
      );
      rethrow;
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    for (final entry in entries) {
      await execute(entry);
    }
  }
}
