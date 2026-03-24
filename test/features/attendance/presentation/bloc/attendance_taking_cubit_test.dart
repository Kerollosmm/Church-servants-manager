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
    },
  );

  // T010 [US3]: Verify that mutationError is preserved even when rapid server
  // snapshots arrive during the mutation window. Simulates the P1-C race condition. // FIX [P1-C]
  test(
    'mutationError is preserved on latest state when snapshot arrives during failed mutation',
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

      // Seed initial roster (unmarked)
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

      // Start mutation (will fail)
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

      // isMutating should be true while in-flight // FIX [P1-C]
      expect((cubit.state as AttendanceTakingLoaded).isMutating, isTrue);

      // Server emits a snapshot mid-mutation (roster now shows updated data)
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

      // isMutating still preserved through the snapshot emission // FIX [P1-C]
      expect((cubit.state as AttendanceTakingLoaded).isMutating, isTrue);

      // Complete with an error
      saveCompleter.completeError(Exception('Network error'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final finalState = cubit.state as AttendanceTakingLoaded;

      // FIX [P1-C]: mutationError must be applied to the LATEST roster (present),
      // not the pre-mutation snapshot (unmarked). Error must not be swallowed.
      expect(finalState.isMutating, isFalse);
      expect(finalState.mutationError, isNotNull);
      // Roster reflects the latest server snapshot (present), not the stale pre-mutation data
      expect(
        finalState.roster.single.effectiveStatus,
        AttendanceEffectiveStatus.present,
      );

      await cubit.close();
    },
  );

  // T010 [US3]: Verify that on successful mutation the latest roster is preserved
  // and mutationError is cleared, even when a snapshot arrived mid-mutation. // FIX [P1-C]
  test(
    'on successful mutation, latest roster data is preserved and mutationError is cleared',
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

      // Seed initial roster (unmarked)
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

      // Snapshot arrives mid-mutation with updated roster // FIX [P1-C]
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

      // Complete successfully
      saveCompleter.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final finalState = cubit.state as AttendanceTakingLoaded;

      // FIX [P1-C]: State snapshot applied to LATEST state — roster shows "present",
      // mutationError is null (cleared on success), isMutating is false.
      expect(finalState.isMutating, isFalse);
      expect(finalState.mutationError, isNull);
      expect(
        finalState.roster.single.effectiveStatus,
        AttendanceEffectiveStatus.present,
      );

      await cubit.close();
    },
  );
}
