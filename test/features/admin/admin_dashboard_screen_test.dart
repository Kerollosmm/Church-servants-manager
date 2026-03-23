import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late AdminDashboardCubit cubit;

  final adminUser = AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'مينا',
    role: UserRole.admin,
  );

  setUp(() {
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthAuthenticated(adminUser));
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    cubit = AdminDashboardCubit.seeded(
      AdminDashboardState(
        totalStudents: 42,
        totalServants: 8,
        sessionsThisMonth: 5,
        recentSessions: [
          AttendanceSession(
            id: 's1',
            teamId: 't1',
            teamNameSnapshot: 'إعدادي',
            title: 'اجتماع الجمعة',
            dateKey: '2026-03-20',
            startsAt: DateTime(2026, 3, 20, 18),
            endsAt: DateTime(2026, 3, 20, 19),
            durationMinutes: 60,
            createdByUserId: 'admin-1',
            createdByName: 'مينا',
            createdAt: DateTime(2026, 3, 20, 17),
            updatedAt: DateTime(2026, 3, 20, 17),
          ),
        ],
      ),
    );
  });

  Widget buildSubject({NavigatorObserver? observer}) {
    return MaterialApp(
      theme: AppTheme.light(),
      navigatorObservers: observer == null
          ? const <NavigatorObserver>[]
          : [observer],
      routes: {
        studentList: (_) =>
            Scaffold(appBar: AppBar(), body: const Text(studentList)),
        servantList: (_) =>
            Scaffold(appBar: AppBar(), body: const Text(servantList)),
        attendanceHistory: (_) =>
            Scaffold(appBar: AppBar(), body: const Text(attendanceHistory)),
        teamManagement: (_) =>
            Scaffold(appBar: AppBar(), body: const Text(teamManagement)),
      },
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: AdminDashboardScreen(cubit: cubit),
      ),
    );
  }

  testWidgets('renders dashboard sections without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('مرحباً، مينا'), findsOneWidget);
    expect(find.text('آخر الجلسات'), findsOneWidget);
    expect(find.text('الطلاب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick actions navigate to expected routes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final studentsAction = find.text('الطلاب').first;
    await tester.ensureVisible(studentsAction);
    await tester.tap(studentsAction);
    await tester.pumpAndSettle();
    expect(find.text(studentList), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final servantsAction = find.text('الخدام').last;
    await tester.ensureVisible(servantsAction);
    await tester.tap(servantsAction);
    await tester.pumpAndSettle();
    expect(find.text(servantList), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final attendanceAction = find.text('الحضور').last;
    await tester.ensureVisible(attendanceAction);
    await tester.tap(attendanceAction);
    await tester.pumpAndSettle();
    expect(find.text(attendanceHistory), findsOneWidget);
  });
}
