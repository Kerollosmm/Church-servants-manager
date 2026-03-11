import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;
  late StreamController<AttendanceRosterSnapshot> controller;

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

  AttendanceSession buildSession({
    required bool isClosed,
    bool reopenedForAdminEdit = false,
  }) {
    return AttendanceSession(
      id: 'session-1',
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      title: 'Wednesday',
      dateKey: '2026-03-09',
      startsAt: DateTime(2026, 3, 9, 18, 0),
      endsAt: isClosed
          ? DateTime(2026, 3, 9, 18, 0)
          : DateTime(2026, 3, 9, 18, 30),
      durationMinutes: 30,
      createdByUserId: 'admin-1',
      createdByName: 'Admin',
      createdAt: DateTime(2026, 3, 9, 18, 0),
      updatedAt: DateTime(2026, 3, 9, 18, 0),
      isClosed: isClosed,
      isReopenedForAdminEdit: reopenedForAdminEdit,
      reopenedAt: reopenedForAdminEdit ? DateTime(2026, 3, 10, 10, 0) : null,
      reopenedByUserId: reopenedForAdminEdit ? admin.uid : null,
      reopenedByName: reopenedForAdminEdit ? admin.name : null,
      studentIdsSnapshot: const ['student-1'],
      studentNameSnapshots: const {'student-1': 'Mina'},
    );
  }

  AttendanceRosterItem buildRosterItem({
    required AttendanceSession session,
    required AttendanceEffectiveStatus status,
    String? note,
  }) {
    return AttendanceRosterItem(
      studentId: 'student-1',
      studentName: 'Mina',
      teamId: session.teamId,
      sessionId: session.id,
      manualStatus: status == AttendanceEffectiveStatus.late
          ? AttendanceMarkStatus.late
          : status == AttendanceEffectiveStatus.present
          ? AttendanceMarkStatus.present
          : null,
      effectiveStatus: status,
      isMarked: status == AttendanceEffectiveStatus.present ||
          status == AttendanceEffectiveStatus.late,
      markedByName: status == AttendanceEffectiveStatus.unmarked ? null : 'Servant',
      note: note,
      isSessionOpen: !session.isClosed,
      canEdit: !session.isClosed || session.isReopenedForAdminEdit,
      sortOrder: 0,
    );
  }

  setUp(() {
    repository = MockAttendanceRepository();
    controller = StreamController<AttendanceRosterSnapshot>.broadcast();
    when(
      () => repository.watchSessionRosterSnapshot(
        teamId: 'team-1',
        sessionId: 'session-1',
      ),
    ).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  test('initialize listens to repository snapshot stream', () async {
    final cubit = AttendanceTakingCubit(
      repository: repository,
      nowProvider: () => DateTime(2026, 3, 9, 18, 10),
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AttendanceTakingLoading>(),
        isA<AttendanceTakingLoaded>().having(
          (state) => state.roster.single.studentName,
          'student name',
          'Mina',
        ),
      ]),
    );

    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(
      AttendanceRosterSnapshot(
        session: buildSession(isClosed: false),
        roster: [
          buildRosterItem(
            session: buildSession(isClosed: false),
            status: AttendanceEffectiveStatus.unmarked,
          ),
        ],
      ),
    );

    await expectation;
    await cubit.close();
  });

  test('markPresent on closed session emits mutation error and skips repository', () async {
    final closedSession = buildSession(isClosed: true);
    final cubit = AttendanceTakingCubit(
      repository: repository,
      nowProvider: () => DateTime(2026, 3, 9, 18, 10),
    );
    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(
      AttendanceRosterSnapshot(
        session: closedSession,
        roster: [
          buildRosterItem(
            session: closedSession,
            status: AttendanceEffectiveStatus.absent,
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await cubit.markPresent(
      actor: servant,
      item: buildRosterItem(
        session: closedSession,
        status: AttendanceEffectiveStatus.absent,
      ),
    );

    expect(cubit.state, isA<AttendanceTakingLoaded>());
    expect(
      (cubit.state as AttendanceTakingLoaded).mutationError,
      'This attendance session is read-only right now.',
    );
    verifyNever(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      ),
    );
    await cubit.close();
  });

  test('admin can mutate a reopened closed session', () async {
    final reopenedSession = buildSession(
      isClosed: true,
      reopenedForAdminEdit: true,
    );
    when(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: admin,
      ),
    ).thenAnswer((_) async {});

    final cubit = AttendanceTakingCubit(
      repository: repository,
      nowProvider: () => DateTime(2026, 3, 10, 10, 5),
    );
    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(
      AttendanceRosterSnapshot(
        session: reopenedSession,
        roster: [
          buildRosterItem(
            session: reopenedSession,
            status: AttendanceEffectiveStatus.absent,
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await cubit.markPresent(
      actor: admin,
      item: buildRosterItem(
        session: reopenedSession,
        status: AttendanceEffectiveStatus.absent,
      ),
    );

    verify(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: admin,
      ),
    ).called(1);
    await cubit.close();
  });

  test('servant cannot mutate a reopened closed session', () async {
    final reopenedSession = buildSession(
      isClosed: true,
      reopenedForAdminEdit: true,
    );
    final cubit = AttendanceTakingCubit(
      repository: repository,
      nowProvider: () => DateTime(2026, 3, 10, 10, 5),
    );
    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(
      AttendanceRosterSnapshot(
        session: reopenedSession,
        roster: [
          buildRosterItem(
            session: reopenedSession,
            status: AttendanceEffectiveStatus.absent,
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await cubit.markPresent(
      actor: servant,
      item: buildRosterItem(
        session: reopenedSession,
        status: AttendanceEffectiveStatus.absent,
      ),
    );

    expect(
      (cubit.state as AttendanceTakingLoaded).mutationError,
      'This attendance session is read-only right now.',
    );
    verifyNever(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      ),
    );
    await cubit.close();
  });

  test('updateMarkNote delegates to repository when session is editable', () async {
    final openSession = buildSession(isClosed: false);
    when(
      () => repository.updateStudentMarkNote(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        requestedBy: servant,
        note: 'Needs follow-up',
      ),
    ).thenAnswer((_) async {});

    final cubit = AttendanceTakingCubit(
      repository: repository,
      nowProvider: () => DateTime(2026, 3, 9, 18, 10),
    );
    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(
      AttendanceRosterSnapshot(
        session: openSession,
        roster: [
          buildRosterItem(
            session: openSession,
            status: AttendanceEffectiveStatus.present,
            note: 'Old note',
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    await cubit.updateMarkNote(
      actor: servant,
      item: buildRosterItem(
        session: openSession,
        status: AttendanceEffectiveStatus.present,
        note: 'Old note',
      ),
      note: 'Needs follow-up',
    );

    verify(
      () => repository.updateStudentMarkNote(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        requestedBy: servant,
        note: 'Needs follow-up',
      ),
    ).called(1);
    await cubit.close();
  });

  test('stream snapshots preserve isMutating while a write is in flight', () async {
    final openSession = buildSession(isClosed: false);
    final saveCompleter = Completer<void>();
    when(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: servant,
      ),
    ).thenAnswer((_) => saveCompleter.future);

    final cubit = AttendanceTakingCubit(
      repository: repository,
      nowProvider: () => DateTime(2026, 3, 9, 18, 10),
    );
    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(
      AttendanceRosterSnapshot(
        session: openSession,
        roster: [
          buildRosterItem(
            session: openSession,
            status: AttendanceEffectiveStatus.unmarked,
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state, isA<AttendanceTakingLoaded>());

    unawaited(
      cubit.markPresent(
        actor: servant,
        item: buildRosterItem(
          session: openSession,
          status: AttendanceEffectiveStatus.unmarked,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect((cubit.state as AttendanceTakingLoaded).isMutating, isTrue);

    controller.add(
      AttendanceRosterSnapshot(
        session: openSession,
        roster: [
          buildRosterItem(
            session: openSession,
            status: AttendanceEffectiveStatus.present,
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect((cubit.state as AttendanceTakingLoaded).isMutating, isTrue);

    saveCompleter.complete();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect((cubit.state as AttendanceTakingLoaded).isMutating, isFalse);
    await cubit.close();
  });
}
