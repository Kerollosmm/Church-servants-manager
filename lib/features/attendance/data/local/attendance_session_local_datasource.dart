import 'dart:convert';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:hive/hive.dart';

/// Local Hive datasource for attendance sessions.
///
/// Provides a fast, offline-first cache for session data.
/// Sessions are stored as JSON strings because AttendanceSession
/// uses Freezed without HiveType generation.
class AttendanceSessionLocalDatasource {
  static const String boxName = 'attendance_sessions_cache_box';

  Box<String>? _sessionsBox;

  Future<void> init() async {
    _sessionsBox ??= await Hive.openBox<String>(boxName);
  }

  // ---- Cache Operations ----

  Future<void> cacheSession(AttendanceSession session) async {
    await init();
    await _sessionsBox!.put(session.id, jsonEncode(session.toMap()));
  }

  Future<void> cacheSessions(List<AttendanceSession> sessions) async {
    await init();
    final entries = <String, String>{
      for (final s in sessions) s.id: jsonEncode(s.toMap()),
    };
    await _sessionsBox!.putAll(entries);
  }

  Future<AttendanceSession?> getCachedSessionById(String sessionId) async {
    await init();
    final data = _sessionsBox!.get(sessionId);
    if (data == null) return null;
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      return AttendanceSession.fromMap(map, sessionId);
    } catch (_) {
      return null;
    }
  }

  /// Returns active sessions for a specific team.
  Future<List<AttendanceSession>> getCachedActiveSessions(String teamId) async {
    await init();
    final all = _sessionsBox!.values;
    final sessions = <AttendanceSession>[];
    for (final data in all) {
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        final session = AttendanceSession.fromMap(map, map['id'] ?? '');
        if (session.teamId == teamId && !session.isClosed) {
          sessions.add(session);
        }
      } catch (_) {}
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }

  /// Returns all sessions for a specific team.
  Future<List<AttendanceSession>> getCachedAllSessions(String teamId) async {
    await init();
    final all = _sessionsBox!.values;
    final sessions = <AttendanceSession>[];
    for (final data in all) {
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        final session = AttendanceSession.fromMap(map, map['id'] ?? '');
        if (session.teamId == teamId) {
          sessions.add(session);
        }
      } catch (_) {}
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
    for (final data in all) {
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        final session = AttendanceSession.fromMap(map, map['id'] ?? '');
        if (session.teamId == teamId && session.dateKey == dateKey) {
          sessions.add(session);
        }
      } catch (_) {}
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }
}
