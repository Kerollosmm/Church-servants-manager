import 'package:church_management_system/features/attendance/data/local/mark_sync_entry.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:hive/hive.dart';

/// Hive-backed local datasource for attendance marks.
///
/// Provides two Hive boxes:
/// - **marks cache**: keyed by `{teamId}_{sessionId}_{studentId}` for instant
///   reads and optimistic UI updates. Stores [AttendanceMark] objects directly.
/// - **sync queue**: keyed by the same deduplication key, storing
///   [MarkSyncEntry] objects that are pending Firestore replay.
class AttendanceLocalDatasource {
  static const String _marksCacheBox = 'attendance_marks_v2';
  static const String _syncQueueBox = 'attendance_marks_sync_queue_v2';

  Future<void> init() async {
    await Hive.openBox<AttendanceMark>(
      _marksCacheBox,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
    await Hive.openBox<MarkSyncEntry>(
      _syncQueueBox,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
  }

  Box<AttendanceMark> get _cache => Hive.box<AttendanceMark>(_marksCacheBox);
  Box<MarkSyncEntry> get _queue => Hive.box<MarkSyncEntry>(_syncQueueBox);

  // ──────────────────────────────────────────────────────────────────────────
  // Mark cache
  // ──────────────────────────────────────────────────────────────────────────

  /// Deterministic key for a single mark.
  String _key(String teamId, String sessionId, String studentId) =>
      '${teamId}_${sessionId}_$studentId';

  /// Saves a mark to the local cache.
  Future<void> cacheMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AttendanceMark mark,
  }) async {
    await _cache.put(_key(teamId, sessionId, studentId), mark);
  }

  /// Returns a cached mark, or `null` if absent.
  AttendanceMark? getCachedMark({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) {
    return _cache.get(_key(teamId, sessionId, studentId));
  }

  /// Returns all cached marks for a given session.
  Map<String, AttendanceMark> getCachedMarksForSession({
    required String teamId,
    required String sessionId,
  }) {
    final prefix = '${teamId}_${sessionId}_';
    final marks = <String, AttendanceMark>{};
    for (final key in _cache.keys) {
      final k = key as String;
      if (!k.startsWith(prefix)) continue;
      final mark = _cache.get(k);
      if (mark == null) continue;
      final studentId = k.substring(prefix.length);
      marks[studentId] = mark;
    }
    return marks;
  }

  /// Removes a mark from the local cache.
  Future<void> removeCachedMark({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) async {
    await _cache.delete(_key(teamId, sessionId, studentId));
  }

  /// Clears the entire marks cache.
  Future<void> clearCache() async {
    await _cache.clear();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sync queue
  // ──────────────────────────────────────────────────────────────────────────

  /// Enqueues a mutation for later Firestore sync.
  ///
  /// Uses [MarkSyncEntry.deduplicationKey] so that the latest mutation for a
  /// given mark always overwrites any stale entry.
  Future<void> enqueue(MarkSyncEntry entry) async {
    await _queue.put(entry.deduplicationKey, entry);
  }

  /// Returns all pending sync entries.
  List<MarkSyncEntry> getPendingEntries() {
    return _queue.values.toList();
  }

  /// Removes a synced entry from the queue.
  Future<void> removeFromQueue(String deduplicationKey) async {
    await _queue.delete(deduplicationKey);
  }

  /// Clears the entire sync queue.
  Future<void> clearSyncQueue() async {
    await _queue.clear();
  }
}
