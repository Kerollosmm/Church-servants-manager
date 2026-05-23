import 'dart:async';
import 'package:church_management_system/core/utils/bulk_operation_result.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_command_service.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_query_service.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class AttendanceRepository implements IAttendanceRepository {
  final AttendanceQueryService _queryService;
  final AttendanceCommandService _commandService;

  final AttendanceSessionLocalDatasource _sessionLocalDatasource;

  AttendanceRepository({
    required FirebaseFirestore firestore,
    StudentQueryService? studentQueryService,
    DateTime Function()? nowProvider,
    Connectivity? connectivity,
    AttendanceSessionLocalDatasource? localDatasource,
  }) : _queryService = AttendanceQueryService(
         firestore: firestore,
         nowProvider: nowProvider,
       ),
       _commandService = AttendanceCommandService(
         firestore: firestore,
         nowProvider: nowProvider,
         connectivity: connectivity,
         studentQueryService: studentQueryService,
         localDatasource: localDatasource,
       ),
       _sessionLocalDatasource =
           localDatasource ?? AttendanceSessionLocalDatasource();

  @override
  Future<AttendanceSession> createSession({
    required String teamId,
    required String teamNameSnapshot,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  }) => _commandService.createSession(
    teamId: teamId,
    teamNameSnapshot: teamNameSnapshot,
    startsAt: startsAt,
    durationMinutes: durationMinutes,
    createdBy: createdBy,
    title: title,
  );

  @override
  Future<BulkOperationResult<String>> createSessionsBulk({
    required Map<String, String> teamIdsAndNames,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  }) => _commandService.createSessionsBulk(
    teamIdsAndNames: teamIdsAndNames,
    startsAt: startsAt,
    durationMinutes: durationMinutes,
    createdBy: createdBy,
    title: title,
  );

  @override
  Future<void> closeSession({
    required String teamId,
    required String sessionId,
    required AuthUser closedBy,
  }) => _commandService.closeSession(
    teamId: teamId,
    sessionId: sessionId,
    closedBy: closedBy,
  );

  @override
  Future<List<AttendanceSession>> getSessionsForTeam(String teamId) =>
      _queryService.getSessionsForTeam(teamId);

  @override
  Future<({List<AttendanceSession> sessions, bool isFromCache})>
  getSessionsForTeamWithFallback(String teamId) async {
    final cached = await _sessionLocalDatasource.getCachedAllSessions(teamId);
    if (cached.isNotEmpty) {
      // Trigger a background refresh
      unawaited(
        _queryService
            .getSessionsForTeam(teamId)
            .then((remote) {
              if (remote.isNotEmpty) {
                _sessionLocalDatasource.cacheSessions(remote);
              }
            })
            .catchError((_) {
              // Ignore network errors on background refresh
            }),
      );
      return (sessions: cached, isFromCache: true);
    }
    try {
      final remote = await _queryService.getSessionsForTeam(teamId);
      if (remote.isNotEmpty) {
        await _sessionLocalDatasource.cacheSessions(remote);
      }
      return (sessions: remote, isFromCache: false);
    } catch (_) {
      return (sessions: const <AttendanceSession>[], isFromCache: true);
    }
  }

  @override
  Future<AttendanceSession?> getActiveSessionForTeam(String teamId) =>
      _queryService.getActiveSessionForTeam(teamId);

  @override
  Future<AttendanceSession?> getSessionById({
    required String teamId,
    required String sessionId,
  }) => _queryService.getSessionById(teamId: teamId, sessionId: sessionId);

  @override
  Future<void> markStudentPresent({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  }) => _commandService.markStudentPresent(
    teamId: teamId,
    sessionId: sessionId,
    studentId: studentId,
    studentNameSnapshot: studentNameSnapshot,
    markedBy: markedBy,
    note: note,
  );

  @override
  Future<void> markStudentLate({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  }) => _commandService.markStudentLate(
    teamId: teamId,
    sessionId: sessionId,
    studentId: studentId,
    studentNameSnapshot: studentNameSnapshot,
    markedBy: markedBy,
    note: note,
  );

  @override
  Future<void> clearStudentMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser requestedBy,
  }) => _commandService.clearStudentMark(
    teamId: teamId,
    sessionId: sessionId,
    studentId: studentId,
    requestedBy: requestedBy,
  );

  @override
  Future<void> markAllPresentForRemainingStudents({
    required String teamId,
    required String sessionId,
    required AuthUser markedBy,
  }) => _commandService.markAllPresentForRemainingStudents(
    teamId: teamId,
    sessionId: sessionId,
    markedBy: markedBy,
  );

  @override
  Future<SessionStatus> getSessionStatus({
    required String teamId,
    required String sessionId,
  }) => _queryService.getSessionStatus(teamId: teamId, sessionId: sessionId);

  @override
  Future<List<AttendanceRosterItem>> getSessionRoster({
    required String teamId,
    required String sessionId,
  }) => _queryService.getSessionRoster(teamId: teamId, sessionId: sessionId);

  @override
  Future<AttendanceRosterSnapshot> getSessionRosterSnapshot({
    required String teamId,
    required String sessionId,
  }) => _queryService.getSessionRosterSnapshot(
    teamId: teamId,
    sessionId: sessionId,
  );

  @override
  Future<List<StudentAttendanceHistoryItem>> getStudentAttendanceHistory({
    required String studentId,
    String? teamId,
    DateTimeRange? range,
  }) async => _queryService.getStudentAttendanceHistory(
    studentId: studentId,
    teamId: teamId,
    range: range,
  );

  @override
  Future<StudentAttendanceStats> getStudentAttendanceStats({
    required String studentId,
    String? teamId,
    DateTimeRange? range,
  }) => _queryService.getStudentAttendanceStats(
    studentId: studentId,
    teamId: teamId,
    range: range,
  );

  @override
  Future<TeamAttendanceStats> getTeamAttendanceStats({
    required String teamId,
    DateTimeRange? range,
  }) => _queryService.getTeamAttendanceStats(teamId: teamId, range: range);

  @override
  Future<bool> canUserManageAttendance({
    required AuthUser user,
    required String teamId,
  }) => _queryService.canUserManageAttendance(user: user, teamId: teamId);

  @override
  Future<void> assertUserCanManageAttendance({
    required AuthUser user,
    required String teamId,
  }) => _queryService.assertUserCanManageAttendance(user: user, teamId: teamId);

  @override
  Future<void> syncOfflineMark(Map<String, dynamic> payload) =>
      _commandService.syncOfflineMark(payload);

  @override
  Future<void> syncBatchedMarks({
    required String teamId,
    required String sessionId,
    required List<Map<String, dynamic>> payloads,
  }) => _commandService.syncBatchedMarks(
    teamId: teamId,
    sessionId: sessionId,
    payloads: payloads,
  );

  Future<void> batchWriteMarks({
    required String teamId,
    required String sessionId,
    required Map<String, AttendanceMarkStatus> marks,
    required AuthUser markedBy,
    bool cachedPermission = false,
  }) => _commandService.batchWriteMarks(
    teamId: teamId,
    sessionId: sessionId,
    marks: marks,
    markedBy: markedBy,
    cachedPermission: cachedPermission,
  );
}
