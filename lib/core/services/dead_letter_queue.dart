import 'dart:developer' as developer;

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:hive/hive.dart';

/// Persistent dead-letter queue for sync entries that exceeded max retries.
///
/// Entries moved here are preserved for manual inspection or admin recovery.
/// Capped at 100 entries (FIFO eviction).
class DeadLetterQueue {
  static const String _boxName = 'dead_letter_queue_box';
  static const int _maxEntries = 100;

  String get boxName => _boxName;

  Future<void> init() async {
    await Hive.openBox<SyncEntry>(
      _boxName,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
  }

  Box<SyncEntry> get _box => Hive.box<SyncEntry>(_boxName);

  bool get isEmpty => _box.isEmpty;
  int get length => _box.length;

  /// Moves a [SyncEntry] to the DLQ, stamping it with the current time.
  /// Enforces FIFO cap by evicting oldest entries when exceeding [_maxEntries].
  Future<void> add(SyncEntry entry) async {
    entry.failedAt = DateTime.now();
    await _box.put(entry.id, entry);

    // Enforce FIFO cap
    if (_box.length > _maxEntries) {
      final sorted = _box.values.toList()
        ..sort((a, b) {
          final aTime = a.failedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.failedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime); // oldest first
        });
      final toEvict = sorted.take(_box.length - _maxEntries);
      for (final old in toEvict) {
        await _box.delete(old.id);
      }
    }

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

  /// Returns all DLQ entries for re-enqueueing to the sync queue.
  List<SyncEntry> retryAll() {
    return getAll();
  }

  /// Prunes entries older than [age] from the DLQ.
  /// Returns the number of entries pruned.
  Future<int> pruneOlderThan(Duration age) async {
    final cutoff = DateTime.now().subtract(age);
    final toRemove = <String>[];

    for (final entry in _box.values) {
      final failedAt = entry.failedAt;
      if (failedAt != null && failedAt.isBefore(cutoff)) {
        toRemove.add(entry.id);
      }
    }

    if (toRemove.isNotEmpty) {
      await _box.deleteAll(toRemove);
      developer.log(
        'Pruned ${toRemove.length} old entries from DLQ',
        name: 'DeadLetterQueue',
      );
    }
    return toRemove.length;
  }
}
