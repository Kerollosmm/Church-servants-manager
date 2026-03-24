import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_taking_view.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  late MockAttendanceRepository repository;

  AuthUser actor() => const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  AttendanceRosterSnapshot snapshot(DateTime now) {
    final session = AttendanceSession(
      id: 'session-1',
      teamId: 'team-1',
      teamNameSnapshot: 'Team 1',
      title: 'جلسة خدمة',
      dateKey: '2026-03-24',
      startsAt: now.subtract(const Duration(minutes: 5)),
      endsAt: now.add(const Duration(seconds: 2)),
      durationMinutes: 30,
      createdByUserId: 'admin-1',
      createdByName: 'Admin',
      createdAt: now.subtract(const Duration(minutes: 6)),
      updatedAt: now,
      isClosed: false,
      studentIdsSnapshot: const <String>['student-1'],
      studentNameSnapshots: const <String, String>{'student-1': 'Student 1'},
    );

    return AttendanceRosterSnapshot(
      session: session,
      roster: <AttendanceRosterItem>[
        const AttendanceRosterItem(
          studentId: 'student-1',
          studentName: 'Student 1',
          teamId: 'team-1',
          sessionId: 'session-1',
          effectiveStatus: AttendanceEffectiveStatus.unmarked,
          isMarked: false,
          isSessionOpen: true,
          canEdit: true,
          sortOrder: 0,
        ),
      ],
    );
  }

  setUp(() {
    repository = MockAttendanceRepository();
  });

  testWidgets(
    'session expiry disables actions without waiting for roster updates',
    (tester) async {
      final now = DateTime.now();
      when(
        () => repository.watchSessionRosterSnapshot(
          teamId: 'team-1',
          sessionId: 'session-1',
        ),
      ).thenAnswer(
        (_) => Stream<AttendanceRosterSnapshot>.value(snapshot(now)),
      );

      await tester.pumpWidget(
        RepositoryProvider<IAttendanceRepository>.value(
          value: repository,
          child: MaterialApp(
            home: AttendanceTakingView(
              args: AttendanceTakingArgs(
                actor: actor(),
                teamId: 'team-1',
                sessionId: 'session-1',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byTooltip('تحديد الباقي حاضر'), findsOneWidget);
      expect(
        find.text('الجلسة مفتوحة الآن. يمكنك تحديد حاضر أو متأخر فقط.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'حاضر'))
            .onPressed,
        isNotNull,
      );

      await tester.pump(const Duration(seconds: 3));

      expect(find.byTooltip('تحديد الباقي حاضر'), findsNothing);
      expect(find.text('انتهت الجلسة'), findsOneWidget);
      expect(
        find.text('الجلسة مغلقة الآن. أي مخدوم غير محدد يظهر كغائب تلقائيا.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'حاضر'))
            .onPressed,
        isNull,
      );
    },
  );
}
