import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_bloc.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_event.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class MockAttendanceLocalDatasource extends Mock
    implements AttendanceLocalDatasource {}

class AuthUserFake extends Fake implements AuthUser {}

void main() {
  late MockAttendanceRepository repository;
  late MockAttendanceLocalDatasource localDatasource;

  setUpAll(() {
    registerFallbackValue(AuthUserFake());
  });

  setUp(() {
    repository = MockAttendanceRepository();
    localDatasource = MockAttendanceLocalDatasource();
    when(
      () => localDatasource.cacheMark(
        teamId: any(named: 'teamId'),
        sessionId: any(named: 'sessionId'),
        studentId: any(named: 'studentId'),
        markData: any(named: 'markData'),
      ),
    ).thenAnswer((_) async {});
    when(() => localDatasource.clearCache()).thenAnswer((_) async {});

    final getIt = GetIt.instance;
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<AttendanceLocalDatasource>(
      () => localDatasource,
    );
  });

  final servant = const AuthUser(
    uid: 'servant-1',
    email: 'servant@example.com',
    name: 'Servant',
    role: UserRole.servant,
    isEmailVerified: true,
    assignedTeamIds: ['team-1'],
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
    when(
      () => repository.getSessionRosterSnapshot(
        teamId: any(named: 'teamId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        AttendanceRosterSnapshot(
          session: buildSession(isClosed: false),
          roster: [],
        ),
      ),
    );
    when(
      () => repository.getSessionStatus(
        teamId: any(named: 'teamId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) => Future.value(SessionStatus.open));
    when(
      () => repository.canUserManageAttendance(
        user: any(named: 'user'),
        teamId: any(named: 'teamId'),
      ),
    ).thenAnswer((_) async => true);
  });

  tearDown(() async {});

  group('initialization', () {
    test('emits Loading then Loaded on initialize', () async {
      final bloc = AttendanceTakingBloc(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AttendanceTakingLoading>(),
          isA<AttendanceTakingLoaded>(),
        ]),
      );

      when(
        () => repository.getSessionStatus(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => SessionStatus.open);
      when(
        () => repository.getSessionRosterSnapshot(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => AttendanceRosterSnapshot(
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
      bloc.add(
        const InitializeSessionEvent(teamId: 'team-1', sessionId: 'session-1'),
      );

      await expectation;
      await bloc.close();
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

      final bloc = AttendanceTakingBloc(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );
      when(
        () => repository.getSessionStatus(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => SessionStatus.open);
      when(
        () => repository.getSessionRosterSnapshot(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => AttendanceRosterSnapshot(
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
      bloc.add(
        const InitializeSessionEvent(teamId: 'team-1', sessionId: 'session-1'),
      );
      await Future<void>.delayed(Duration.zero);

      bloc.add(
        MarkStudentPresentEvent(
          actor: servant,
          item: buildRosterItem(
            session: openSession,
            studentId: 'student-1',
            studentName: 'Mina',
            status: AttendanceEffectiveStatus.unmarked,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      bloc.add(SubmitSessionEvent(actor: servant));
      await Future<void>.delayed(Duration.zero);

      verify(
        () => repository.batchWriteMarks(
          teamId: 'team-1',
          sessionId: 'session-1',
          marks: {'student-1': AttendanceMarkStatus.present},
          markedBy: servant,
          cachedPermission: any(named: 'cachedPermission'),
        ),
      ).called(1);
      await bloc.close();
    });

    test(
      'duplicate mark (same status) does NOT update local state or call repository',
      () async {
        final openSession = buildSession(isClosed: false);

        final bloc = AttendanceTakingBloc(
          repository: repository,
          nowProvider: () => DateTime(2026, 3, 9, 18, 10),
        );
        when(
          () => repository.getSessionStatus(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer((_) async => SessionStatus.open);
        when(
          () => repository.getSessionRosterSnapshot(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer(
          (_) async => AttendanceRosterSnapshot(
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
        bloc.add(
          const InitializeSessionEvent(
            teamId: 'team-1',
            sessionId: 'session-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        bloc.add(
          MarkStudentPresentEvent(
            actor: servant,
            item: buildRosterItem(
              session: openSession,
              studentId: 'student-1',
              studentName: 'Mina',
              status: AttendanceEffectiveStatus.present,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          (bloc.state as AttendanceTakingLoaded).pendingLocalMarks.isEmpty,
          isTrue,
        );

        bloc.add(SubmitSessionEvent(actor: servant));
        await Future<void>.delayed(Duration.zero);

        verifyNever(
          () => repository.batchWriteMarks(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
            marks: any(named: 'marks'),
            markedBy: any(named: 'markedBy'),
          ),
        );
        await bloc.close();
      },
    );

    test('on closed session emits error and skips repository', () async {
      final closedSession = buildSession(isClosed: true);

      final bloc = AttendanceTakingBloc(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );
      when(
        () => repository.getSessionStatus(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => SessionStatus.closed);
      when(
        () => repository.getSessionRosterSnapshot(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => AttendanceRosterSnapshot(
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
      bloc.add(
        const InitializeSessionEvent(teamId: 'team-1', sessionId: 'session-1'),
      );
      await Future<void>.delayed(Duration.zero);

      bloc.add(
        MarkStudentPresentEvent(
          actor: servant,
          item: buildRosterItem(
            session: closedSession,
            studentId: 'student-1',
            studentName: 'Mina',
            status: AttendanceEffectiveStatus.absent,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<AttendanceTakingLoaded>());
      expect((bloc.state as AttendanceTakingLoaded).errorMessage, isNotEmpty);
      verifyNever(
        () => repository.markStudentPresent(
          teamId: 'team-1',
          sessionId: 'session-1',
          studentId: 'student-1',
          studentNameSnapshot: 'Mina',
          markedBy: servant,
        ),
      );
      await bloc.close();
    });
  });

  group('session status refresh', () {
    test(
      'session closed event disables marking (isSessionOpen: false)',
      () async {
        final openSession = buildSession(isClosed: false);

        final bloc = AttendanceTakingBloc(
          repository: repository,
          nowProvider: () => DateTime(2026, 3, 9, 18, 10),
        );
        when(
          () => repository.getSessionStatus(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer((_) async => SessionStatus.open);
        when(
          () => repository.getSessionRosterSnapshot(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer(
          (_) async => AttendanceRosterSnapshot(
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
        bloc.add(
          const InitializeSessionEvent(
            teamId: 'team-1',
            sessionId: 'session-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect((bloc.state as AttendanceTakingLoaded).isSessionOpen, isTrue);

        // Flip to closed.
        when(
          () => repository.getSessionStatus(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer((_) async => SessionStatus.closed);
        bloc.add(
          const RefreshSessionEvent(teamId: 'team-1', sessionId: 'session-1'),
        );
        await Future<void>.delayed(Duration.zero);

        expect((bloc.state as AttendanceTakingLoaded).isSessionOpen, isFalse);
        await bloc.close();
      },
    );
  });

  group('refresh update', () {
    test('triggers state rebuild with updated marksMap', () async {
      final openSession = buildSession(isClosed: false);

      final bloc = AttendanceTakingBloc(
        repository: repository,
        nowProvider: () => DateTime(2026, 3, 9, 18, 10),
      );
      when(
        () => repository.getSessionStatus(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => SessionStatus.open);
      when(
        () => repository.getSessionRosterSnapshot(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => AttendanceRosterSnapshot(
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

      bloc.add(
        const InitializeSessionEvent(teamId: 'team-1', sessionId: 'session-1'),
      );
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as AttendanceTakingLoaded).marksMap, isEmpty);

      // Update with a present mark.
      when(
        () => repository.getSessionRosterSnapshot(
          teamId: any(named: 'teamId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async => AttendanceRosterSnapshot(
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
      bloc.add(
        const RefreshSessionEvent(teamId: 'team-1', sessionId: 'session-1'),
      );
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state as AttendanceTakingLoaded;
      expect(state.marksMap['student-1'], AttendanceMarkStatus.present);
      await bloc.close();
    });
  });
}
