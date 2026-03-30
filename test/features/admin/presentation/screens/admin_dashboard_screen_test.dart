import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_audit_review_service.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;
  late AdminDashboardCubit cubit;

  const actor = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin',
    role: UserRole.admin,
  );

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthAuthenticated(actor));
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    cubit = AdminDashboardCubit.seeded(
      AdminDashboardState(
        totalStudents: 12,
        totalServants: 3,
        sessionsThisMonth: 4,
        recentSessions: [
          AttendanceSession(
            id: 'session-1',
            teamId: 'team-1',
            teamNameSnapshot: 'Team 1',
            title: 'Friday Meeting',
            dateKey: '2026-03-28',
            startsAt: DateTime(2026, 3, 28, 10),
            endsAt: DateTime(2026, 3, 28, 11),
            durationMinutes: 60,
            createdByUserId: 'admin-1',
            createdByName: 'Admin',
            createdAt: DateTime(2026, 3, 28, 9),
            updatedAt: DateTime(2026, 3, 28, 9),
          ),
        ],
        recentAuditEntries: [
          AdminAuditReviewEntry(
            eventType: 'session.closed',
            actorName: 'Admin',
            teamId: 'team-1',
            sessionId: 'session-1',
            occurredAt: DateTime(2026, 3, 28, 11),
          ),
        ],
        pendingRestoreAccounts: const [
          AdminManagedAccountFollowUp(
            uid: 'user-1',
            name: 'Servant 1',
            email: 'servant1@test.com',
          ),
        ],
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('shows quick metrics and audit review sections', (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AdminDashboardCubit>.value(value: cubit),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );

    expect(find.text('تقارير سريعة'), findsOneWidget);
    expect(find.text('مراجعة النشاط'), findsOneWidget);
    expect(find.text('Friday Meeting'), findsOneWidget);
    expect(find.text('Servant 1'), findsOneWidget);
  });
}
