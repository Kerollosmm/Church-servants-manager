import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
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
    await firestore.collection('attendance').doc(value.id).set(value.toMap());
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    clockController = StreamController<DateTime>.broadcast();
    currentTime = DateTime(2026, 3, 9, 18);
    await firestore.collection('Classes').doc('team-1').set({
      'name': 'Team A',
      'groupId': 'year1',
      'isArchived': false,
    });
    repository = AttendanceRepository(
      firestore: firestore,
      nowProvider: () => currentTime,
    );
  });

  tearDown(() async {
    await clockController.close();
  });

  test(
    'createSession writes to the top-level attendance collection with frozen roster',
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
          .collection('attendance')
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
    'markStudentPresent uses studentId_sessionId as document id and remains idempotent',
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
      await repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );

      final marks = await firestore
          .collection('attendance')
          .doc(session.id)
          .collection('marks')
          .get();

      expect(marks.docs.length, 1);
      expect(marks.docs.single.id, 'student-1_${session.id}');
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

    await expectLater(
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
    final presentRoster = await repository.getSessionRoster(
      teamId: 'team-1',
      sessionId: session.id,
    );
    expect(
      presentRoster.single.effectiveStatus,
      AttendanceEffectiveStatus.present,
    );

    await firestore
        .collection('attendance')
        .doc(session.id)
        .collection('marks')
        .doc('student-1_${session.id}')
        .set({
          'studentId': 'student-1',
          'studentNameSnapshot': 'Mina',
          'status': 'late',
          'markedByUserId': servant.uid,
          'markedByName': servant.name,
          'markedAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });

    final lateRoster = await repository.getSessionRoster(
      teamId: 'team-1',
      sessionId: session.id,
    );
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

  group('closeSession', () {
    test('auto-marks absent students not in marks subcollection', () async {
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

      // Mark only student-1.
      await repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: session.id,
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      );

      // Close session — should auto-mark student-2.
      await repository.closeSession(
        teamId: 'team-1',
        sessionId: session.id,
        closedBy: admin,
      );

      // Verify session is closed.
      final sessionDoc = await firestore
          .collection('attendance')
          .doc(session.id)
          .get();
      expect(sessionDoc.data()!['isClosed'], isTrue);

      // Verify both students have marks.
      final marks = await firestore
          .collection('attendance')
          .doc(session.id)
          .collection('marks')
          .get();
      expect(marks.docs.length, 2);
      final markedStudentIds = marks.docs
          .map((d) => d.id.split('_').first)
          .toSet();
      expect(markedStudentIds.contains('student-1'), isTrue);
      expect(markedStudentIds.contains('student-2'), isTrue);
    });
  });
}
