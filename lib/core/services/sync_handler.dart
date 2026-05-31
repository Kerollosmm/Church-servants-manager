import 'package:church_management_system/core/models/sync_entry.dart';

/// Contract representing a specific sync handler for feature data.
abstract class SyncHandler {
  /// Executes a single mutation offline entry on the remote Firestore.
  Future<void> execute(SyncEntry entry);

  /// Executes a batch of mutation offline entries on the remote Firestore.
  Future<void> executeBatch(List<SyncEntry> entries);
}
