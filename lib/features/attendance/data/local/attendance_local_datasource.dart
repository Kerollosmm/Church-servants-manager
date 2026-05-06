import 'dart:convert';
import 'dart:developer' as developer;

import 'package:church_management_system/features/attendance/data/local/mark_sync_entry.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:hive/hive.dart';

/// Hive-backed local datasource for attendance marks.
///
/// Provides two Hive boxes:
/// - **marks cache**: keyed by `{teamId}_{sessionId}_{studentId}` for instant
///   reads and optimistic UI updates.
/// - **sync queue**: keyed by the same deduplication key, storing
///   [MarkSyncEntry] payloads that are pending Firestore replay.
class AttendanceLocalDatasource {
  static const String _marksCacheBox = 'attendance_marks_cache';
  static const String _syncQueueBox = 'attendance_marks_sync_queue';

  Future<void> init() async {
    await Hive.openBox<String>(_marksCacheBox);
    await Hive.openBox<String>(_syncQueueBox);
  }

  Box<String> get _cache => Hive.box(_marksCacheBox);
  Box<String> get _queue => Hive.box(_syncQueueBox);

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
    required Map<String, dynamic> markData,
  }) async {
    await _cache.put(_key(teamId, sessionId, studentId), jsonEncode(markData));
  }

  /// Returns a cached mark, or `null` if absent.
  Map<String, dynamic>? getCachedMark({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) {
    final data = _cache.get(_key(teamId, sessionId, studentId));
    if (data == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(data) as Map);
    } catch (_) {
      return null;
    }
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
      final data = _cache.get(k);
      if (data == null) continue;
      try {
        final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
        final studentId = k.substring(prefix.length);
        marks[studentId] = AttendanceMark.fromMap(map, studentId);
      } catch (error) {
        developer.log(
          'skipped malformed cached mark $k',
          error: error,
          name: 'AttendanceLocalDatasource',
        );
      }
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
    await _queue.put(entry.deduplicationKey, entry.encode());
  }

  /// Returns all pending sync entries.
  List<MarkSyncEntry> getPendingEntries() {
    final entries = <MarkSyncEntry>[];
    for (final key in _queue.keys) {
      final data = _queue.get(key);
      if (data == null) continue;
      try {
        entries.add(MarkSyncEntry.decode(data));
      } catch (error) {
        developer.log(
          'skipped malformed sync entry $key',
          error: error,
          name: 'AttendanceLocalDatasource',
        );
      }
    }
    return entries;
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
