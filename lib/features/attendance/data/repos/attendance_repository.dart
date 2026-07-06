import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/cache_tracker.dart';
import 'package:church_management_system/core/services/sync_service.dart'
    hide SyncStatus;
import 'package:church_management_system/core/utils/bulk_operation_result.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_command_service.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_query_service.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_stats.dart';
import 'package:church_management_system/features/attendance/domain/entities/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Note: `AttendanceMarkRepository` has been retired.
/// [AttendanceRepository] paired with [SyncService] is the active,
/// canonical offline synchronization path.
class AttendanceRepository implements IAttendanceRepository {
  final AttendanceQueryService _queryService;
  final AttendanceCommandService _commandService;
  final AttendanceSessionLocalDatasource _sessionLocalDatasource;
  final AttendanceLocalDatasource _attendanceLocalDatasource;
  final SyncService Function() _syncServiceGetter;
  final DateTime Function() _nowProvider;

  AttendanceRepository({
    required FirebaseFirestore firestore,
    required AttendanceLocalDatasource attendanceLocalDatasource,
    required SyncService Function() syncServiceGetter,
    StudentQueryService? studentQueryService,
    DateTime Function()? nowProvider,
    Connectivity? connectivity,
    AttendanceSessionLocalDatasource? localDatasource,
  }) : _attendanceLocalDatasource = attendanceLocalDatasource,
       _syncServiceGetter = syncServiceGetter,
       _nowProvider = nowProvider ?? DateTime.now,
       _queryService = AttendanceQueryService(
         firestore: firestore,
         nowProvider: nowProvider,
       ),
       _commandService = AttendanceCommandService(
         firestore: firestore,
         syncServiceGetter: syncServiceGetter,
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
      final cacheKey = 'all_sessions_$teamId';
      if (CacheTracker.shouldRevalidate(cacheKey)) {
        // Trigger a background refresh
        unawaited(
          _queryService
              .getSessionsForTeam(teamId)
              .timeout(const Duration(seconds: 10))
              .then((remote) {
                if (remote.isNotEmpty) {
                  _sessionLocalDatasource.cacheSessions(remote);
                  CacheTracker.markFetched(cacheKey);
                }
              })
              .catchError((_) {
                // Ignore network errors on background refresh
              }),
        );
      }
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

  Future<void> _assertCanMark(String teamId, String sessionId) async {
    var session = await _sessionLocalDatasource.getCachedSessionById(sessionId);
    if (session == null) {
      session = await getSessionById(teamId: teamId, sessionId: sessionId);
      if (session != null) {
        await _sessionLocalDatasource.cacheSession(session);
      }
    }
    if (session == null) {
      throw AttendanceSessionNotFoundFailure();
    }
    final now = _nowProvider();
    final canMark = !session.isClosed && session.isOpenAt(now);
    if (!canMark) {
      throw AttendanceSessionClosedFailure();
    }
  }

  @override
  Future<void> markStudentPresent({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  }) async {
    await _assertCanMark(teamId, sessionId);
    final now = _nowProvider();
    final mark = AttendanceMark(
      studentId: studentId,
      studentNameSnapshot: studentNameSnapshot,
      status: AttendanceMarkStatus.present,
      markedByUserId: markedBy.uid,
      markedByName: markedBy.name,
      markedAt: now,
      updatedAt: now,
      note: note,
    );
    await _attendanceLocalDatasource.cacheMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      mark: mark,
    );

    await _syncServiceGetter().enqueue(
      SyncEntry(
        id: 'mark_${sessionId}_$studentId',
        actionType: 'MARK_ATTENDANCE',
        payload: {
          'teamId': teamId,
          'sessionId': sessionId,
          'studentId': studentId,
          'studentNameSnapshot': studentNameSnapshot,
          'status': AttendanceMarkStatus.present.name,
          'markedByUid': markedBy.uid,
          'markedByName': markedBy.name,
          'note': note,
          'createdAt': now.toIso8601String(),
        },
        createdAt: now,
      ),
    );
  }

