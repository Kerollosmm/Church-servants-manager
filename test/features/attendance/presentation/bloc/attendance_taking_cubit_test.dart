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
  late AttendanceTakingCubit cubit;
  late StreamController<AttendanceRosterSnapshot> controller;

  const actor = AuthUser(
    uid: 'servant-1',
    email: 'servant@test.com',
    name: 'Servant One',
    role: UserRole.servant,
  );

  final session = AttendanceSession(
    id: 'session-1',
    teamId: 'team-1',
    teamNameSnapshot: 'Team One',
    title: 'Weekly',
    dateKey: '2026-03-28',
    startsAt: DateTime(2026, 3, 28, 10),
    endsAt: DateTime(2026, 3, 28, 11),
    durationMinutes: 60,
    createdByUserId: 'servant-1',
    createdByName: 'Servant One',
    createdAt: DateTime(2026, 3, 28, 9, 30),
    updatedAt: DateTime(2026, 3, 28, 9, 30),
    studentIdsSnapshot: const ['student-1'],
    studentNameSnapshots: const {'student-1': 'Mina'},
  );

  final rosterItem = AttendanceRosterItem(
    studentId: 'student-1',
    studentName: 'Mina',
    teamId: 'team-1',
    sessionId: 'session-1',
    manualStatus: null,
    effectiveStatus: AttendanceEffectiveStatus.unmarked,
    isMarked: false,
    markedAt: null,
    markedByName: null,
    isSessionOpen: true,
    canEdit: true,
    sortOrder: 0,
  );

  AttendanceRosterSnapshot snapshot() =>
      AttendanceRosterSnapshot(session: session, roster: [rosterItem]);

  setUp(() {
    repository = MockAttendanceRepository();
    controller = StreamController<AttendanceRosterSnapshot>.broadcast();
    cubit = AttendanceTakingCubit(
      repository: repository,
      nowProvider: () => DateTime(2026, 3, 28, 10, 15),
    );

    when(
      () => repository.watchSessionRosterSnapshot(
        teamId: 'team-1',
        sessionId: 'session-1',
      ),
    ).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await cubit.close();
    await controller.close();
  });

  test('initialize streams roster snapshots into loaded state', () async {
    final states = <AttendanceTakingState>[];
    final subscription = cubit.stream.listen(states.add);

    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(snapshot());
    await Future<void>.delayed(Duration.zero);

    expect(states.first, const AttendanceTakingLoading());
    expect(cubit.state, isA<AttendanceTakingLoaded>());

    final loaded = cubit.state as AttendanceTakingLoaded;
    expect(loaded.session.id, 'session-1');
    expect(loaded.roster, [rosterItem]);

    await subscription.cancel();
  });

  test('markPresent calls repository with the expected arguments', () async {
    when(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: actor,
      ),
    ).thenAnswer((_) async {});

    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');
    controller.add(snapshot());
    await Future<void>.delayed(Duration.zero);

    final states = <AttendanceTakingState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.markPresent(actor: actor, item: rosterItem);

    verify(
      () => repository.markStudentPresent(
        teamId: 'team-1',
        sessionId: 'session-1',
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        markedBy: actor,
      ),
    ).called(1);

    expect(
      states.whereType<AttendanceTakingMarkInProgress>().single.studentId,
      'student-1',
    );

    await subscription.cancel();
  });
}
