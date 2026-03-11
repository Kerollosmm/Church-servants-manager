import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_taking_screen.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;

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

  AttendanceSession buildSession() {
    return AttendanceSession(
      id: 'session-1',
      teamId: 'team-1',
      teamNameSnapshot: 'Team A',
      title: 'Wednesday',
      dateKey: '2026-03-09',
      startsAt: DateTime(2026, 3, 9, 18, 0),
      endsAt: DateTime(2026, 3, 9, 18, 30),
      durationMinutes: 30,
      createdByUserId: admin.uid,
      createdByName: admin.name,
      createdAt: DateTime(2026, 3, 9, 18, 0),
      updatedAt: DateTime(2026, 3, 10, 10, 0),
      isClosed: true,
      isReopenedForAdminEdit: true,
      reopenedAt: DateTime(2026, 3, 10, 10, 0),
      reopenedByUserId: admin.uid,
      reopenedByName: admin.name,
      studentIdsSnapshot: const ['student-1'],
      studentNameSnapshots: const {'student-1': 'Mina'},
    );
  }

  AttendanceRosterItem buildMarkedItem() {
    return AttendanceRosterItem(
      studentId: 'student-1',
      studentName: 'Mina',
      teamId: 'team-1',
      sessionId: 'session-1',
      manualStatus: AttendanceMarkStatus.present,
      effectiveStatus: AttendanceEffectiveStatus.present,
      isMarked: true,
      markedByName: 'Servant',
      note: 'Exception approved',
      isSessionOpen: false,
      canEdit: true,
      sortOrder: 0,
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required AuthUser actor,
  }) async {
    when(
      () => repository.watchSessionRosterSnapshot(
        teamId: 'team-1',
        sessionId: 'session-1',
      ),
    ).thenAnswer(
      (_) => Stream.value(
        AttendanceRosterSnapshot(
          session: buildSession(),
          roster: [buildMarkedItem()],
        ),
      ),
    );

    await tester.pumpWidget(
      RepositoryProvider<IAttendanceRepository>.value(
        value: repository,
        child: MaterialApp(
          home: AttendanceTakingScreen(
            args: AttendanceTakingArgs(
              actor: actor,
              teamId: 'team-1',
              sessionId: 'session-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = MockAttendanceRepository();
  });

  testWidgets('admin sees correction controls and note editing', (tester) async {
    await pumpScreen(tester, actor: admin);

    expect(find.text('Edit note'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(
      find.text(
        'Admin correction mode is active. You can update marks and notes for exceptions.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('servant sees reopened session as read-only', (tester) async {
    await pumpScreen(tester, actor: servant);

    expect(find.text('Edit note'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Present'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(
      find.text(
        'This session was reopened for admin correction. Servants can view it, but cannot edit it.',
      ),
      findsOneWidget,
    );
  });
}
