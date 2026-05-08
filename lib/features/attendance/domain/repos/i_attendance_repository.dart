import 'package:church_management_system/core/utils/bulk_operation_result.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/material.dart';

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
    DateTimeRange? range,
  });

  Future<StudentAttendanceStats> getStudentAttendanceStats({
    required String studentId,
    String? teamId,
    DateTimeRange? range,
  });

  Future<TeamAttendanceStats> getTeamAttendanceStats({
    required String teamId,
    DateTimeRange? range,
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
}
