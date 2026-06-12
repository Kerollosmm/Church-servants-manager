import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:hive/hive.dart';

/// Local Hive datasource for attendance sessions.
///
/// Provides a fast, offline-first cache for session data.
class AttendanceSessionLocalDatasource {
  static const String boxName = 'attendance_sessions_cache_box';

  Box<AttendanceSessionModel>? _sessionsBox;

  Future<void> init() async {
    if (_sessionsBox != null && _sessionsBox!.isOpen) return;
    try {
      _sessionsBox = await Hive.openBox<AttendanceSessionModel>(
        boxName,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
      );

      // Migrations: if the box contains legacy String (JSON) data, clear it to avoid format crashes
      if (_sessionsBox!.isNotEmpty) {
        final firstValue = _sessionsBox!.values.first;
        if (firstValue is String) {
          await _sessionsBox!.clear();
        }
      }
    } catch (_) {
      // Type/schema mismatch fallback: delete files on disk and start clean
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      _sessionsBox = await Hive.openBox<AttendanceSessionModel>(
        boxName,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
      );
    }
  }

  // ---- Cache Operations ----

  Future<void> cacheSession(AttendanceSession session) async {
    await init();
    final model = AttendanceSessionModel.fromDomain(session);
    await _sessionsBox!.put(session.id, model);
  }

  Future<void> cacheSessions(List<AttendanceSession> sessions) async {
    await init();
    final entries = <String, AttendanceSessionModel>{
      for (final s in sessions) s.id: AttendanceSessionModel.fromDomain(s),
    };
    await _sessionsBox!.putAll(entries);
  }

  Future<AttendanceSession?> getCachedSessionById(String sessionId) async {
    await init();
    final model = _sessionsBox!.get(sessionId);
    return model?.toDomain();
  }

  /// Returns active sessions for a specific team.
  Future<List<AttendanceSession>> getCachedActiveSessions(String teamId) async {
    await init();
    final all = _sessionsBox!.values;
    final sessions = <AttendanceSession>[];
    for (final session in all) {
      if (session.teamId == teamId && !session.isClosed) {
        sessions.add(session.toDomain());
      }
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }

  /// Returns all sessions for a specific team.
  Future<List<AttendanceSession>> getCachedAllSessions(String teamId) async {
    await init();
    final all = _sessionsBox!.values;
    final sessions = <AttendanceSession>[];
    for (final session in all) {
      if (session.teamId == teamId) {
        sessions.add(session.toDomain());
      }
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }

  /// Returns sessions for a specific date and team.
  Future<List<AttendanceSession>> getCachedSessionsForDate(
    String teamId,
    String dateKey,
  ) async {
    await init();
    final all = _sessionsBox!.values;
    final sessions = <AttendanceSession>[];
    for (final session in all) {
      if (session.teamId == teamId && session.dateKey == dateKey) {
        sessions.add(session.toDomain());
      }
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }
}
