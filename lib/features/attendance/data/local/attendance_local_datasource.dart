import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:hive/hive.dart';

/// Hive-backed local datasource for attendance marks.
///
/// Provides marks cache: keyed by `{teamId}_{sessionId}_{studentId}` for instant
/// reads and optimistic UI updates. Stores [AttendanceMark] objects directly.
class AttendanceLocalDatasource {
  static const String _marksCacheBox = 'attendance_marks_v2';

  /// Ensures the box is open before any read/write operation.
  Future<void> _ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_marksCacheBox)) {
      await Hive.openBox<AttendanceMark>(
        _marksCacheBox,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    }
  }

  Future<void> init() async {
    // Retained as public no-op for backwards compatibility.
  }

  Box<AttendanceMark> get _cache {
    if (!Hive.isBoxOpen(_marksCacheBox)) {
      throw StateError(
        'AttendanceLocalDatasource._cache accessed before _ensureBoxOpen. '
        'Call an async public method first, or await _ensureBoxOpen() explicitly.',
      );
    }
    return Hive.box<AttendanceMark>(_marksCacheBox);
  }

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
    await _ensureBoxOpen();
    await _cache.put(_key(teamId, sessionId, studentId), mark);
  }

  /// Saves multiple marks to the local cache in a batch.
  Future<void> cacheMarks({
    required String teamId,
    required String sessionId,
    required Map<String, AttendanceMark> marks,
  }) async {
    await _ensureBoxOpen();
    final entries = marks.map((studentId, mark) => MapEntry(_key(teamId, sessionId, studentId), mark));
    await _cache.putAll(entries);
  }

  /// Returns a cached mark, or `null` if absent.
  AttendanceMark? getCachedMark({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) {
    if (!Hive.isBoxOpen(_marksCacheBox)) return null;
    return Hive.box<AttendanceMark>(
      _marksCacheBox,
    ).get(_key(teamId, sessionId, studentId));
  }

  /// Returns all cached marks for a given session.
  Map<String, AttendanceMark> getCachedMarksForSession({
    required String teamId,
    required String sessionId,
  }) {
    if (!Hive.isBoxOpen(_marksCacheBox)) return {};
    final cacheBox = Hive.box<AttendanceMark>(_marksCacheBox);
    final prefix = '${teamId}_${sessionId}_';
    final marks = <String, AttendanceMark>{};
    for (final key in cacheBox.keys) {
      final k = key as String;
      if (!k.startsWith(prefix)) continue;
      final mark = cacheBox.get(k);
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
    await _ensureBoxOpen();
    await _cache.delete(_key(teamId, sessionId, studentId));
  }

  /// Clears the entire marks cache.
  Future<void> clearCache() async {
    await _ensureBoxOpen();
    await _cache.clear();
  }
}
