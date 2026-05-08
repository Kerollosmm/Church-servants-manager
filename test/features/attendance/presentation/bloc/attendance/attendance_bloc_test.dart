import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance/attendance_bloc.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class MockSyncService extends Mock implements SyncService {}

class FakeSyncEntry extends Fake implements SyncEntry {}

class FakeAuthUser extends Fake implements AuthUser {}

void main() {
  late MockAttendanceRepository mockAttendanceRepository;
  late MockSyncService mockSyncService;
  late AttendanceBloc attendanceBloc;

  final tAuthUser = const AuthUser(
    uid: 'user_1',
    email: 'test@example.com',
    name: 'Test User',
    groupId: 'group_1',
    assignedTeamIds: ['team_1'],
    role: UserRole.servant,
  );

  final tSession = AttendanceSession(
    id: 'session_1',
    teamId: 'team_1',
    dateKey: '2023-10-10',
    startsAt: DateTime(2023, 10, 10, 10),
    endsAt: DateTime(2023, 10, 10, 12),
    durationMinutes: 120,
    createdByUserId: 'user_1',
    createdByName: 'Test User',
    createdAt: DateTime(2023, 10, 10),
    updatedAt: DateTime(2023, 10, 10),
    studentIdsSnapshot: const ['student_1'],
    studentNameSnapshots: const {'student_1': 'Student One'},
  );

  final tRosterItem = AttendanceRosterItem(
    studentId: 'student_1',
    studentName: 'Student One',
    teamId: 'team_1',
    sessionId: 'session_1',
    effectiveStatus: AttendanceEffectiveStatus.absent,
    isMarked: false,
    isSessionOpen: true,
    canEdit: true,
    sortOrder: 0,
  );

  final tRosterSnapshot = AttendanceRosterSnapshot(
    session: tSession,
    roster: [tRosterItem],
  );

  setUpAll(() {
    registerFallbackValue(FakeSyncEntry());
    registerFallbackValue(FakeAuthUser());
  });

  setUp(() {
    mockAttendanceRepository = MockAttendanceRepository();
    mockSyncService = MockSyncService();
    attendanceBloc = AttendanceBloc(
      attendanceRepository: mockAttendanceRepository,
      syncService: mockSyncService,
    );
  });

  tearDown(() {
    attendanceBloc.close();
  });

  group('StartSession', () {
    final tEvent = StartSession(
      teamId: 'team_1',
      teamNameSnapshot: 'Team One',
      startsAt: DateTime(2023, 10, 10, 10),
      durationMinutes: 120,
      createdBy: tAuthUser,
      studentIdsSnapshot: const ['student_1'],
      studentNameSnapshots: const {'student_1': 'Student One'},
      title: 'Test Session',
    );

    test(
      'emits [AttendanceLoading, AttendanceSessionActive] on success',
      () async {
        when(
          () => mockAttendanceRepository.createSession(
            teamId: any(named: 'teamId'),
            teamNameSnapshot: any(named: 'teamNameSnapshot'),
            startsAt: any(named: 'startsAt'),
            durationMinutes: any(named: 'durationMinutes'),
            createdBy: any(named: 'createdBy'),
            title: any(named: 'title'),
          ),
        ).thenAnswer((_) async => tSession);

        when(
          () => mockAttendanceRepository.getSessionRosterSnapshot(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer((_) async => tRosterSnapshot);

        final expectedStates = [
          const AttendanceLoading(),
          AttendanceSessionActive(
            session: tSession,
            roster: tRosterSnapshot.roster,
          ),
        ];

        expectLater(attendanceBloc.stream, emitsInOrder(expectedStates));

        attendanceBloc.add(tEvent);

        await Future.delayed(Duration.zero);

        verify(
          () => mockAttendanceRepository.createSession(
            teamId: tEvent.teamId,
            teamNameSnapshot: tEvent.teamNameSnapshot,
            startsAt: tEvent.startsAt,
            durationMinutes: tEvent.durationMinutes,
            createdBy: tEvent.createdBy,
            title: tEvent.title,
          ),
        ).called(1);
        verify(
          () => mockAttendanceRepository.getSessionRosterSnapshot(
            teamId: tSession.teamId,
            sessionId: tSession.id,
          ),
        ).called(1);
      },
    );

    test('emits [AttendanceLoading, AttendanceError] on failure', () async {
      when(
        () => mockAttendanceRepository.createSession(
          teamId: any(named: 'teamId'),
          teamNameSnapshot: any(named: 'teamNameSnapshot'),
          startsAt: any(named: 'startsAt'),
          durationMinutes: any(named: 'durationMinutes'),
          createdBy: any(named: 'createdBy'),
          title: any(named: 'title'),
        ),
      ).thenThrow(Exception('Failed'));

      final expectedStates = [
        const AttendanceLoading(),
        const AttendanceError(
          message: 'حدث خطأ أثناء إنشاء الجلسة: Exception: Failed',
        ),
      ];

      expectLater(attendanceBloc.stream, emitsInOrder(expectedStates));

      attendanceBloc.add(tEvent);
      await Future.delayed(Duration.zero);
    });
  });

  group('ToggleAttendance', () {
    test(
      'emits updated AttendanceSessionActive and enqueues sync entry',
      () async {
        when(() => mockSyncService.enqueue(any())).thenAnswer((_) async {});

        when(
          () => mockAttendanceRepository.getSessionById(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer((_) async => tSession);

        when(
          () => mockAttendanceRepository.getSessionRosterSnapshot(
            teamId: any(named: 'teamId'),
            sessionId: any(named: 'sessionId'),
          ),
        ).thenAnswer((_) async => tRosterSnapshot);

        attendanceBloc.add(
          const LoadSessionRoster(teamId: 'team_1', sessionId: 'session_1'),
        );

        // Wait for it to become Active
        await expectLater(
          attendanceBloc.stream,
          emitsThrough(isA<AttendanceSessionActive>()),
        );

        final expectedState = isA<AttendanceSessionActive>()
            .having(
              (state) => state.roster.first.manualStatus,
              'manualStatus',
              AttendanceMarkStatus.present,
            )
            .having((state) => state.roster.first.isMarked, 'isMarked', true);

        attendanceBloc.add(
          ToggleAttendance(
            studentId: 'student_1',
            newStatus: AttendanceMarkStatus.present,
            markedBy: tAuthUser,
          ),
        );

        await expectLater(attendanceBloc.stream, emits(expectedState));

        final captured = verify(
          () => mockSyncService.enqueue(captureAny()),
        ).captured;
        final syncEntry = captured.first as SyncEntry;

        expect(syncEntry.actionType, equals('MARK_ATTENDANCE'));
        expect(syncEntry.payload['studentId'], equals('student_1'));
        expect(syncEntry.payload['status'], equals('present'));
      },
    );
  });
}
