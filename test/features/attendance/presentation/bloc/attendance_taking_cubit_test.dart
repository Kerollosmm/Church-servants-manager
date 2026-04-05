import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;
  late StreamController<AttendanceRosterSnapshot> controller;

  final servant = const AuthUser(
    uid: 'servant-1',
    email: 'servant@example.com',
    name: 'Servant',
    role: UserRole.servant,
    isEmailVerified: true,
    assignedTeamIds: ['team-1'],
    assignedTeamId: 'team-1',
  );

  AttendanceSession buildSession({required bool isClosed}) {
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
      studentIdsSnapshot: const ['student-1'],
      studentNameSnapshots: const {'student-1': 'Mina'},
    );
  }

  AttendanceRosterItem buildRosterItem({
    required AttendanceSession session,
    required AttendanceEffectiveStatus status,
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
      isMarked:
          status == AttendanceEffectiveStatus.present ||
          status == AttendanceEffectiveStatus.late,
      isSessionOpen: !session.isClosed,
      canEdit: !session.isClosed,
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

  test(
    'markPresent on closed session emits mutation error and skips repository',
    () async {
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
        'انتهى وقت تسجيل الحضور لهذه الجلسة.',
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
    },
  );

  test(
    'stream snapshots preserve isMutating while a write is in flight',
    () async {
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
      await Future<void>.delayed(Duration.zero);
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
      await Future<void>.delayed(Duration.zero);

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
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as AttendanceTakingLoaded).isMutating, isTrue);

      saveCompleter.complete();
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as AttendanceTakingLoaded).isMutating, isFalse);
      await cubit.close();
    },
  );

  test(
    'markPresent on already-present student calls markStudentPresent (toggle-off handled by repo)',
    () async {
      final openSession = buildSession(isClosed: false);
      when(
        () => repository.markStudentPresent(
          teamId: 'team-1',
          sessionId: 'session-1',
          studentId: 'student-1',
          studentNameSnapshot: 'Mina',
          markedBy: servant,
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
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await cubit.markPresent(
        actor: servant,
        item: buildRosterItem(
          session: openSession,
          status: AttendanceEffectiveStatus.present,
        ),
      );

      verify(
        () => repository.markStudentPresent(
          teamId: 'team-1',
          sessionId: 'session-1',
          studentId: 'student-1',
          studentNameSnapshot: 'Mina',
          markedBy: servant,
        ),
      ).called(1);
      await cubit.close();
    },
  );

  test(
    'markLate on present student calls markStudentLate (status change)',
    () async {
      final openSession = buildSession(isClosed: false);
      when(
        () => repository.markStudentLate(
          teamId: 'team-1',
          sessionId: 'session-1',
          studentId: 'student-1',
          studentNameSnapshot: 'Mina',
          markedBy: servant,
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
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await cubit.markLate(
        actor: servant,
        item: buildRosterItem(
          session: openSession,
          status: AttendanceEffectiveStatus.present,
        ),
      );

      verify(
        () => repository.markStudentLate(
          teamId: 'team-1',
          sessionId: 'session-1',
          studentId: 'student-1',
          studentNameSnapshot: 'Mina',
          markedBy: servant,
        ),
      ).called(1);
      await cubit.close();
    },
  );

  test(
    'clearMark on present student calls clearStudentMark (toggle-off)',
    () async {
      final openSession = buildSession(isClosed: false);
      when(
        () => repository.clearStudentMark(
          teamId: 'team-1',
          sessionId: 'session-1',
          studentId: 'student-1',
          requestedBy: servant,
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
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await cubit.clearMark(
        actor: servant,
        item: buildRosterItem(
          session: openSession,
          status: AttendanceEffectiveStatus.present,
        ),
      );

      verify(
        () => repository.clearStudentMark(
          teamId: 'team-1',
          sessionId: 'session-1',
          studentId: 'student-1',
          requestedBy: servant,
        ),
      ).called(1);
      await cubit.close();
    },
  );
}