  @override
  Future<void> markStudentLate({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  }) async {
    await _assertCanMark(teamId, sessionId);
    final now = _nowProvider();
    final mark = AttendanceMark(
      studentId: studentId,
      studentNameSnapshot: studentNameSnapshot,
      status: AttendanceMarkStatus.late,
      markedByUserId: markedBy.uid,
      markedByName: markedBy.name,
      markedAt: now,
      updatedAt: now,
      note: note,
    );
    await _attendanceLocalDatasource.cacheMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      mark: mark,
    );

    await _syncServiceGetter().enqueue(
      SyncEntry(
        id: 'mark_${sessionId}_$studentId',
        actionType: 'MARK_ATTENDANCE',
        payload: {
          'teamId': teamId,
          'sessionId': sessionId,
          'studentId': studentId,
          'studentNameSnapshot': studentNameSnapshot,
          'status': AttendanceMarkStatus.late.name,
          'markedByUid': markedBy.uid,
          'markedByName': markedBy.name,
          'note': note,
          'createdAt': now.toIso8601String(),
        },
        createdAt: now,
      ),
    );
  }

  @override
  Future<void> clearStudentMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser requestedBy,
  }) async {
    await _attendanceLocalDatasource.removeCachedMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
    );

    final now = _nowProvider();
    await _syncServiceGetter().enqueue(
      SyncEntry(
        id: 'mark_${sessionId}_$studentId',
        actionType: 'CLEAR_ATTENDANCE',
        payload: {
          'teamId': teamId,
          'sessionId': sessionId,
          'studentId': studentId,
          'requestedByUid': requestedBy.uid,
        },
        createdAt: now,
      ),
    );
  }

  @override
  Future<void> markAllPresentForRemainingStudents({
    required String teamId,
    required String sessionId,
    required AuthUser markedBy,
  }) async {
    final snapshot = await getSessionRosterSnapshot(
      teamId: teamId,
      sessionId: sessionId,
    );

    final unmarked = snapshot.roster.where((item) => !item.isMarked).toList();
    final now = _nowProvider();

    for (final item in unmarked) {
      final mark = AttendanceMark(
        studentId: item.studentId,
        studentNameSnapshot: item.studentName,
        status: AttendanceMarkStatus.present,
        markedByUserId: markedBy.uid,
        markedByName: markedBy.name,
        markedAt: now,
        updatedAt: now,
      );
      await _attendanceLocalDatasource.cacheMark(
        teamId: teamId,
        sessionId: sessionId,
        studentId: item.studentId,
        mark: mark,
      );

      await _syncServiceGetter().enqueue(
        SyncEntry(
          id: 'mark_${sessionId}_${item.studentId}',
          actionType: 'MARK_ATTENDANCE',
          payload: {
            'teamId': teamId,
            'sessionId': sessionId,
            'studentId': item.studentId,
            'studentNameSnapshot': item.studentName,
            'status': AttendanceMarkStatus.present.name,
            'markedByUid': markedBy.uid,
            'markedByName': markedBy.name,
            'createdAt': now.toIso8601String(),
          },
          createdAt: now,
        ),
      );
    }
  }

  @override
  Future<SessionStatus> getSessionStatus({
    required String teamId,
    required String sessionId,
  }) => _queryService.getSessionStatus(teamId: teamId, sessionId: sessionId);

  @override
  Future<List<AttendanceRosterItem>> getSessionRoster({
    required String teamId,
    required String sessionId,
  }) async {
    final snapshot = await getSessionRosterSnapshot(
      teamId: teamId,
      sessionId: sessionId,
    );
    return snapshot.roster;
  }

  @override
  Future<AttendanceRosterSnapshot> getSessionRosterSnapshot({
    required String teamId,
    required String sessionId,
  }) async {
    // 1. Try local cache first
    final cachedSession = await _sessionLocalDatasource.getCachedSessionById(
      sessionId,
    );
    final cachedMarks = _attendanceLocalDatasource.getCachedMarksForSession(
      teamId: teamId,
      sessionId: sessionId,
    );

    if (cachedSession != null) {
      final roster = <AttendanceRosterItem>[];
      final isSessionOpen = cachedSession.isOpenAt(_nowProvider());

      for (
        var index = 0;
        index < cachedSession.studentIdsSnapshot.length;
        index += 1
      ) {
        final studentId = cachedSession.studentIdsSnapshot[index];
        final cachedMark = cachedMarks[studentId];
        final studentName =
            cachedSession.studentNameSnapshots[studentId] ?? 'مخدوم';

        roster.add(
          AttendanceRosterItem(
            studentId: studentId,
            studentName: studentName,
            teamId: cachedSession.teamId,
            sessionId: cachedSession.id,
            manualStatus: cachedMark?.status,
            effectiveStatus: AttendanceRosterItem.resolveEffectiveStatus(
              manualStatus: cachedMark?.status,
              session: cachedSession,
              now: _nowProvider(),
            ),
            isMarked: cachedMark != null,
            markedAt: cachedMark?.markedAt,
            markedByName: cachedMark?.markedByName,
            isSessionOpen: isSessionOpen,
            canEdit: isSessionOpen,
            sortOrder: index,
          ),
        );
      }

      final snapshot = AttendanceRosterSnapshot(
        session: cachedSession,
        roster: roster,
      );

      // Trigger a non-blocking background fetch to refresh caches
      final cacheKey = 'roster_${teamId}_$sessionId';
      if (CacheTracker.shouldRevalidate(cacheKey)) {
        unawaited(
          _queryService
              .getSessionRosterSnapshot(teamId: teamId, sessionId: sessionId)
              .timeout(const Duration(seconds: 10))
              .then((remoteSnapshot) async {
                await _sessionLocalDatasource.cacheSession(
                  remoteSnapshot.session,
                );
                for (final item in remoteSnapshot.roster) {
                  if (item.isMarked && item.manualStatus != null) {
                    final mark = AttendanceMark(
                      studentId: item.studentId,
                      studentNameSnapshot: item.studentName,
                      status: item.manualStatus!,
                      markedByUserId: '',
                      markedByName: item.markedByName ?? '',
                      markedAt: item.markedAt ?? DateTime.now(),
                      updatedAt: item.markedAt ?? DateTime.now(),
                    );
                    await _attendanceLocalDatasource.cacheMark(
                      teamId: teamId,
                      sessionId: sessionId,
                      studentId: item.studentId,
                      mark: mark,
                    );
                  }
                }
                CacheTracker.markFetched(cacheKey);
              })
              .catchError((error) {
                developer.log(
                  'Background roster sync failed',
                  error: error,
                  name: 'AttendanceRepository',
                );
              }),
        );
      }

      return snapshot;
    }

    // 2. Cache miss: fetch from Firestore and populate cache
    final remoteSnapshot = await _queryService.getSessionRosterSnapshot(
      teamId: teamId,
      sessionId: sessionId,
    );

    await _sessionLocalDatasource.cacheSession(remoteSnapshot.session);
    for (final item in remoteSnapshot.roster) {
      if (item.isMarked && item.manualStatus != null) {
        final mark = AttendanceMark(
          studentId: item.studentId,
          studentNameSnapshot: item.studentName,
          status: item.manualStatus!,
          markedByUserId: '',
          markedByName: item.markedByName ?? '',
          markedAt: item.markedAt ?? DateTime.now(),
          updatedAt: item.markedAt ?? DateTime.now(),
        );
        await _attendanceLocalDatasource.cacheMark(
          teamId: teamId,
          sessionId: sessionId,
          studentId: item.studentId,
          mark: mark,
        );
      }
    }

    if (cachedMarks.isEmpty) {
      return remoteSnapshot;
    }

    final updatedRoster = remoteSnapshot.roster.map((item) {
      final cachedMark = cachedMarks[item.studentId];
      if (cachedMark != null) {
        return item.copyWith(
          manualStatus: cachedMark.status,
          effectiveStatus: AttendanceRosterItem.resolveEffectiveStatus(
            manualStatus: cachedMark.status,
            session: remoteSnapshot.session,
            now: _nowProvider(),
          ),
          isMarked: true,
          markedAt: cachedMark.markedAt,
          markedByName: cachedMark.markedByName,
        );
      }
      return item;
    }).toList();

    return AttendanceRosterSnapshot(
      session: remoteSnapshot.session,
      roster: updatedRoster,
    );
  }

  @override
  Future<List<StudentAttendanceHistoryItem>> getStudentAttendanceHistory({
    required String studentId,
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
  }) async => _queryService.getStudentAttendanceHistory(
    studentId: studentId,
    teamId: teamId,
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<StudentAttendanceStats> getStudentAttendanceStats({
    required String studentId,
    String? teamId,
    DateTime? startDate,
    DateTime? endDate,
  }) async => _queryService.getStudentAttendanceStats(
    studentId: studentId,
    teamId: teamId,
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<TeamAttendanceStats> getTeamAttendanceStats({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
  }) async => _queryService.getTeamAttendanceStats(
    teamId: teamId,
    startDate: startDate,
    endDate: endDate,
  );

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
  Future<void> syncOfflineMark(Map<String, dynamic> payload) async {
    await _commandService.syncOfflineMark(payload);
    try {
      final teamId = payload['teamId'] as String;
      final sessionId = payload['sessionId'] as String;
      final studentId = payload['studentId'] as String;
      final statusString = payload['status'] as String;
      final markedByUid = payload['markedByUid'] as String;
      final markedByName = payload['markedByName'] as String;
      final createdAt = DateTime.parse(payload['createdAt'] as String);

      final existing = _attendanceLocalDatasource.getCachedMark(
        teamId: teamId,
        sessionId: sessionId,
        studentId: studentId,
      );

      final updatedMark = AttendanceMark(
        studentId: studentId,
        studentNameSnapshot:
            existing?.studentNameSnapshot ??
            (payload['studentNameSnapshot'] as String?) ??
            'مخدوم',
        status: const AttendanceMarkStatusJsonConverter().fromJson(
          statusString,
        ),
        markedByUserId: markedByUid,
        markedByName: markedByName,
        markedAt: existing?.markedAt ?? createdAt,
        updatedAt: DateTime.now(),
      );

      await _attendanceLocalDatasource.cacheMark(
        teamId: teamId,
        sessionId: sessionId,
        studentId: studentId,
        mark: updatedMark,
      );
    } catch (e) {
      developer.log(
        'Failed to update local cache after syncOfflineMark: $e',
        name: 'AttendanceRepository',
      );
    }
  }

  @override
  Future<void> syncBatchedMarks({
    required String teamId,
    required String sessionId,
    required List<Map<String, dynamic>> payloads,
  }) async {
    await _commandService.syncBatchedMarks(
      teamId: teamId,
      sessionId: sessionId,
      payloads: payloads,
    );
    try {
      for (final payload in payloads) {
        final studentId = payload['studentId'] as String? ?? '';
        if (studentId.isEmpty) continue;
        final statusString = payload['status'] as String? ?? 'absent';
        final markedByUid = payload['markedByUid'] as String? ?? 'system';
        final markedByName = payload['markedByName'] as String? ?? 'النظام';
        final rawCreatedAt = payload['createdAt'] as String?;
        final createdAt = rawCreatedAt != null
            ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
            : DateTime.now();

        final existing = _attendanceLocalDatasource.getCachedMark(
          teamId: teamId,
          sessionId: sessionId,
          studentId: studentId,
        );

        final updatedMark = AttendanceMark(
          studentId: studentId,
          studentNameSnapshot:
              existing?.studentNameSnapshot ??
              (payload['studentNameSnapshot'] as String?) ??
              'مخدوم',
          status: const AttendanceMarkStatusJsonConverter().fromJson(
            statusString,
          ),
          markedByUserId: markedByUid,
          markedByName: markedByName,
          markedAt: existing?.markedAt ?? createdAt,
          updatedAt: DateTime.now(),
        );

        await _attendanceLocalDatasource.cacheMark(
          teamId: teamId,
          sessionId: sessionId,
          studentId: studentId,
          mark: updatedMark,
        );
      }
    } catch (e) {
      developer.log(
        'Failed to update local cache after syncBatchedMarks: $e',
        name: 'AttendanceRepository',
      );
    }
  }

  Future<void> batchWriteMarks({
    required String teamId,
    required String sessionId,
    required Map<String, ({AttendanceMarkStatus status, DateTime markedAt})>
    marks,
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
