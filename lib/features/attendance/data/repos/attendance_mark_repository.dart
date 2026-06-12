import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/local/mark_sync_entry.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:church_management_system/features/team/data/datasources/team_local_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceMarkRepository {
  AttendanceMarkRepository({
    required FirebaseFirestore firestore,
    required AttendanceLocalDatasource localDatasource,
    required AttendanceSessionLocalDatasource sessionLocalDatasource,
    required TeamLocalDatasource teamLocalDatasource,
    DateTime Function()? nowProvider,
  }) : _firestore = firestore,
       _localDatasource = localDatasource,
       _sessionLocalDatasource = sessionLocalDatasource,
       _teamLocalDatasource = teamLocalDatasource,
       _nowProvider = nowProvider ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final AttendanceLocalDatasource _localDatasource;
  final AttendanceSessionLocalDatasource _sessionLocalDatasource;
  final TeamLocalDatasource _teamLocalDatasource;
  final DateTime Function() _nowProvider;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);

  CollectionReference<Map<String, dynamic>> _sessionsCol(String teamId) =>
      _classesCollection
          .doc(teamId)
          .collection(FirestoreCollections.attendanceSessions);

  DocumentReference<Map<String, dynamic>> _sessionDoc(
    String teamId,
    String sessionId,
  ) => _sessionsCol(teamId).doc(sessionId);

  CollectionReference<Map<String, dynamic>> _marksCol(
    String teamId,
    String sessionId,
  ) => _sessionDoc(
    teamId,
    sessionId,
  ).collection(FirestoreCollections.attendanceMarks);

  DocumentReference<Map<String, dynamic>> _markDoc(
    String teamId,
    String sessionId,
    String studentId,
  ) => _marksCol(teamId, sessionId).doc('${studentId}_$sessionId');

  Future<DocumentSnapshot<Map<String, dynamic>>> _cachedGet(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists) return cached;
    } catch (_) {
      // Fallback to server if cache read fails
    }
    try {
      return await ref.get(const GetOptions(source: Source.server));
    } catch (e) {
      // If server fetch fails, try cache one more time in case of connection loss
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        if (cached.exists) return cached;
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _assertCanWriteMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser user,
    required DateTime now,
  }) async {
    final normalizedStudentId = studentId.trim();

    final results = await Future.wait([
      _canUserManageAttendance(user, teamId),
      _getSession(teamId, sessionId),
    ]);

    final canManage = results[0] as bool;
    if (!canManage) {
      throw const AttendancePermissionDeniedFailure();
    }

    final session = results[1] as AttendanceSession?;
    if (session == null) {
      throw const AttendanceSessionNotFoundFailure();
    }

    if (!session.studentIdsSnapshot.contains(normalizedStudentId)) {
      throw const AttendanceStudentNotInSessionFailure();
    }

    if (!session.isOpenAt(now)) {
      throw const AttendanceSessionClosedFailure();
    }
  }

  Future<AttendanceSession?> _getSession(
    String teamId,
    String sessionId,
  ) async {
    return _sessionLocalDatasource.getCachedSessionById(sessionId);
  }

  Future<bool> _canUserManageAttendance(AuthUser user, String teamId) async {
    if (user.isArchived) return false;
    if (user.role == UserRole.admin) return true;
    if (user.role != UserRole.servant) return false;

    final normalizedTeamId = teamId.trim();
    if (user.effectiveAssignedTeamIds.contains(normalizedTeamId)) {
      return true;
    }

    final groupId = user.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      try {
        final cachedTeam = await _teamLocalDatasource.getCachedTeamById(normalizedTeamId);
        if (cachedTeam != null) {
          return cachedTeam.groupId == groupId;
        }
      } catch (_) {}
    }

    return false;
  }

  Future<void> createMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    required AttendanceMarkStatus status,
    String? note,
  }) async {
    final now = _nowProvider();
    final normalizedStudentId = studentId.trim();

    // 1. Pessimistic validation using local caches.
    await _assertCanWriteMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      user: markedBy,
      now: now,
    );

    final localMark = AttendanceMark(
      studentId: normalizedStudentId,
      studentNameSnapshot: studentNameSnapshot,
      status: status,
      markedByUserId: markedBy.uid,
      markedByName: markedBy.name,
      markedAt: now,
      updatedAt: now,
      note: note,
    );

    // Save to local cache first
    await _localDatasource.cacheMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      mark: localMark,
    );

    final markData = {
      'teamId': teamId,
      'sessionId': sessionId,
      'studentId': normalizedStudentId,
      'studentNameSnapshot': studentNameSnapshot,
      'status': status.name,
      'markedByUid': markedBy.uid,
      'markedByName': markedBy.name,
      'note': note,
      'createdAt': now.toIso8601String(),
    };

    final markSyncEntry = MarkSyncEntry(
      id: '${teamId}_${sessionId}_$normalizedStudentId',
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      operation: MarkSyncOperation.create,
      markData: markData,
      queuedAt: now,
    );

    // Attempt online Firestore write
    try {
      final markRef = _markDoc(teamId, sessionId, normalizedStudentId);
      final sessionRef = _sessionDoc(teamId, sessionId);

      await _firestore.runTransaction((transaction) async {
        transaction.set(markRef, {
          'teamId': teamId,
          'sessionId': sessionId,
          'studentId': normalizedStudentId,
          'studentNameSnapshot': studentNameSnapshot,
          'status': status.name,
          'markedByUserId': markedBy.uid,
          'markedByName': markedBy.name,
          'markedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'note': note,
        });

        if (status == AttendanceMarkStatus.present) {
          transaction.update(sessionRef, {
            'presentCount': FieldValue.increment(1),
          });
        }
      });
    } catch (error) {
      developer.log(
        'Online write failed, enqueuing mark for student $normalizedStudentId',
        error: error,
        name: 'AttendanceMarkRepository',
      );
      // On network failure or exception, enqueue to local queue
      await _localDatasource.enqueue(markSyncEntry);
    }
  }

  Future<void> updateMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser markedBy,
    required AttendanceMarkStatus status,
    String? note,
  }) async {
    final now = _nowProvider();
    final normalizedStudentId = studentId.trim();

    // 1. Pessimistic validation.
    await _assertCanWriteMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      user: markedBy,
      now: now,
    );

    final existingMark = _localDatasource.getCachedMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
    );
    final studentNameSnapshot = existingMark?.studentNameSnapshot ?? '';

    final localMark = AttendanceMark(
      studentId: normalizedStudentId,
      studentNameSnapshot: studentNameSnapshot,
      status: status,
      markedByUserId: markedBy.uid,
      markedByName: markedBy.name,
      markedAt: existingMark?.markedAt ?? now,
      updatedAt: now,
      note: note,
    );

    // Save to local cache first
    await _localDatasource.cacheMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      mark: localMark,
    );

    final markData = {
      'teamId': teamId,
      'sessionId': sessionId,
      'studentId': normalizedStudentId,
      'status': status.name,
      'markedByUid': markedBy.uid,
      'markedByName': markedBy.name,
      'note': note,
      'createdAt': now.toIso8601String(),
    };

    final markSyncEntry = MarkSyncEntry(
      id: '${teamId}_${sessionId}_$normalizedStudentId',
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      operation: MarkSyncOperation.update,
      markData: markData,
      queuedAt: now,
    );

    // Attempt online Firestore write
    try {
      final markRef = _markDoc(teamId, sessionId, normalizedStudentId);
      final sessionRef = _sessionDoc(teamId, sessionId);

      final markDoc = await _cachedGet(markRef);
      if (!markDoc.exists) return;

      final oldStatusStr = markDoc.data()?['status'] as String?;
      final oldStatus = AttendanceMarkStatus.values.firstWhere(
        (e) => e.name == oldStatusStr,
        orElse: () => AttendanceMarkStatus.absent,
      );

      await _firestore.runTransaction((transaction) async {
        transaction.update(markRef, {
          'teamId': teamId,
          'sessionId': sessionId,
          'status': status.name,
          'markedByUserId': markedBy.uid,
          'markedByName': markedBy.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'note': note,
        });

        // Update aggregation if status changed.
        if (oldStatus != status) {
          if (status == AttendanceMarkStatus.present) {
            transaction.update(sessionRef, {
              'presentCount': FieldValue.increment(1),
            });
          } else if (oldStatus == AttendanceMarkStatus.present) {
            transaction.update(sessionRef, {
              'presentCount': FieldValue.increment(-1),
            });
          }
        }
      });
    } catch (error) {
      developer.log(
        'Online update failed, enqueuing update for student $normalizedStudentId',
        error: error,
        name: 'AttendanceMarkRepository',
      );
      await _localDatasource.enqueue(markSyncEntry);
    }
  }

  Future<AttendanceMark?> getMarkForStudent({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) async {
    final normalizedStudentId = studentId.trim();

    final cachedMark = _localDatasource.getCachedMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
    );

    if (cachedMark != null) {
      unawaited(
        _markDoc(teamId, sessionId, normalizedStudentId)
            .get(const GetOptions(source: Source.server))
            .catchError((_) => _markDoc(teamId, sessionId, normalizedStudentId)
                .get(const GetOptions(source: Source.cache)))
            .then((doc) {
              final data = doc.data();
              if (doc.exists && data != null) {
                try {
                  final mark = AttendanceMark.fromMap(data, doc.id);
                  _localDatasource.cacheMark(
                    teamId: teamId,
                    sessionId: sessionId,
                    studentId: normalizedStudentId,
                    mark: mark,
                  );
                } catch (_) {}
              }
            })
            .catchError((_) {}),
      );

      return cachedMark;
    }

    final doc = await _cachedGet(
      _markDoc(teamId, sessionId, normalizedStudentId),
    );
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    try {
      final mark = AttendanceMark.fromMap(data, doc.id);
      await _localDatasource.cacheMark(
        teamId: teamId,
        sessionId: sessionId,
        studentId: normalizedStudentId,
        mark: mark,
      );
      return mark;
    } catch (error) {
      developer.log(
        'malformed mark for student $normalizedStudentId',
        error: error,
        name: 'AttendanceMarkRepository',
      );
      return null;
    }
  }
}
