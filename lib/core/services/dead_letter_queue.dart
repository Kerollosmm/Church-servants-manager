import 'dart:developer' as developer;

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:hive/hive.dart';

/// Persistent dead-letter queue for sync entries that exceeded max retries.
///
/// Entries moved here are preserved for manual inspection or admin recovery.
/// The box grows unboundedly but is small (only failed items).
class DeadLetterQueue {
  static const String _boxName = 'dead_letter_queue_box';

  String get boxName => _boxName;

  Future<void> init() async {
    await Hive.openBox<SyncEntry>(_boxName);
  }

  Box<SyncEntry> get _box => Hive.box<SyncEntry>(_boxName);

  bool get isEmpty => _box.isEmpty;
  int get length => _box.length;

  /// Moves a [SyncEntry] to the DLQ, stamping it with the current time.
  Future<void> add(SyncEntry entry) async {
    entry.failedAt = DateTime.now();
    await _box.put(entry.id, entry);
    developer.log(
      'Moved SyncEntry ${entry.id} to dead-letter queue',
      name: 'DeadLetterQueue',
    );
  }

  /// Returns all DLQ entries, most recent failures first.
  List<SyncEntry> getAll() {
    final entries = _box.values.toList()
      ..sort((a, b) {
        final aTime = a.failedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.failedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    return entries;
  }

  /// Removes a specific entry from the DLQ.
  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  /// Clears the entire DLQ.
  Future<void> clear() async {
    await _box.clear();
  }
}
