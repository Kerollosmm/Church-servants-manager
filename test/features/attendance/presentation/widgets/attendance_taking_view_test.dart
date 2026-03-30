import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_taking_view.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;
  late AttendanceTakingCubit cubit;
  late AttendanceSessionAdminCubit adminCubit;
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
    teamNameSnapshot: 'فريق 1',
    title: 'اجتماع الجمعة',
    dateKey: '2026-03-28',
    startsAt: DateTime(2026, 3, 28, 10),
    endsAt: DateTime(2026, 3, 28, 11),
    durationMinutes: 60,
    createdByUserId: 'admin-1',
    createdByName: 'Admin',
    createdAt: DateTime(2026, 3, 28, 9),
    updatedAt: DateTime(2026, 3, 28, 9),
    studentIdsSnapshot: const ['student-1'],
    studentNameSnapshots: const {'student-1': 'Mina'},
  );

  final rosterItem = AttendanceRosterItem(
    studentId: 'student-1',
    studentName: 'Mina',
    teamId: 'team-1',
    sessionId: 'session-1',
    effectiveStatus: AttendanceEffectiveStatus.unmarked,
    isMarked: false,
    isSessionOpen: true,
    canEdit: true,
    sortOrder: 0,
  );

  setUp(() {
    repository = MockAttendanceRepository();
    controller = StreamController<AttendanceRosterSnapshot>.broadcast();
    cubit = AttendanceTakingCubit(repository: repository);
    adminCubit = AttendanceSessionAdminCubit(repository: repository);

    when(
      () => repository.watchSessionRosterSnapshot(
        teamId: 'team-1',
        sessionId: 'session-1',
      ),
    ).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await cubit.close();
    await adminCubit.close();
    await controller.close();
  });

  testWidgets('renders roster and bulk action for loaded session', (
    tester,
  ) async {
    cubit.initialize(teamId: 'team-1', sessionId: 'session-1');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AttendanceTakingCubit>.value(value: cubit),
          BlocProvider<AttendanceSessionAdminCubit>.value(value: adminCubit),
        ],
        child: const MaterialApp(
          home: AttendanceTakingView(
            args: AttendanceTakingArgs(
              actor: actor,
              teamId: 'team-1',
              sessionId: 'session-1',
            ),
          ),
        ),
      ),
    );

    controller.add(
      AttendanceRosterSnapshot(session: session, roster: [rosterItem]),
    );
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الحضور'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('تحديد الباقي حاضر'), findsOneWidget);
  });
}
