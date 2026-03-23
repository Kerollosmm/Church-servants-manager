import 'dart:math' show max, min;

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class AttendanceRepository implements IAttendanceRepository {
  AttendanceRepository({
    FirebaseFirestore? firestore,
    StudentQueryService? studentQueryService,
    DateTime Function()? nowProvider,
    Stream<DateTime>? clockStream,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
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

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

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

  DocumentReference<Map<String, dynamic>> _markDoc(
    String teamId,
    String sessionId,
    String studentId,
  ) => _marksCol(teamId, sessionId).doc(studentId);

  Stream<DateTime> _watchClock() {
    final source =
        _clockStream ??
        Stream<DateTime>.periodic(
          const Duration(seconds: 15),
          (_) => _nowProvider(),
        );
    return source.startWith(_nowProvider());
  }

  List<List<T>> _chunkList<T>(List<T> input, int chunkSize) {
    final chunks = <List<T>>[];
    for (var index = 0; index < input.length; index += chunkSize) {
      chunks.add(input.sublist(index, min(index + chunkSize, input.length)));
    }
    return chunks;
  }

  String _normalizeTitle(String? title) {
    return title?.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase() ?? '';
  }

  String _slugifyTitle(String? title) {
    final cleaned = _normalizeTitle(title)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
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

  AttendanceMark? _mapMarkOrNull(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    try {
      return AttendanceMark.fromMap(data, doc.id);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'AttendanceRepository: skipped malformed attendance mark '
          '${doc.reference.path} (${error.runtimeType})',
        );
      }
      return null;
    }
  }

  List<AttendanceSession> _mapSessionsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sessions = <AttendanceSession>[];
    for (final doc in snapshot.docs) {
      try {
        sessions.add(_mapSessionDoc(doc));
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'AttendanceRepository: skipped malformed attendance session '
            '${doc.reference.path} (${error.runtimeType})',
          );
        }
      }
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }

  Stream<Map<String, StudentModel>> _watchStudentsByIds(
    List<String> studentIds,
  ) {
    final normalizedIds = studentIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedIds.isEmpty) {
      return Stream.value(const <String, StudentModel>{});
    }

    final chunks = _chunkList(normalizedIds, 10);
    final streams = chunks
        .map((chunk) {
          return _studentsCollection
              .where(FieldPath.documentId, whereIn: chunk)
              .snapshots()
              .map((snapshot) {
                final byId = <String, StudentModel>{};
                for (final student in _studentQueryService.mapStudentDocs(
                  snapshot.docs,
                )) {
                  byId[student.docID] = student;
                }
                return byId;
              });
        })
        .toList(growable: false);

    if (streams.length == 1) {
      return streams.first;
    }

    return Rx.combineLatestList(streams).map((results) {
      final merged = <String, StudentModel>{};
      for (final chunkMap in results) {
        merged.addAll(chunkMap);
      }
      return merged;
    });
  }

  Stream<Map<String, AttendanceMark>> _watchMarksMap(
    String teamId,
    String sessionId,
  ) {
    return _marksCol(teamId, sessionId).snapshots().map((snapshot) {
      final marks = <String, AttendanceMark>{};
      for (final doc in snapshot.docs) {
        try {
          marks[doc.id] = AttendanceMark.fromMap(doc.data(), doc.id);
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              'AttendanceRepository: skipped malformed attendance mark '
              '${doc.reference.path} (${error.runtimeType})',
            );
          }
        }
      }
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
    Query<Map<String, dynamic>> query = _firestore
        .collectionGroup(FirestoreCollections.attendanceSessions)
        .where('studentIdsSnapshot', arrayContains: studentId);
    final normalizedTeamId = teamId?.trim() ?? '';
    if (normalizedTeamId.isNotEmpty) {
      query = query.where('teamId', isEqualTo: normalizedTeamId);
    }
    return query;
  }

  Stream<List<AttendanceSession>> _watchStudentSessions({
    required String studentId,
    String? teamId,
  }) {
    return _studentSessionsQuery(
      studentId: studentId,
      teamId: teamId,
    ).snapshots().map(_mapSessionsSnapshot);
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

  Future<Map<String, String>> _loadStudentNamesByIds(
    List<String> studentIds,
  ) async {
    if (studentIds.isEmpty) return const <String, String>{};
    final chunks = _chunkList(studentIds, 10);
    final names = <String, String>{};
    for (final chunk in chunks) {
      final snapshot = await _studentsCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final student in _studentQueryService.mapStudentDocs(
        snapshot.docs,
      )) {
        names[student.docID] = student.name;
      }
    }
    return names;
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
      await assertUserCanManageAttendance(user: markedBy, teamId: teamId);
      final session = await _getRequiredSession(
        teamId: teamId,
        sessionId: sessionId,
      );
      _assertStudentInSession(session, studentId);
      _assertSessionWritable(session, _nowProvider());

      final markRef = _markDoc(teamId, sessionId, studentId);
      final existing = await markRef.get();
      final existingMarkedAt = existing.data()?['markedAt'];
      final effectiveStudentName = studentNameSnapshot.trim().isNotEmpty
          ? studentNameSnapshot.trim()
          : (session.studentNameSnapshots[studentId] ?? 'مخدوم');
      final normalizedNote = note?.trim();

      await markRef.set({
        'studentNameSnapshot': effectiveStudentName,
        'status': status.name,
        'markedByUserId': markedBy.uid,
        'markedByName': markedBy.name,
        'markedAt': existingMarkedAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'note': normalizedNote == null || normalizedNote.isEmpty
            ? FieldValue.delete()
            : normalizedNote,
      }, SetOptions(merge: true));
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

      final existingSnapshot = await _sessionsCol(
        normalizedTeamId,
      ).where('isClosed', isEqualTo: false).get();
      final existingSessions = _mapSessionsSnapshot(existingSnapshot);
      for (final existing in existingSessions) {
        final isActiveConflict =
            !existing.isEffectivelyClosedAt(now) &&
            _sessionsOverlap(candidate, existing);
        if (isActiveConflict ||
            _isDuplicateSessionCandidate(candidate, existing)) {
          throw const AttendanceSessionConflictFailure();
        }
      }

      final docRef = _sessionDoc(normalizedTeamId, candidate.id);
      await _firestore.runTransaction((transaction) async {
        final existingDoc = await transaction.get(docRef);
        if (existingDoc.exists) {
          throw const AttendanceSessionConflictFailure(
            'تم إنشاء جلسة حضور مطابقة بالفعل.',
          );
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

      await _sessionDoc(
        teamId,
        sessionId,
      ).update({'isClosed': true, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
  Stream<List<AttendanceSession>> watchSessionsForTeam(String teamId) {
    return _sessionsCol(teamId)
        .orderBy('startsAt', descending: true)
        .snapshots()
        .map(_mapSessionsSnapshot);
  }

  @override
  Stream<AttendanceSession?> watchActiveSessionForTeam(String teamId) {
    return Rx.combineLatest2(watchSessionsForTeam(teamId), _watchClock(), (
      List<AttendanceSession> sessions,
      DateTime now,
    ) {
      return sessions.cast<AttendanceSession?>().firstWhere(
        (s) => s!.isOpenAt(now),
        orElse: () => null,
      );
    });
  }

  @override
  Stream<AttendanceSession?> watchSessionById({
    required String teamId,
    required String sessionId,
  }) {
    return _sessionDoc(teamId, sessionId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return AttendanceSession.fromMap(data, doc.id);
    });
  }

  @override
  Future<AttendanceSession?> getSessionById({
    required String teamId,
    required String sessionId,
  }) async {
    try {
      final doc = await _sessionDoc(teamId, sessionId).get();
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
      await _markDoc(teamId, sessionId, studentId).delete();
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
      await assertUserCanManageAttendance(user: markedBy, teamId: teamId);
      final session = await _getRequiredSession(
        teamId: teamId,
        sessionId: sessionId,
      );
      _assertSessionWritable(session, _nowProvider());

      final existingMarks = await _marksCol(teamId, sessionId).get();
      final alreadyMarkedIds = existingMarks.docs.map((doc) => doc.id).toSet();
      final remainingIds = session.studentIdsSnapshot
          .where((studentId) => !alreadyMarkedIds.contains(studentId))
          .toList(growable: false);
      if (remainingIds.isEmpty) return;

      final liveNames = await _loadStudentNamesByIds(remainingIds);
      final batch = _firestore.batch();

      for (final studentId in remainingIds) {
        batch.set(_markDoc(teamId, sessionId, studentId), {
          'studentNameSnapshot':
              liveNames[studentId] ??
              session.studentNameSnapshots[studentId] ??
              'مخدوم',
          'status': AttendanceMarkStatus.present.name,
          'markedByUserId': markedBy.uid,
          'markedByName': markedBy.name,
          'markedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  @override
  Stream<List<AttendanceRosterItem>> watchSessionRoster({
    required String teamId,
    required String sessionId,
  }) {
    return watchSessionRosterSnapshot(
      teamId: teamId,
      sessionId: sessionId,
    ).map((snapshot) => snapshot.roster);
  }

  @override
  Stream<AttendanceRosterSnapshot> watchSessionRosterSnapshot({
    required String teamId,
    required String sessionId,
  }) {
    final marksStream = _watchMarksMap(teamId, sessionId);

    return watchSessionById(teamId: teamId, sessionId: sessionId)
        .switchMap((session) {
          if (session == null) {
            return Stream<AttendanceRosterSnapshot>.error(
              const AttendanceSessionNotFoundFailure(),
            );
          }

          return Rx.combineLatest3(
            _watchStudentsByIds(session.studentIdsSnapshot),
            marksStream,
            _watchClock(),
            (
              Map<String, StudentModel> studentsById,
              Map<String, AttendanceMark> marksById,
              DateTime now,
            ) {
              return _buildRosterSnapshot(
                session: session,
                studentsById: studentsById,
                marksById: marksById,
                now: now,
              );
            },
          );
        });
  }

  @override
  Stream<List<StudentAttendanceHistoryItem>> watchStudentAttendanceHistory({
    required String studentId,
    String? teamId,
  }) {
    return _watchStudentSessions(
      studentId: studentId,
      teamId: teamId,
    ).switchMap((sessions) {
      if (sessions.isEmpty) {
        return Stream.value(const <StudentAttendanceHistoryItem>[]);
      }

      final markStreams = sessions
          .map((session) {
            return _markDoc(
              session.teamId,
              session.id,
              studentId,
            ).snapshots().map((doc) {
              return (session: session, mark: _mapMarkOrNull(doc));
            });
          })
          .toList(growable: false);

      return Rx.combineLatest2(
        Rx.combineLatestList(markStreams),
        _watchClock(),
        (
          List<({AttendanceSession session, AttendanceMark? mark})> entries,
          DateTime now,
        ) {
          final history = entries
              .map((entry) {
                final session = entry.session;
                final mark = entry.mark;
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
          history.sort(
            (first, second) =>
                second.sessionStartsAt.compareTo(first.sessionStartsAt),
          );
          return history;
        },
      );
    });
  }

  @override
  Future<StudentAttendanceStats> getStudentAttendanceStats({
    required String studentId,
    String? teamId,
    DateTimeRange? range,
  }) async {
    try {
      final sessions = await _loadStudentSessions(
        studentId: studentId,
        teamId: teamId,
        range: range,
      );
      final now = _nowProvider();

      final history = await Future.wait(
        sessions.map((session) async {
          final mark = _mapMarkOrNull(
            await _markDoc(session.teamId, session.id, studentId).get(),
          );
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
        }),
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
      final snapshot = await _sessionsCol(teamId).get();
      final sessions = _mapSessionsSnapshot(snapshot);
      final now = _nowProvider();

      var totalSessions = 0;
      var totalRosterEntries = 0;
      var presentCount = 0;
      var lateCount = 0;
      var absentCount = 0;
      final uniqueStudentIds = <String>{};

      for (final session in sessions) {
        final inRange =
            range == null ||
            (!session.startsAt.isBefore(range.start) &&
                !session.startsAt.isAfter(range.end));
        if (!inRange || !session.isEffectivelyClosedAt(now)) {
          continue;
        }

        totalSessions += 1;
        totalRosterEntries += session.studentIdsSnapshot.length;
        uniqueStudentIds.addAll(session.studentIdsSnapshot);

        final marksSnapshot = await _marksCol(teamId, session.id).get();
        var sessionMarkedCount = 0;
        for (final doc in marksSnapshot.docs) {
          try {
            final mark = AttendanceMark.fromMap(doc.data(), doc.id);
            sessionMarkedCount += 1;
            if (mark.status == AttendanceMarkStatus.present) {
              presentCount += 1;
            } else {
              lateCount += 1;
            }
          } catch (error) {
            if (kDebugMode) {
              debugPrint(
                'AttendanceRepository: skipped malformed attendance mark '
                '${doc.reference.path} (${error.runtimeType})',
              );
            }
          }
        }

        absentCount += max(
          0,
          session.studentIdsSnapshot.length - sessionMarkedCount,
        );
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
    return user.effectiveAssignedTeamIds.contains(teamId.trim());
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
