import 'package:church_management_system/core/utils/bulk_operation_result.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_stats.dart';
import 'package:church_management_system/features/attendance/domain/entities/student_attendance_history_item.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';

abstract class IAttendanceRepository {
  Future<AttendanceSession> createSession({
    required String teamId,
    required String teamNameSnapshot,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  });

  Future<BulkOperationResult<String>> createSessionsBulk({
    required Map<String, String> teamIdsAndNames,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  });

  Future<void> closeSession({
    required String teamId,
    required String sessionId,
    required AuthUser closedBy,
  });

  Future<List<AttendanceSession>> getSessionsForTeam(String teamId);

  Future<({List<AttendanceSession> sessions, bool isFromCache})>
  getSessionsForTeamWithFallback(String teamId);

  Future<AttendanceSession?> getActiveSessionForTeam(String teamId);

  Future<AttendanceSession?> getSessionById({
    required String teamId,
    required String sessionId,
  });

  Future<void> markStudentPresent({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  });

  Future<void> markStudentLate({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  });

  Future<void> clearStudentMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser requestedBy,
  });

  Future<void> markAllPresentForRemainingStudents({
    required String teamId,
    required String sessionId,
    required AuthUser markedBy,
  });

  Future<SessionStatus> getSessionStatus({
    required String teamId,
    required String sessionId,
  });

  Future<List<AttendanceRosterItem>> getSessionRoster({
    required String teamId,
    required String sessionId,
  });

  Future<AttendanceRosterSnapshot> getSessionRosterSnapshot({
    required String teamId,
    required String sessionId,
  });

  Future<List<StudentAttendanceHistoryItem>> getStudentAttendanceHistory({
    required String studentId,
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<StudentAttendanceStats> getStudentAttendanceStats({
    required String studentId,
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<TeamAttendanceStats> getTeamAttendanceStats({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> canUserManageAttendance({
    required AuthUser user,
    required String teamId,
  });

  Future<void> assertUserCanManageAttendance({
    required AuthUser user,
    required String teamId,
  });

  Future<void> syncOfflineMark(Map<String, dynamic> payload);

  Future<void> syncOfflineClear(Map<String, dynamic> payload);

  /// Persists multiple offline attendance-mark payloads for the same session
  /// in a single Firestore [WriteBatch].
  ///
  /// Each payload in [payloads] must contain the same fields as a single
  /// [syncOfflineMark] call.  The implementation must apply the LWW rule
  /// (compare payload `updatedAt` / `createdAt` against the server document)
  /// for each mark within the batch.
  ///
  /// Firestore allows a maximum of 500 operations per WriteBatch; the
  /// implementation is responsible for chunking when `payloads.length > 490`.
  Future<void> syncBatchedMarks({
    required String teamId,
    required String sessionId,
    required List<Map<String, dynamic>> payloads,
  });

  /// Caches a mark locally.
  Future<void> cacheMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AttendanceMark mark,
  });

  /// Caches multiple marks locally in a single batch.
  Future<void> cacheMarks({
    required String teamId,
    required String sessionId,
    required Map<String, AttendanceMark> marks,
  });

  /// Clears the local attendance mark cache.
  Future<void> clearLocalCache();

  /// Gets cached marks for a session from local storage.
  Map<String, AttendanceMark> getCachedMarksForSession({
    required String teamId,
    required String sessionId,
  });

  /// Batches writes attendance marks online with offline fallback.
  Future<void> batchWriteMarks({
    required String teamId,
    required String sessionId,
    required Map<String, ({AttendanceMarkStatus status, DateTime markedAt})>
    marks,
    required AuthUser markedBy,
    bool cachedPermission = false,
  });
}
