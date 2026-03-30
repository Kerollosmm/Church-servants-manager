import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_session_create_screen.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockAttendanceRepository extends Mock implements IAttendanceRepository {}

void main() {
  const actor = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin One',
    role: UserRole.admin,
  );

  late MockAuthBloc authBloc;
  late TeamRepository teamRepository;
  late AttendanceSessionAdminCubit adminCubit;
  late AdminDashboardCubit dashboardCubit;

  setUp(() async {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthAuthenticated(actor));
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection('Classes')
        .doc('team-1')
        .set(TeamModel(id: 'team-1', name: 'فريق 1', groupId: 'g1').toMap());
    teamRepository = TeamRepository(firestore: firestore);
    adminCubit = AttendanceSessionAdminCubit(
      repository: MockAttendanceRepository(),
    );
    dashboardCubit = AdminDashboardCubit.seeded(
      const AdminDashboardState(totalStudents: 1, totalServants: 1),
    );
  });

  tearDown(() async {
    await adminCubit.close();
    await dashboardCubit.close();
  });

  testWidgets('admin dashboard exposes attendance entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<AdminDashboardCubit>.value(value: dashboardCubit),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );

    expect(find.text('إنشاء جلسة حضور'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('سجل الحضور'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('سجل الحضور'), findsOneWidget);
  });

  testWidgets('session create screen renders team form for authorized actor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<TeamRepository>.value(value: teamRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<AttendanceSessionAdminCubit>.value(value: adminCubit),
          ],
          child: const MaterialApp(home: AttendanceSessionCreateScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('إنشاء جلسة حضور'), findsOneWidget);
    expect(find.text('الفريق'), findsOneWidget);
    expect(find.text('إنشاء الجلسة'), findsOneWidget);
  });
}
