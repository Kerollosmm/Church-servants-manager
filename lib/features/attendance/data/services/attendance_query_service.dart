import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceQueryService {
  AttendanceQueryService({
    required FirebaseFirestore firestore,
    DateTime Function()? nowProvider,
  }) : _firestore = firestore,
       _nowProvider = nowProvider ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _nowProvider;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);

  DocumentReference<Map<String, dynamic>> _teamDoc(String teamId) =>
      _classesCollection.doc(teamId);

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection(FirestoreCollections.attendance);

  DocumentReference<Map<String, dynamic>> _sessionDoc(
    String teamId,
    String sessionId,
  ) => _sessionsCol.doc(sessionId);

  CollectionReference<Map<String, dynamic>> _marksCol(
    String teamId,
    String sessionId,
  ) => _sessionDoc(
    teamId,
    sessionId,
  ).collection(FirestoreCollections.attendanceMarks);

  Future<DocumentSnapshot<Map<String, dynamic>>> _cachedGet(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists) return cached;
    } catch (_) {}
    return ref.get(const GetOptions(source: Source.server));
  }

  Future<bool> _hasCacheForCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    try {
      final snapshot = await collection
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<AttendanceSession>> getSessionsForTeam(String teamId) async {
    final query = _sessionsCol
        .where('teamId', isEqualTo: teamId)
        .orderBy('startsAt', descending: true)
        .limit(50);

    final hasCache = await _hasCacheForCollection(_sessionsCol);
    if (hasCache) {
      try {
        final cached = await query.get(const GetOptions(source: Source.cache));
        if (cached.docs.isNotEmpty) return _mapSessionsSnapshot(cached);
      } catch (_) {}
    }

    final snapshot = await query.get(const GetOptions(source: Source.server));
    return _mapSessionsSnapshot(snapshot);
  }

  Future<AttendanceSession?> getActiveSessionForTeam(String teamId) async {
    final query = _sessionsCol
        .where('teamId', isEqualTo: teamId)
        .where('isClosed', isEqualTo: false)
        .orderBy('startsAt', descending: true)
        .limit(10);

    final hasCache = await _hasCacheForCollection(_sessionsCol);
    QuerySnapshot<Map<String, dynamic>> snapshot;
    if (hasCache) {
      try {
        final cached = await query.get(const GetOptions(source: Source.cache));
        snapshot = cached.docs.isNotEmpty
            ? cached
            : await query.get(const GetOptions(source: Source.server));
      } catch (_) {
        snapshot = await query.get(const GetOptions(source: Source.server));
      }
    } else {
      snapshot = await query.get(const GetOptions(source: Source.server));
    }

    final sessions = _mapSessionsSnapshot(snapshot);
    final now = _nowProvider();
    for (final session in sessions) {
      if (session.isOpenAt(now)) {
        return session;
      }
    }
    return null;
  }

  Future<AttendanceSession?> getSessionById({
    required String teamId,
    required String sessionId,
  }) async {
    try {
      final doc = await _cachedGet(_sessionDoc(teamId, sessionId));
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return AttendanceSession.fromMap(data, doc.id);
    } catch (error) {
      throw mapExceptionToAttendanceFailure(error);
    }
  }

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

  Future<AttendanceRosterSnapshot> getSessionRosterSnapshot({
    required String teamId,
    required String sessionId,
  }) async {
    final session = await getSessionById(teamId: teamId, sessionId: sessionId);
    if (session == null) {
      throw const AttendanceSessionNotFoundFailure();
    }

    // Cache-first for marks
    QuerySnapshot<Map<String, dynamic>> marksSnapshot;
    try {
      final cachedMarks = await _marksCol(
        teamId,
        sessionId,
      ).get(const GetOptions(source: Source.cache));
      marksSnapshot = cachedMarks.docs.isNotEmpty
          ? cachedMarks
          : await _marksCol(
              teamId,
              sessionId,
            ).get(const GetOptions(source: Source.server));
    } catch (_) {
      marksSnapshot = await _marksCol(
        teamId,
        sessionId,
      ).get(const GetOptions(source: Source.server));
    }

    final marks = <String, AttendanceMark>{};
    final studentMarks = <String, List<AttendanceMark>>{};

    for (final doc in marksSnapshot.docs) {
      try {
        final parts = doc.id.split('_');
        final studentId = parts.first;
        final mark = AttendanceMark.fromMap(doc.data(), studentId);

        if (!studentMarks.containsKey(studentId)) {
          studentMarks[studentId] = [];
        }
        studentMarks[studentId]!.add(mark);
      } catch (error) {
        developer.log(
          'skipped malformed attendance mark ${doc.reference.path}',
          error: error,
          name: 'AttendanceRepository',
        );
      }
    }

    studentMarks.forEach((studentId, list) {
      if (list.isEmpty) return;
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      marks[studentId] = list.first;
    });

    return _buildRosterSnapshot(
      session: session,
      studentsById: const <String, StudentModel>{},
      marksById: marks,
      now: _nowProvider(),
    );
  }

  Future<SessionStatus> getSessionStatus({
    required String teamId,
    required String sessionId,
  }) async {
    final doc = await _cachedGet(_sessionDoc(teamId, sessionId));
    final data = doc.data();
    if (!doc.exists || data == null) {
      return SessionStatus.closed;
    }
    final isReopened = data['isReopenedForAdminEdit'] == true;
    final isClosed = data['isClosed'] == true;
    if (isReopened && !isClosed) {
      return SessionStatus.reopened;
    }
    if (isClosed) {
      return SessionStatus.closed;
    }
    return SessionStatus.open;
  }

  Future<List<StudentAttendanceHistoryItem>> getStudentAttendanceHistory({
    required String studentId,
    String? teamId,
    DateTimeRange? range,
  }) async {
    final sessions = await _loadStudentSessions(
      studentId: studentId,
      teamId: teamId,
      range: range,
    );

    if (sessions.isEmpty) {
      return const <StudentAttendanceHistoryItem>[];
    }

    final now = _nowProvider();

    // Optimize: fetch all marks for this student across all sessions in one query
    final marksSnapshot = await _firestore
        .collectionGroup(FirestoreCollections.attendanceMarks)
        .where('studentId', isEqualTo: studentId)
        .get();

    // Group marks by sessionId
    final marksBySession = <String, List<AttendanceMark>>{};
    for (final doc in marksSnapshot.docs) {
      try {
        final sessionId = doc.reference.parent.parent!.id;
        final mark = AttendanceMark.fromMap(doc.data(), studentId);
        if (!marksBySession.containsKey(sessionId)) {
          marksBySession[sessionId] = [];
        }
        marksBySession[sessionId]!.add(mark);
      } catch (error) {
        developer.log('failed to map mark in group query', error: error);
      }
    }

    final history = sessions
        .map((session) {
          final sessionMarks = marksBySession[session.id] ?? [];
          // Pick best mark (latest updatedAt) for this session
          AttendanceMark? mark;
          if (sessionMarks.isNotEmpty) {
            sessionMarks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            mark = sessionMarks.first;
          }

          return StudentAttendanceHistoryItem(
            sessionId: session.id,
            teamId: session.teamId,
            teamNameSnapshot: session.teamNameSnapshot,
            title: session.title,
            dateKey: session.dateKey,
            sessionStartsAt: session.startsAt,
            sessionEndsAt: session.endsAt,
            effectiveStatus: AttendanceRosterItem.resolveEffectiveStatus(
              manualStatus: mark?.status,
              session: session,
              now: now,
            ),
            isSessionClosed: session.isEffectivelyClosedAt(now),
            markedAt: mark?.markedAt,
            markedByName: mark?.markedByName,
          );
        })
        .toList(growable: false);

    return history..sort(
      (first, second) =>
          second.sessionStartsAt.compareTo(first.sessionStartsAt),
    );
  }

  Future<StudentAttendanceStats> getStudentAttendanceStats({
    required String studentId,
    String? teamId,
    DateTimeRange? range,
  }) async {
    try {
      final history = await getStudentAttendanceHistory(
        studentId: studentId,
        teamId: teamId,
        range: range,
      );

      return StudentAttendanceStats.fromHistory(
        studentId: studentId,
        filterTeamId: teamId,
        history: history,
      );
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<TeamAttendanceStats> getTeamAttendanceStats({
    required String teamId,
    DateTimeRange? range,
  }) async {
    try {
      if (range != null) {
        // Range-based queries aren't supported with the aggregate document approach,
        // and falling back to a full collection scan violates quota constraints.
        developer.log(
          'Warning: getTeamAttendanceStats called with a date range, but server-side aggregation does not support arbitrary date ranges. Ignoring range.',
          name: 'AttendanceQueryService',
        );
      }

      // Cache-first for team stats
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        final cachedDoc = await _firestore
            .collection(FirestoreCollections.classes)
            .doc(teamId)
            .collection('stats')
            .doc('attendance')
            .get(const GetOptions(source: Source.cache));
        doc = cachedDoc.exists
            ? cachedDoc
            : await _firestore
                  .collection(FirestoreCollections.classes)
                  .doc(teamId)
                  .collection('stats')
                  .doc('attendance')
                  .get(const GetOptions(source: Source.server));
      } catch (_) {
        doc = await _firestore
            .collection(FirestoreCollections.classes)
            .doc(teamId)
            .collection('stats')
            .doc('attendance')
            .get(const GetOptions(source: Source.server));
      }

      final data = doc.data() ?? {};

      return TeamAttendanceStats(
        teamId: teamId,
        totalSessions: data['totalSessions'] as int? ?? 0,
        uniqueStudentsCount:
            data['uniqueStudentsCount'] as int? ??
            0, // This may require a different calculation strategy over time
        totalRosterEntries: data['totalRosterEntries'] as int? ?? 0,
        presentCount: data['presentCount'] as int? ?? 0,
        lateCount: data['lateCount'] as int? ?? 0,
        absentCount: data['absentCount'] as int? ?? 0,
      );
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<bool> canUserManageAttendance({
    required AuthUser user,
    required String teamId,
  }) async {
    if (user.isArchived) return false;
    if (user.role == UserRole.admin) return true;
    if (user.role != UserRole.servant) return false;

    final normalizedTeamId = teamId.trim();
    final assignedTeamIds = user.effectiveAssignedTeamIds;

    if (assignedTeamIds.contains(normalizedTeamId)) {
      return true;
    }

    final groupId = user.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      try {
        final doc = await _cachedGet(_teamDoc(normalizedTeamId));
        final data = doc.data();
        if (doc.exists && data != null) {
          return data['groupId'] == groupId;
        }
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  Future<void> assertUserCanManageAttendance({
    required AuthUser user,
    required String teamId,
  }) async {
    final canManage = await canUserManageAttendance(user: user, teamId: teamId);
    if (!canManage) {
      throw const AttendancePermissionDeniedFailure();
    }
  }

  List<AttendanceSession> _mapSessionsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sessions = <AttendanceSession>[];
    for (final doc in snapshot.docs) {
      try {
        sessions.add(AttendanceSession.fromMap(doc.data(), doc.id));
      } catch (error) {
        developer.log(
          'skipped malformed attendance session ${doc.reference.path}',
          error: error,
          name: 'AttendanceRepository',
        );
      }
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }

  AttendanceRosterSnapshot _buildRosterSnapshot({
    required AttendanceSession session,
    required Map<String, StudentModel> studentsById,
    required Map<String, AttendanceMark> marksById,
    required DateTime now,
  }) {
    final isSessionOpen = session.isOpenAt(now);
    final roster = <AttendanceRosterItem>[];

    for (var index = 0; index < session.studentIdsSnapshot.length; index += 1) {
      final studentId = session.studentIdsSnapshot[index];
      final student = studentsById[studentId];
      final mark = marksById[studentId];
      final studentName = (student?.name.trim().isNotEmpty ?? false)
          ? student?.name.trim() ?? 'مخدوم'
          : (session.studentNameSnapshots[studentId] ??
                mark?.studentNameSnapshot ??
                'مخدوم');

      roster.add(
        AttendanceRosterItem(
          studentId: studentId,
          studentName: studentName,
          teamId: session.teamId,
          sessionId: session.id,
          manualStatus: mark?.status,
          effectiveStatus: AttendanceRosterItem.resolveEffectiveStatus(
            manualStatus: mark?.status,
            session: session,
            now: now,
          ),
          isMarked: mark != null,
          markedAt: mark?.markedAt,
          markedByName: mark?.markedByName,
          isSessionOpen: isSessionOpen,
          canEdit: isSessionOpen,
          sortOrder: index,
        ),
      );
    }

    return AttendanceRosterSnapshot(session: session, roster: roster);
  }

  Query<Map<String, dynamic>> _studentSessionsQuery({
    required String studentId,
    String? teamId,
  }) {
    final normalizedTeamId = teamId?.trim() ?? '';
    if (normalizedTeamId.isNotEmpty) {
      return _sessionsCol
          .where('teamId', isEqualTo: normalizedTeamId)
          .where('studentIdsSnapshot', arrayContains: studentId);
    }

    return _firestore
        .collectionGroup(FirestoreCollections.attendanceSessions)
        .where('studentIdsSnapshot', arrayContains: studentId);
  }

  Future<List<AttendanceSession>> _loadStudentSessions({
    required String studentId,
    String? teamId,
    DateTimeRange? range,
  }) async {
    final snapshot = await _studentSessionsQuery(
      studentId: studentId,
      teamId: teamId,
    ).get();
    final sessions = _mapSessionsSnapshot(snapshot);
    if (range == null) return sessions;
    return sessions
        .where((session) {
          return !session.startsAt.isBefore(range.start) &&
              !session.startsAt.isAfter(range.end);
        })
        .toList(growable: false);
  }
}
