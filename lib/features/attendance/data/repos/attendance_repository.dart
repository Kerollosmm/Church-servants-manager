import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/utils/bulk_operation_result.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// Repository for attendance data and operations.
///
/// Handles session CRUD, mark management, roster tracking,
/// and attendance statistics. Uses [StudentQueryService] for
/// student lookups and delegates to Firestore.
class AttendanceRepository implements IAttendanceRepository {
  AttendanceRepository({
    required FirebaseFirestore firestore,
    StudentQueryService? studentQueryService,
    DateTime Function()? nowProvider,
    Stream<DateTime>? clockStream,
  }) : _firestore = firestore,
       _studentQueryService =
           studentQueryService ?? StudentQueryService(firestore: firestore),
       _nowProvider = nowProvider ?? DateTime.now,
       _clockStream = clockStream;

  final FirebaseFirestore _firestore;
  final StudentQueryService _studentQueryService;
  final DateTime Function() _nowProvider;
  final Stream<DateTime>? _clockStream;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);

  DocumentReference<Map<String, dynamic>> _teamDoc(String teamId) =>
      _classesCollection.doc(teamId);

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

  /// Builds a deterministic mark document reference.
  /// Uses studentId_servantId to allow each servant to have their own record,
  /// preventing Last-Write-Wins conflicts and enabling additive syncing.
  DocumentReference<Map<String, dynamic>> _markDoc(
    String teamId,
    String sessionId,
    String studentId,
    String servantId,
  ) => _marksCol(teamId, sessionId).doc('${studentId}_$servantId');

  Stream<DateTime> _watchClock({
    Duration interval = const Duration(seconds: 15),
  }) {
    final source =
        _clockStream ??
        Stream<DateTime>.periodic(interval, (_) => _nowProvider());
    return source.startWith(_nowProvider());
  }

  Stream<DateTime> _watchSessionBoundary(AttendanceSession session) {
    final clockStream = _clockStream;
    if (clockStream != null) {
      return clockStream
          .where((tick) => !tick.isBefore(session.endsAt))
          .startWith(_nowProvider());
    }

    final controller = StreamController<DateTime>()..add(_nowProvider());
    final now = _nowProvider();
    if (session.endsAt.isAfter(now)) {
      Future.delayed(session.endsAt.difference(now)).then((_) {
        if (!controller.isClosed) {
          controller
            ..add(_nowProvider())
            ..close();
        }
      });
    } else {
      controller.close();
    }
    return controller.stream;
  }

  String _normalizeTitle(String? title) {
    return title?.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase() ?? '';
  }

  String _slugifyTitle(String? title) {
    final normalized = _normalizeTitle(title);
    final slug = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    if (cleaned.isEmpty) return 'session';
    if (cleaned.length <= 40) return cleaned;
    return cleaned.substring(0, 40);
  }

  String _buildSessionId(DateTime startsAt, String? title) {
    final dateKey = AttendanceSession.buildDateKey(startsAt);
    final timeKey = startsAt.toUtc().millisecondsSinceEpoch;
    return '${dateKey}_${timeKey}_${_slugifyTitle(title)}';
  }

  bool _sessionsOverlap(AttendanceSession first, AttendanceSession second) {
    return first.startsAt.isBefore(second.endsAt) &&
        second.startsAt.isBefore(first.endsAt);
  }

  bool _isDuplicateSessionCandidate(
    AttendanceSession candidate,
    AttendanceSession existing,
  ) {
    return candidate.dateKey == existing.dateKey &&
        candidate.startsAt.millisecondsSinceEpoch ==
            existing.startsAt.millisecondsSinceEpoch &&
        candidate.durationMinutes == existing.durationMinutes &&
        _normalizeTitle(candidate.title) == _normalizeTitle(existing.title);
  }

  void _assertAdmin(AuthUser user) {
    if (user.role != UserRole.admin) {
      throw const AttendancePermissionDeniedFailure(
        'ليس لديك صلاحية لإدارة جلسات الحضور.',
      );
    }
  }

  void _assertStudentInSession(AttendanceSession session, String studentId) {
    if (!session.studentIdsSnapshot.contains(studentId.trim())) {
      throw const AttendanceStudentNotInSessionFailure();
    }
  }

  void _assertSessionWritable(AttendanceSession session, DateTime now) {
    if (!session.isOpenAt(now)) {
      throw const AttendanceSessionClosedFailure();
    }
  }

  Future<void> _assertTeamIsActive(String teamId) async {
    final teamDoc = await _teamDoc(teamId).get();
    final teamData = teamDoc.data();
    if (!teamDoc.exists || teamData == null) {
      throw const AttendanceValidationFailure(
        'تعذر العثور على الفريق المطلوب.',
      );
    }
    if (teamData['isArchived'] == true) {
      throw const AttendanceValidationFailure(
        'لا يمكن إنشاء جلسة حضور لفريق مؤرشف.',
      );
    }
  }

  AttendanceSession _mapSessionDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AttendanceSession.fromMap(doc.data(), doc.id);
  }

  List<AttendanceSession> _mapSessionsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sessions = <AttendanceSession>[];
    for (final doc in snapshot.docs) {
      try {
        sessions.add(_mapSessionDoc(doc));
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

  /// Aggregates a stream of marks from all servants.
  /// For each student, the most recently updated mark is selected.
  Stream<Map<String, AttendanceMark>> _watchMarksMap(
    String teamId,
    String sessionId,
  ) {
    return _marksCol(teamId, sessionId).snapshots().map((snapshot) {
      final marks = <String, AttendanceMark>{};
      final studentMarks = <String, List<AttendanceMark>>{};

      for (final doc in snapshot.docs) {
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

      // Aggregate: Pick the mark with latest updatedAt for each student
      studentMarks.forEach((studentId, list) {
        if (list.isEmpty) return;
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        marks[studentId] = list.first;
      });

      return marks;
    });
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
          ? student!.name.trim()
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
      return _sessionsCol(
        normalizedTeamId,
      ).where('studentIdsSnapshot', arrayContains: studentId);
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

  Future<AttendanceSession> _getRequiredSession({
    required String teamId,
    required String sessionId,
  }) async {
    final session = await getSessionById(teamId: teamId, sessionId: sessionId);
    if (session == null) {
      throw const AttendanceSessionNotFoundFailure();
    }
    return session;
  }

  Future<void> _writeMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    required AttendanceMarkStatus status,
    String? note,
  }) async {
    try {
      final results = await Future.wait([
        canUserManageAttendance(user: markedBy, teamId: teamId),
        getSessionById(teamId: teamId, sessionId: sessionId),
      ]);
      final canManage = results[0] as bool;
      if (!canManage) {
        throw const AttendancePermissionDeniedFailure();
      }
      final session = results[1] as AttendanceSession?;
      if (session == null) {
        throw const AttendanceSessionNotFoundFailure();
      }
      _assertStudentInSession(session, studentId);
      _assertSessionWritable(session, _nowProvider());

      // Use deterministic ID: studentId_servantId for additive sync
      final markRef = _markDoc(teamId, sessionId, studentId, markedBy.uid);
      final effectiveStudentName = studentNameSnapshot.trim().isNotEmpty
          ? studentNameSnapshot.trim()
          : (session.studentNameSnapshots[studentId] ?? 'مخدوم');
      final normalizedNote = note?.trim();

      await _firestore.runTransaction((transaction) async {
        final existingDoc = await transaction.get(markRef);
        final existingMarkedAt = existingDoc.data()?['markedAt'];

        final data = <String, dynamic>{
          'studentId': studentId, // Explicit field for querying
          'status': status.name,
          'markedByUserId': markedBy.uid,
          'markedByName': markedBy.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'note': normalizedNote == null || normalizedNote.isEmpty
              ? FieldValue.delete()
              : normalizedNote,
        };

        if (existingMarkedAt == null) {
          data['studentNameSnapshot'] = effectiveStudentName;
          data['markedAt'] = FieldValue.serverTimestamp();
        } else {
          data['markedAt'] = existingMarkedAt;
        }

        transaction.set(markRef, data, SetOptions(merge: true));
      });
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
  Future<AttendanceSession> createSession({
    required String teamId,
    required String teamNameSnapshot,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  }) async {
    try {
      final normalizedTeamId = teamId.trim();
      if (normalizedTeamId.isEmpty) {
        throw const AttendanceValidationFailure(
          'يجب اختيار الفريق قبل إنشاء الجلسة.',
        );
      }
      if (durationMinutes <= 0) {
        throw const AttendanceValidationFailure(
          'مدة الجلسة يجب أن تكون أكبر من صفر.',
        );
      }

      await assertUserCanManageAttendance(
        user: createdBy,
        teamId: normalizedTeamId,
      );
      await _assertTeamIsActive(normalizedTeamId);

      final normalizedTitle = title?.trim();
      final now = _nowProvider();
      final rosterStudents = await _studentQueryService.getStudentsByClass(
        normalizedTeamId,
      );
      rosterStudents.sort((first, second) => first.name.compareTo(second.name));

      final candidate = AttendanceSession(
        id: _buildSessionId(startsAt, normalizedTitle),
        teamId: normalizedTeamId,
        teamNameSnapshot: teamNameSnapshot.trim().isEmpty
            ? null
            : teamNameSnapshot.trim(),
        title: normalizedTitle == null || normalizedTitle.isEmpty
            ? null
            : normalizedTitle,
        dateKey: AttendanceSession.buildDateKey(startsAt),
        startsAt: startsAt,
        endsAt: startsAt.add(Duration(minutes: durationMinutes)),
        durationMinutes: durationMinutes,
        createdByUserId: createdBy.uid,
        createdByName: createdBy.name,
        createdAt: now,
        updatedAt: now,
        studentIdsSnapshot: rosterStudents
            .map((student) => student.docID)
            .toList(growable: false),
        studentNameSnapshots: {
          for (final student in rosterStudents) student.docID: student.name,
        },
      );

      final docRef = _sessionDoc(normalizedTeamId, candidate.id);
      await _firestore.runTransaction((transaction) async {
        final existingDoc = await transaction.get(docRef);
        if (existingDoc.exists) {
          throw const AttendanceSessionConflictFailure(
            'تم إنشاء جلسة حضور مطابقة بالفعل.',
          );
        }

        final activeSessionsSnapshot = await _sessionsCol(
          normalizedTeamId,
        ).where('isClosed', isEqualTo: false).get();
        final existingSessions = _mapSessionsSnapshot(activeSessionsSnapshot);

        for (final existing in existingSessions) {
          final isActiveConflict =
              !existing.isEffectivelyClosedAt(now) &&
              _sessionsOverlap(candidate, existing);
          if (isActiveConflict ||
              _isDuplicateSessionCandidate(candidate, existing)) {
            throw const AttendanceSessionConflictFailure();
          }
        }

        transaction.set(docRef, {
          ...candidate.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return candidate;
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
  Future<BulkOperationResult<String>> createSessionsBulk({
    required Map<String, String> teamIdsAndNames,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  }) async {
    final successfulItems = <String>[];
    final failedItems = <String>[];

    final futures = teamIdsAndNames.entries.map((entry) async {
      try {
        await createSession(
          teamId: entry.key,
          teamNameSnapshot: entry.value,
          startsAt: startsAt,
          durationMinutes: durationMinutes,
          createdBy: createdBy,
          title: title,
        );
        successfulItems.add(entry.key);
      } catch (error) {
        developer.log(
          'Bulk session creation failed for team ${entry.key}',
          error: error,
          name: 'AttendanceRepository',
        );
        failedItems.add(entry.key);
      }
    });

    await Future.wait(futures);

    return BulkOperationResult(
      successfulItems: successfulItems,
      failedItems: failedItems,
    );
  }

  @override
  Future<void> closeSession({
    required String teamId,
    required String sessionId,
    required AuthUser closedBy,
  }) async {
    try {
      _assertAdmin(closedBy);
      final session = await _getRequiredSession(
        teamId: teamId,
        sessionId: sessionId,
      );
      if (session.isClosed) {
        return;
      }

      final marksSnapshot = await _marksCol(teamId, sessionId).get();
      final markedStudentIds = <String>{};
      final presentStudentIds = <String>{};

      for (final doc in marksSnapshot.docs) {
        final studentId = doc.id.split('_').first;
        markedStudentIds.add(studentId);
        final status = doc.data()['status'];
        if (status == 'present' || status == 'late') {
          presentStudentIds.add(studentId);
        }
      }

      final unmarkedStudents = session.studentIdsSnapshot
          .where((id) => !markedStudentIds.contains(id))
          .toList(growable: false);

      final totalOperations =
          unmarkedStudents.length +
          presentStudentIds.length +
          2; // +1 for session, +1 for group

      if (totalOperations <= 500) {
        // Atomic update for everything via transaction (Idempotent)
        await _firestore.runTransaction((transaction) async {
          final sessionRef = _sessionDoc(teamId, sessionId);
          final sessionDoc = await transaction.get(sessionRef);

          if (sessionDoc.exists && sessionDoc.data()?['isClosed'] == true) {
            // Already closed, skip to avoid double-incrementing aggregates
            return;
          }

          // 1. Mark unmarked students as absent
          for (final studentId in unmarkedStudents) {
            final markRef = _markDoc(teamId, sessionId, studentId, 'system');
            transaction.set(markRef, {
              'studentId': studentId,
              'studentNameSnapshot':
                  session.studentNameSnapshots[studentId] ?? 'مخدوم',
              'status': AttendanceMarkStatus.absent.name,
              'markedByUserId': 'system',
              'markedByName': 'النظام',
              'markedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // 2. Update Student Aggregates
          for (final studentId in presentStudentIds) {
            final studentRef = _firestore
                .collection(FirestoreCollections.students)
                .doc(studentId);
            transaction.set(studentRef, {
              'attendanceSummary': {
                'totalPresent': FieldValue.increment(1),
                'lastAttendanceDate': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          // 3. Update Group Aggregate
          transaction
            ..set(_teamDoc(teamId), {
              'groupAttendanceSummary': {
                'lastSessionDate': FieldValue.serverTimestamp(),
                'lastSessionAttendanceCount': presentStudentIds.length,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            ..update(sessionRef, {
              'isClosed': true,
              'updatedAt': FieldValue.serverTimestamp(),
              'presentCount': presentStudentIds.length,
              'absentCount':
                  session.studentIdsSnapshot.length - presentStudentIds.length,
            });
        });
      } else {
        // Fallback for very large groups: multi-batch (Not fully atomic, but idempotent)
        // We do ALL student updates first (present aggregates + absent marks),
        // and the session status LAST in a transaction.

        // 1. Mark unmarked as absent in chunks
        final unmarkedList = unmarkedStudents.toList();
        for (final chunk in unmarkedList.chunk(450)) {
          final batch = _firestore.batch();
          for (final studentId in chunk) {
            final markRef = _markDoc(teamId, sessionId, studentId, 'system');
            batch.set(markRef, {
              'studentId': studentId,
              'studentNameSnapshot':
                  session.studentNameSnapshots[studentId] ?? 'مخدوم',
              'status': AttendanceMarkStatus.absent.name,
              'markedByUserId': 'system',
              'markedByName': 'النظام',
              'markedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }

        // 2. Student Aggregates (Batched)
        final studentIdsList = presentStudentIds.toList();
        for (final chunk in studentIdsList.chunk(450)) {
          final batch = _firestore.batch();
          for (final studentId in chunk) {
            final studentRef = _firestore
                .collection(FirestoreCollections.students)
                .doc(studentId);
            batch.set(studentRef, {
              'attendanceSummary': {
                'totalPresent': FieldValue.increment(1),
                'lastAttendanceDate': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          await batch.commit();
        }

        // 3. Final IDEMPOTENT step for group aggregate and session status
        await _firestore.runTransaction((transaction) async {
          final sessionRef = _sessionDoc(teamId, sessionId);
          final sessionDoc = await transaction.get(sessionRef);

          if (sessionDoc.exists && sessionDoc.data()?['isClosed'] == true) {
            return;
          }

          transaction
            ..set(_teamDoc(teamId), {
              'groupAttendanceSummary': {
                'lastSessionDate': FieldValue.serverTimestamp(),
                'lastSessionAttendanceCount': presentStudentIds.length,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            ..update(sessionRef, {
              'isClosed': true,
              'updatedAt': FieldValue.serverTimestamp(),
              'presentCount': presentStudentIds.length,
              'absentCount':
                  session.studentIdsSnapshot.length - presentStudentIds.length,
            });
        });
      }
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
  Future<List<AttendanceSession>> getSessionsForTeam(String teamId) async {
    final snapshot = await _sessionsCol(teamId)
        .orderBy('startsAt', descending: true)
        .limit(50)
        .get(const GetOptions());
    return _mapSessionsSnapshot(snapshot);
  }

  @override
  Future<AttendanceSession?> getActiveSessionForTeam(String teamId) async {
    final snapshot = await _sessionsCol(teamId)
        .where('isClosed', isEqualTo: false)
        .orderBy('startsAt', descending: true)
        .limit(10)
        .get(const GetOptions());
    final sessions = _mapSessionsSnapshot(snapshot);
    final now = _nowProvider();
    for (final session in sessions) {
      if (session.isOpenAt(now)) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<AttendanceSession?> getSessionById({
    required String teamId,
    required String sessionId,
  }) async {
    try {
      final doc = await _sessionDoc(
        teamId,
        sessionId,
      ).get(const GetOptions());
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return AttendanceSession.fromMap(data, doc.id);
    } catch (error) {
      throw mapExceptionToAttendanceFailure(error);
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
  }) {
    return _writeMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      studentNameSnapshot: studentNameSnapshot,
      markedBy: markedBy,
      status: AttendanceMarkStatus.present,
      note: note,
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
  }) {
    return _writeMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      studentNameSnapshot: studentNameSnapshot,
      markedBy: markedBy,
      status: AttendanceMarkStatus.late,
      note: note,
    );
  }

  Future<void> batchWriteMarks({
    required String teamId,
    required String sessionId,
    required Map<String, AttendanceMarkStatus> marks,
    required AuthUser markedBy,
    bool cachedPermission = false,
  }) async {
    try {
      // Step 1: Validate ONCE (skip if cached from cubit)
      if (!cachedPermission) {
        final canManage = await canUserManageAttendance(
          user: markedBy,
          teamId: teamId,
        );
        if (!canManage) throw const AttendancePermissionDeniedFailure();
      }

      // Step 2: Fetch session ONCE
      final session = await getSessionById(
        teamId: teamId,
        sessionId: sessionId,
      );
      if (session == null) throw const AttendanceSessionNotFoundFailure();
      _assertSessionWritable(session, _nowProvider());

      // Step 3: Validate all studentIds are in session roster
      for (final studentId in marks.keys) {
        _assertStudentInSession(session, studentId);
      }

      // Step 4: Write all marks in batches of 400
      final entries = marks.entries.toList(growable: false);
      for (var i = 0; i < entries.length; i += 400) {
        final chunk = entries.sublist(
          i,
          i + 400 > entries.length ? entries.length : i + 400,
        );
        final batch = _firestore.batch();
        for (final entry in chunk) {
          final studentId = entry.key;
          final status = entry.value;
          final markRef = _markDoc(teamId, sessionId, studentId, markedBy.uid);
          final studentName =
              session.studentNameSnapshots[studentId] ?? 'مخدوم';
          batch.set(markRef, {
            'studentId': studentId,
            'studentNameSnapshot': studentName,
            'status': status.name,
            'markedByUserId': markedBy.uid,
            'markedByName': markedBy.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
  Future<void> clearStudentMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser requestedBy,
  }) async {
    try {
      await assertUserCanManageAttendance(user: requestedBy, teamId: teamId);
      final session = await _getRequiredSession(
        teamId: teamId,
        sessionId: sessionId,
      );
      _assertStudentInSession(session, studentId);
      _assertSessionWritable(session, _nowProvider());

      // Delete specifically the mark from this servant
      await _markDoc(teamId, sessionId, studentId, requestedBy.uid).delete();
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
  Future<void> markAllPresentForRemainingStudents({
    required String teamId,
    required String sessionId,
    required AuthUser markedBy,
  }) async {
    try {
      final results = await Future.wait([
        canUserManageAttendance(user: markedBy, teamId: teamId),
        getSessionById(teamId: teamId, sessionId: sessionId),
      ]);
      final canManage = results[0] as bool;
      if (!canManage) {
        throw const AttendancePermissionDeniedFailure();
      }
      final session = results[1] as AttendanceSession?;
      if (session == null) {
        throw const AttendanceSessionNotFoundFailure();
      }
      _assertSessionWritable(session, _nowProvider());

      final existingMarksSnapshot = await _marksCol(teamId, sessionId).get();
      final existingMarkedStudentIds = existingMarksSnapshot.docs
          .map((doc) => doc.id.split('_').first)
          .toSet();

      final unmarkedStudents = session.studentIdsSnapshot
          .where((id) => !existingMarkedStudentIds.contains(id))
          .toList(growable: false);

      for (final chunk in unmarkedStudents.chunk(400)) {
        final batch = _firestore.batch();
        for (final studentId in chunk) {
          final markRef = _markDoc(teamId, sessionId, studentId, markedBy.uid);
          final studentName =
              session.studentNameSnapshots[studentId] ?? 'مخدوم';

          batch.set(markRef, {
            'studentId': studentId,
            'studentNameSnapshot': studentName,
            'status': AttendanceMarkStatus.present.name,
            'markedByUserId': markedBy.uid,
            'markedByName': markedBy.name,
            'markedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        batch.set(_sessionDoc(teamId, sessionId), {
          'presentCount': FieldValue.increment(chunk.length),
        }, SetOptions(merge: true));
        await batch.commit();
      }
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

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
    final session = await getSessionById(teamId: teamId, sessionId: sessionId);
    if (session == null) {
      throw const AttendanceSessionNotFoundFailure();
    }

    final marksSnapshot = await _marksCol(
      teamId,
      sessionId,
    ).get(const GetOptions());

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

  @override
  Future<SessionStatus> getSessionStatus({
    required String teamId,
    required String sessionId,
  }) async {
    final doc = await _sessionDoc(
      teamId,
      sessionId,
    ).get(const GetOptions());
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

  @override
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

  @override
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

  @override
  Future<TeamAttendanceStats> getTeamAttendanceStats({
    required String teamId,
    DateTimeRange? range,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _sessionsCol(teamId);
      if (range != null) {
        query = query
            .where(
              'startsAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start),
            )
            .where(
              'startsAt',
              isLessThanOrEqualTo: Timestamp.fromDate(range.end),
            );
      }
      final snapshot = await query.get();
      final sessions = _mapSessionsSnapshot(snapshot);
      final now = _nowProvider();

      final eligibleSessions = sessions
          .where((s) => s.isEffectivelyClosedAt(now))
          .toList(growable: false);

      var totalSessions = 0;
      var totalRosterEntries = 0;
      var presentCount = 0;
      var lateCount = 0;
      var absentCount = 0;
      final uniqueStudentIds = <String>{};

      for (final session in eligibleSessions) {
        totalSessions += 1;
        totalRosterEntries += session.studentIdsSnapshot.length;
        uniqueStudentIds.addAll(session.studentIdsSnapshot);

        presentCount += session.presentCount;
        lateCount += session.lateCount;

        final sessionMarkedCount = session.presentCount + session.lateCount;
        final sessionAbsentCount =
            session.studentIdsSnapshot.length - sessionMarkedCount;
        absentCount += sessionAbsentCount < 0 ? 0 : sessionAbsentCount;
      }

      return TeamAttendanceStats(
        teamId: teamId,
        totalSessions: totalSessions,
        uniqueStudentsCount: uniqueStudentIds.length,
        totalRosterEntries: totalRosterEntries,
        presentCount: presentCount,
        lateCount: lateCount,
        absentCount: absentCount,
      );
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
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
        final doc = await _teamDoc(normalizedTeamId).get();
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

  @override
  Future<void> assertUserCanManageAttendance({
    required AuthUser user,
    required String teamId,
  }) async {
    final canManage = await canUserManageAttendance(user: user, teamId: teamId);
    if (!canManage) {
      throw const AttendancePermissionDeniedFailure();
    }
  }
}
