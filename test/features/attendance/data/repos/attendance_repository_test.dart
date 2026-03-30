import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late StreamController<DateTime> clockController;
  late DateTime currentTime;
  late AttendanceRepository repository;

  final admin = const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  final servant = const AuthUser(
    uid: 'servant-1',
    email: 'servant@example.com',
    name: 'Servant',
    role: UserRole.servant,
    isEmailVerified: true,
    assignedTeamIds: ['team-1'],
    assignedTeamId: 'team-1',
  );

  StudentModel student({required String id, required String name}) {
    return StudentModel(
      uid: id,
      docID: id,
      name: name,
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team A',
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: '',
      notes: null,
      classId: 'team-1',
    );
  }

  AttendanceSession buildSession({
    bool isClosed = false,
    DateTime? startsAt,
    DateTime? endsAt,
  }) {
    final sessionStartsAt = startsAt ?? currentTime;
    final sessionEndsAt =
        endsAt ?? sessionStartsAt.add(const Duration(minutes: 30));
    return AttendanceSession(
      id: '2026-03-09_${sessionStartsAt.toUtc().millisecondsSinceEpoch}_session',
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      title: 'Wednesday',
      dateKey: AttendanceSession.buildDateKey(sessionStartsAt),
      startsAt: sessionStartsAt,
      endsAt: sessionEndsAt,
      durationMinutes: 30,
      createdByUserId: admin.uid,
      createdByName: admin.name,
      createdAt: sessionStartsAt,
      updatedAt: sessionStartsAt,
      isClosed: isClosed,
      studentIdsSnapshot: const ['student-1'],
      studentNameSnapshots: const {'student-1': 'Mina'},
    );
  }

  Future<void> seedStudent(StudentModel value) async {
    await firestore.collection('Students').doc(value.docID).set(value.toMap());
  }

  Future<void> seedSession(AttendanceSession value) async {
    await firestore
        .collection(FirestoreCollections.classes)
        .doc(value.teamId)
        .collection(FirestoreCollections.attendanceSessions)
        .doc(value.id)
        .set(value.toMap());
  }

  Future<Map<String, dynamic>?> getMarkDoc(
    String sessionId,
    String studentId,
  ) async {
    final snapshot = await firestore
        .collection(FirestoreCollections.classes)
        .doc('team-1')
        .collection(FirestoreCollections.attendanceSessions)
        .doc(sessionId)
        .collection(FirestoreCollections.attendanceMarks)
        .doc(studentId)
        .get();
    return snapshot.data();
  }

  Future<List<Map<String, dynamic>>> getAuditDocs(String sessionId) async {
    final snapshot = await firestore
        .collection(FirestoreCollections.classes)
        .doc('team-1')
        .collection(FirestoreCollections.attendanceSessions)
        .doc(sessionId)
        .collection(FirestoreCollections.attendanceAuditEvents)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList(growable: false);
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    clockController = StreamController<DateTime>.broadcast();
    currentTime = DateTime(2026, 3, 9, 18, 0);
    await firestore.collection('Classes').doc('team-1').set({
      'name': 'Team A',
      'groupId': 'year1',
      'isArchived': false,
    });
    repository = AttendanceRepository(
      firestore: firestore,
      studentQueryService: StudentQueryService(firestore: firestore),
      nowProvider: () => currentTime,
      clockStream: clockController.stream,
    );
  });

  tearDown(() async {
    await clockController.close();
  });

  test(
    'createSession writes to the team attendance path with frozen roster',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      await seedStudent(
        student(id: 'student-2', name: 'Andrew').copyWith(classId: 'team-1'),
      );

      final session = await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      final doc = await firestore
          .collection('Classes')
          .doc('team-1')
          .collection('attendance_sessions')
          .doc(session.id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['teamId'], 'team-1');
      expect(List<String>.from(doc.data()!['studentIdsSnapshot']), [
        'student-2',
        'student-1',
      ]);
    },
  );

  test('createSession prevents duplicate open sessions', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));

    await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: admin,
      title: 'Wednesday',
    );

    expect(
      () => repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      ),
      throwsA(isA<AttendanceSessionConflictFailure>()),
    );
  });

  test('assigned servant can create a session for an active team', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));

    final session = await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: servant,
      title: 'Servant Session',
    );

    expect(session.createdByUserId, servant.uid);
  });

  test('createSession rejects archived teams', () async {
    await firestore.collection('Classes').doc('team-1').set({
      'name': 'Team A',
      'groupId': 'year1',
      'isArchived': true,
    });

    expect(
      () => repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Archived Team Session',
      ),
      throwsA(isA<AttendanceValidationFailure>()),
    );
  });

  test(
    'createSession uses deterministic IDs based on date and title',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      final startsAt = DateTime(2026, 3, 10, 10, 0);

      final session1 = await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: startsAt,
        durationMinutes: 60,
        createdBy: admin,
        title: 'Regular Service',
      );

      // Re-creating or checking ID generation logic
      final expectedId = '2026-03-10_team-1_regular-service';
      expect(session1.id, expectedId);
    },
  );

  test(
    'markStudentPresent updates attendance_history and attendance_stats read-models',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      final session = await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      await repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );

      // Verify mark doc (standard)
      final mark = await getMarkDoc(session.id, 'student-1');
      expect(mark, isNotNull);

      // Verify History Read-Model
      final historyDoc = await firestore
          .collection(FirestoreCollections.attendanceHistory)
          .doc('student-1')
          .collection('sessions')
          .doc(session.id)
          .get();

      expect(historyDoc.exists, isTrue);
      expect(historyDoc.data()!['status'], 'present');

      // Verify Stats Read-Model
      final statsDoc = await firestore
          .collection(FirestoreCollections.attendanceStats)
          .doc('student-1')
          .get();

      expect(statsDoc.exists, isTrue);
      expect(statsDoc.data()!['presentCount'], 1);
      expect(statsDoc.data()!['totalSessions'], 1);
    },
  );

  test('updating mark status adjusts stats counters correctly', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    final session = await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: admin,
      title: 'Wednesday',
    );

    // Mark Present
    await repository.markStudentPresent(
      teamId: 'team-1',
      sessionId: session.id,
      studentId: 'student-1',
      studentNameSnapshot: 'Mina',
      markedBy: servant,
    );

    // Change to Late
    await repository.markStudentLate(
      teamId: 'team-1',
      sessionId: session.id,
      studentId: 'student-1',
      studentNameSnapshot: 'Mina',
      markedBy: servant,
    );

    final statsDoc = await firestore
        .collection(FirestoreCollections.attendanceStats)
        .doc('student-1')
        .get();

    expect(statsDoc.data()!['presentCount'], 0);
    expect(statsDoc.data()!['lateCount'], 1);
    expect(statsDoc.data()!['totalSessions'], 1); // Should not increment twice
  });

  test(
    're-marking the same student updates the existing mark document',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      final session = await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      await repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );
      await repository.markStudentLate(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );

      final marks = await firestore
          .collection(FirestoreCollections.classes)
          .doc('team-1')
          .collection(FirestoreCollections.attendanceSessions)
          .doc(session.id)
          .collection(FirestoreCollections.attendanceMarks)
          .get();

      expect(marks.docs.length, 1);
      expect(marks.docs.single.id, 'student-1');
      expect(
        marks.docs.single.data()['status'],
        AttendanceMarkStatus.late.name,
      );

      final audits = await getAuditDocs(session.id);
      expect(
        audits.any((event) => event['eventType'] == 'mark.created'),
        isTrue,
      );
      expect(
        audits.any((event) => event['eventType'] == 'mark.updated'),
        isTrue,
      );
    },
  );

  test('markStudentPresent on closed session throws', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    final closedSession = buildSession(
      isClosed: true,
      startsAt: currentTime.subtract(const Duration(minutes: 30)),
      endsAt: currentTime,
    );
    await seedSession(closedSession);

    expect(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: closedSession.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      ),
      throwsA(isA<AttendanceSessionClosedFailure>()),
    );
  });

  test('re-marking the same student preserves the original markedAt', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    final session = await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: admin,
      title: 'Wednesday',
    );

    await repository.markStudentPresent(
      teamId: 'team-1',
      sessionId: session.id,
      studentId: 'student-1',
      studentNameSnapshot: 'Mina',
      markedBy: servant,
    );
    final firstMark = await getMarkDoc(session.id, 'student-1');

    await repository.markStudentPresent(
      teamId: 'team-1',
      sessionId: session.id,
      studentId: 'student-1',
      studentNameSnapshot: 'Mina',
      markedBy: servant,
    );
    final secondMark = await getMarkDoc(session.id, 'student-1');

    expect(firstMark, isNotNull);
    expect(secondMark, isNotNull);
    expect(secondMark!['markedAt'], firstMark!['markedAt']);
  });

  test(
    'updating status from present to late preserves the original markedAt',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      final session = await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      await repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );
      final firstMark = await getMarkDoc(session.id, 'student-1');

      await repository.markStudentLate(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );
      final secondMark = await getMarkDoc(session.id, 'student-1');

      expect(firstMark, isNotNull);
      expect(secondMark, isNotNull);
      expect(secondMark!['status'], AttendanceMarkStatus.late.name);
      expect(secondMark['markedAt'], firstMark!['markedAt']);
    },
  );

  test('servant cannot close a session', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    final session = await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: admin,
      title: 'Wednesday',
    );

    expect(
      () => repository.closeSession(
        teamId: 'team-1',
        sessionId: session.id,
        closedBy: servant,
      ),
      throwsA(isA<AttendancePermissionDeniedFailure>()),
    );
  });

  test(
    'createSession rejects overlapping sessions for the same team',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));

      await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      expect(
        () => repository.createSession(
          teamId: 'team-1',
          teamNameSnapshot: 'Team A',
          startsAt: currentTime.add(const Duration(minutes: 15)),
          durationMinutes: 30,
          createdBy: admin,
          title: 'Follow Up',
        ),
        throwsA(isA<AttendanceSessionConflictFailure>()),
      );
    },
  );

  test(
    'createSession allows non-overlapping sessions on the same day',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));

      await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      final secondSession = await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime.add(const Duration(minutes: 30)),
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday Late',
      );

      expect(
        secondSession.startsAt,
        currentTime.add(const Duration(minutes: 30)),
      );
    },
  );

  test('watchSessionRoster derives absent automatically after close', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    final session = buildSession(
      isClosed: false,
      startsAt: currentTime,
      endsAt: currentTime.add(const Duration(minutes: 30)),
    );
    await seedSession(session);

    final iterator = StreamIterator(
      repository.watchSessionRosterSnapshot(
        teamId: 'team-1',
        sessionId: session.id,
      ),
    );

    expect(await iterator.moveNext(), isTrue);
    expect(
      iterator.current.roster.single.effectiveStatus,
      AttendanceEffectiveStatus.unmarked,
    );
    expect(iterator.current.roster.single.isSessionOpen, isTrue);

    currentTime = currentTime.add(const Duration(minutes: 31));
    clockController.add(currentTime);

    expect(await iterator.moveNext(), isTrue);
    expect(
      iterator.current.roster.single.effectiveStatus,
      AttendanceEffectiveStatus.absent,
    );
    expect(iterator.current.roster.single.isSessionOpen, isFalse);
    await iterator.cancel();
  });

  test('present and late marks remain effective after session close', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    final session = await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: admin,
      title: 'Wednesday',
    );

    await repository.markStudentPresent(
      teamId: 'team-1',
      sessionId: session.id,
      studentId: 'student-1',
      studentNameSnapshot: 'Mina',
      markedBy: servant,
    );

    currentTime = currentTime.add(const Duration(minutes: 31));
    final presentRoster = await repository
        .watchSessionRoster(teamId: 'team-1', sessionId: session.id)
        .first;
    expect(
      presentRoster.single.effectiveStatus,
      AttendanceEffectiveStatus.present,
    );

    await firestore
        .collection(FirestoreCollections.classes)
        .doc('team-1')
        .collection(FirestoreCollections.attendanceSessions)
        .doc(session.id)
        .collection(FirestoreCollections.attendanceMarks)
        .doc('student-1')
        .set({
          'studentNameSnapshot': 'Mina',
          'status': 'late',
          'markedByUserId': servant.uid,
          'markedByName': servant.name,
          'markedAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });

    final lateRoster = await repository
        .watchSessionRoster(teamId: 'team-1', sessionId: session.id)
        .first;
    expect(lateRoster.single.effectiveStatus, AttendanceEffectiveStatus.late);
  });

  test('canUserManageAttendance is strict to assigned teams', () async {
    expect(
      await repository.canUserManageAttendance(user: admin, teamId: 'team-1'),
      isTrue,
    );
    expect(
      await repository.canUserManageAttendance(user: servant, teamId: 'team-1'),
      isTrue,
    );
    expect(
      await repository.canUserManageAttendance(user: servant, teamId: 'team-2'),
      isFalse,
    );
  });

  test('bulk mark all does not overwrite existing manual late marks', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    await seedStudent(
      student(id: 'student-2', name: 'Andrew').copyWith(classId: 'team-1'),
    );
    final session = await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: admin,
      title: 'Wednesday',
    );

    await repository.markStudentLate(
      teamId: 'team-1',
      sessionId: session.id,
      studentId: 'student-1',
      studentNameSnapshot: 'Mina',
      markedBy: servant,
    );

    await repository.markAllPresentForRemainingStudents(
      teamId: 'team-1',
      sessionId: session.id,
      markedBy: servant,
    );

    final lateMark = await getMarkDoc(session.id, 'student-1');
    final secondMark = await getMarkDoc(session.id, 'student-2');

    expect(lateMark?['status'], AttendanceMarkStatus.late.name);
    expect(secondMark?['status'], AttendanceMarkStatus.present.name);
  });

  test(
    'clearStudentMark removes current mark and writes audit history',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      final session = await repository.createSession(
        teamId: 'team-1',
        teamNameSnapshot: 'Team A',
        startsAt: currentTime,
        durationMinutes: 30,
        createdBy: admin,
        title: 'Wednesday',
      );

      await repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );

      await repository.clearStudentMark(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        requestedBy: servant,
      );

      expect(await getMarkDoc(session.id, 'student-1'), isNull);

      final audits = await getAuditDocs(session.id);
      final clearEvent = audits.firstWhere(
        (event) => event['eventType'] == 'mark.cleared',
      );
      expect(clearEvent['targetStudentId'], 'student-1');
      expect(clearEvent['actorUserId'], servant.uid);
    },
  );

  test('createSession and closeSession write session audit events', () async {
    await seedStudent(student(id: 'student-1', name: 'Mina'));
    final session = await repository.createSession(
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      startsAt: currentTime,
      durationMinutes: 30,
      createdBy: admin,
      title: 'Wednesday',
    );

    await repository.closeSession(
      teamId: 'team-1',
      sessionId: session.id,
      closedBy: admin,
    );

    final audits = await getAuditDocs(session.id);
    expect(
      audits.any((event) => event['eventType'] == 'session.created'),
      isTrue,
    );
    expect(
      audits.any((event) => event['eventType'] == 'session.closed'),
      isTrue,
    );
  });

  test(
    'getStudentAttendanceStats ignores sessions older than default window',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      final recentStart = currentTime.subtract(const Duration(days: 10));
      final oldStart = currentTime.subtract(const Duration(days: 240));
      final recentSession = buildSession(
        startsAt: recentStart,
        endsAt: recentStart.add(const Duration(minutes: 30)),
        isClosed: true,
      ).copyWith(id: 'recent-session');
      final oldSession = buildSession(
        startsAt: oldStart,
        endsAt: oldStart.add(const Duration(minutes: 30)),
        isClosed: true,
      ).copyWith(id: 'old-session');
      await seedSession(recentSession);
      await seedSession(oldSession);

      await firestore
          .collection(FirestoreCollections.classes)
          .doc('team-1')
          .collection(FirestoreCollections.attendanceSessions)
          .doc(recentSession.id)
          .collection(FirestoreCollections.attendanceMarks)
          .doc('student-1')
          .set({
            'studentNameSnapshot': 'Mina',
            'status': 'present',
            'markedByUserId': servant.uid,
            'markedByName': servant.name,
            'markedAt': recentStart,
            'updatedAt': recentStart,
          });
      await firestore
          .collection(FirestoreCollections.classes)
          .doc('team-1')
          .collection(FirestoreCollections.attendanceSessions)
          .doc(oldSession.id)
          .collection(FirestoreCollections.attendanceMarks)
          .doc('student-1')
          .set({
            'studentNameSnapshot': 'Mina',
            'status': 'present',
            'markedByUserId': servant.uid,
            'markedByName': servant.name,
            'markedAt': oldStart,
            'updatedAt': oldStart,
          });

      final stats = await repository.getStudentAttendanceStats(
        studentId: 'student-1',
      );

      expect(stats.totalSessions, 1);
    },
  );

  test(
    'getTeamAttendanceStats ignores sessions older than default window',
    () async {
      await seedStudent(student(id: 'student-1', name: 'Mina'));
      final recentStart = currentTime.subtract(const Duration(days: 5));
      final oldStart = currentTime.subtract(const Duration(days: 260));
      final recentSession = buildSession(
        startsAt: recentStart,
        endsAt: recentStart.add(const Duration(minutes: 30)),
        isClosed: true,
      ).copyWith(id: 'recent-team-session');
      final oldSession = buildSession(
        startsAt: oldStart,
        endsAt: oldStart.add(const Duration(minutes: 30)),
        isClosed: true,
      ).copyWith(id: 'old-team-session');
      await seedSession(recentSession);
      await seedSession(oldSession);

      await firestore
          .collection(FirestoreCollections.classes)
          .doc('team-1')
          .collection(FirestoreCollections.attendanceSessions)
          .doc(recentSession.id)
          .collection(FirestoreCollections.attendanceMarks)
          .doc('student-1')
          .set({
            'studentNameSnapshot': 'Mina',
            'status': 'late',
            'markedByUserId': servant.uid,
            'markedByName': servant.name,
            'markedAt': recentStart,
            'updatedAt': recentStart,
          });
      await firestore
          .collection(FirestoreCollections.classes)
          .doc('team-1')
          .collection(FirestoreCollections.attendanceSessions)
          .doc(oldSession.id)
          .collection(FirestoreCollections.attendanceMarks)
          .doc('student-1')
          .set({
            'studentNameSnapshot': 'Mina',
            'status': 'present',
            'markedByUserId': servant.uid,
            'markedByName': servant.name,
            'markedAt': oldStart,
            'updatedAt': oldStart,
          });

      final stats = await repository.getTeamAttendanceStats(teamId: 'team-1');

      expect(stats.totalSessions, 1);
      expect(stats.lateCount, 1);
    },
  );
}
