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
  late StreamController<AttendanceRosterSnapshot> rosterController;
  late StreamController<SessionStatus> statusController;

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
      startsAt: DateTime(2026, 3, 9, 18),
      endsAt: isClosed
          ? DateTime(2026, 3, 9, 18)
          : DateTime(2026, 3, 9, 18, 30),
      durationMinutes: 30,
      createdByUserId: 'admin-1',
      createdByName: 'Admin',
      createdAt: DateTime(2026, 3, 9, 18),
      updatedAt: DateTime(2026, 3, 9, 18),
      isClosed: isClosed,
      studentIdsSnapshot: const ['student-1', 'student-2'],
      studentNameSnapshots: const {'student-1': 'Mina', 'student-2': 'Peter'},
    );
  }

  AttendanceRosterItem buildRosterItem({
    required AttendanceSession session,
    required String studentId,
    required String studentName,
    required AttendanceEffectiveStatus status,
  }) {
    return AttendanceRosterItem(
      studentId: studentId,
      studentName: studentName,
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
    rosterController = StreamController<AttendanceRosterSnapshot>.broadcast();
    statusController = StreamController<SessionStatus>.broadcast();
    when(
      () => repository.watchSessionRosterSnapshot(
        teamId: 'team-1',
        sessionId: 'session-1',
      ),
    ).thenAnswer((_) => rosterController.stream);
    when(
      () => repository.watchSessionStatus(
        teamId: 'team-1',
        sessionId: 'session-1',
      ),
    ).thenAnswer((_) => statusController.stream);
  });

  tearDown(() async {
    await rosterController.close();
    await statusController.close();
  });

  group('initialization', () {
    test('emits Loading then Loaded on initialize', () async {
      final cubit = AttendanceTakingCubit(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AttendanceTakingLoading>(),
          isA<AttendanceTakingLoaded>(),
        ]),
      );

      cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
      statusController.add(SessionStatus.open);
      rosterController.add(
        AttendanceRosterSnapshot(
          session: buildSession(isClosed: false),
          roster: [
            buildRosterItem(
              session: buildSession(isClosed: false),
              studentId: 'student-1',
              studentName: 'Mina',
              status: AttendanceEffectiveStatus.unmarked,
            ),
          ],
        ),
      );

      await expectation;
      await cubit.close();
    });
  });

  group('markPresent', () {
    test('calls repository when student is unmarked', () async {
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
      statusController.add(SessionStatus.open);
      rosterController.add(
        AttendanceRosterSnapshot(
          session: openSession,
          roster: [
            buildRosterItem(
              session: openSession,
              studentId: 'student-1',
              studentName: 'Mina',
              status: AttendanceEffectiveStatus.unmarked,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await cubit.markPresent(
        actor: servant,
        item: buildRosterItem(
          session: openSession,
          studentId: 'student-1',
          studentName: 'Mina',
          status: AttendanceEffectiveStatus.unmarked,
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
    });

    test(
      'duplicate mark (same status) does NOT call repository — idempotency',
      () async {
        final openSession = buildSession(isClosed: false);

        final cubit = AttendanceTakingCubit(
          repository: repository,
          nowProvider: () => DateTime(2026, 3, 9, 18, 10),
        );
        cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
        statusController.add(SessionStatus.open);
        rosterController.add(
          AttendanceRosterSnapshot(
            session: openSession,
            roster: [
              buildRosterItem(
                session: openSession,
                studentId: 'student-1',
                studentName: 'Mina',
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
            studentId: 'student-1',
            studentName: 'Mina',
            status: AttendanceEffectiveStatus.present,
          ),
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

    test('on closed session emits error and skips repository', () async {
      final closedSession = buildSession(isClosed: true);

      final cubit = AttendanceTakingCubit(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );
      cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
      statusController.add(SessionStatus.closed);
      rosterController.add(
        AttendanceRosterSnapshot(
          session: closedSession,
          roster: [
            buildRosterItem(
              session: closedSession,
              studentId: 'student-1',
              studentName: 'Mina',
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
          studentId: 'student-1',
          studentName: 'Mina',
          status: AttendanceEffectiveStatus.absent,
        ),
      );

      expect(cubit.state, isA<AttendanceTakingLoaded>());
      expect((cubit.state as AttendanceTakingLoaded).errorMessage, isNotEmpty);
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
  });

  group('session status stream', () {
    test(
      'session closed event disables marking (isSessionOpen: false)',
      () async {
        final openSession = buildSession(isClosed: false);

        final cubit = AttendanceTakingCubit(
          repository: repository,
          nowProvider: () => DateTime(2026, 3, 9, 18, 10),
        );
        cubit.initialize(teamId: 'team-1', sessionId: 'session-1');

        // Start as open.
        statusController.add(SessionStatus.open);
        rosterController.add(
          AttendanceRosterSnapshot(
            session: openSession,
            roster: [
              buildRosterItem(
                session: openSession,
                studentId: 'student-1',
                studentName: 'Mina',
                status: AttendanceEffectiveStatus.unmarked,
              ),
            ],
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect((cubit.state as AttendanceTakingLoaded).isSessionOpen, isTrue);

        // Flip to closed.
        statusController.add(SessionStatus.closed);
        await Future<void>.delayed(Duration.zero);

        expect((cubit.state as AttendanceTakingLoaded).isSessionOpen, isFalse);
        await cubit.close();
      },
    );
  });

  group('watchSessionMarks stream update', () {
    test('triggers state rebuild with updated marksMap', () async {
      final openSession = buildSession(isClosed: false);

      final cubit = AttendanceTakingCubit(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );
      cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
      statusController.add(SessionStatus.open);

      // Initial unmarked state.
      rosterController.add(
        AttendanceRosterSnapshot(
          session: openSession,
          roster: [
            buildRosterItem(
              session: openSession,
              studentId: 'student-1',
              studentName: 'Mina',
              status: AttendanceEffectiveStatus.unmarked,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect((cubit.state as AttendanceTakingLoaded).marksMap, isEmpty);

      // Update with a present mark.
      rosterController.add(
        AttendanceRosterSnapshot(
          session: openSession,
          roster: [
            buildRosterItem(
              session: openSession,
              studentId: 'student-1',
              studentName: 'Mina',
              status: AttendanceEffectiveStatus.present,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = cubit.state as AttendanceTakingLoaded;
      expect(state.marksMap['student-1'], AttendanceMarkStatus.present);
      await cubit.close();
    });
  });

  group('unmarkedCount', () {
    test('returns correct count of unmarked students', () async {
      final openSession = buildSession(isClosed: false);

      final cubit = AttendanceTakingCubit(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );
      cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
      statusController.add(SessionStatus.open);
      rosterController.add(
        AttendanceRosterSnapshot(
          session: openSession,
          roster: [
            buildRosterItem(
              session: openSession,
              studentId: 'student-1',
              studentName: 'Mina',
              status: AttendanceEffectiveStatus.present,
            ),
            buildRosterItem(
              session: openSession,
              studentId: 'student-2',
              studentName: 'Peter',
              status: AttendanceEffectiveStatus.unmarked,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.unmarkedCount, 1);
      await cubit.close();
    });
  });
}
