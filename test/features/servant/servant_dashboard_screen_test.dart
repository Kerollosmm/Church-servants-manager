import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_dashboard_cubit.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late ServantDashboardCubit cubit;

  final user = AuthUser(
    uid: 'servant-1',
    email: 'servant@example.com',
    name: 'يوحنا',
    role: UserRole.servant,
    assignedTeamIds: const ['team-1'],
  );

  setUp(() {
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthAuthenticated(user));
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    cubit = ServantDashboardCubit.seeded(
      ServantDashboardState(
        currentTeamName: 'فريق مارمرقس',
        teamNames: const ['فريق مارمرقس'],
        assignedStudents: [
          StudentModel(
            uid: 'student-1',
            docID: 'student-1',
            name: 'مريم',
            imageUrl: null,
            role: UserRole.student,
            mobile: '0100',
            group: Group.year1,
            teamName: 'فريق مارمرقس',
            motherPhone: '0100',
            fatherPhone: '0100',
            grade: 8,
            educationStage: EducationStage.preparatory,
            school: 'School',
            address: 'Address',
            birthdate: DateTime(2012, 1, 1),
            fatherOfConfession: 'Abouna',
            notes: null,
          ),
        ],
        upcomingSessions: [
          AttendanceSession(
            id: 'session-1',
            teamId: 'team-1',
            teamNameSnapshot: 'فريق مارمرقس',
            title: 'اجتماع الجمعة',
            dateKey: '2026-03-25',
            startsAt: DateTime(2026, 3, 25, 18),
            endsAt: DateTime(2026, 3, 25, 19),
            durationMinutes: 60,
            createdByUserId: 'servant-1',
            createdByName: 'يوحنا',
            createdAt: DateTime(2026, 3, 25, 17),
            updatedAt: DateTime(2026, 3, 25, 17),
          ),
        ],
        weeklyAttendanceRate: 87,
      ),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      theme: AppTheme.light(),
      routes: {
        studentList: (_) =>
            Scaffold(appBar: AppBar(), body: const Text(studentList)),
        attendanceSessionCreate: (_) => Scaffold(
          appBar: AppBar(),
          body: const Text(attendanceSessionCreate),
        ),
      },
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: ServantDashboardScreen(user: user, cubit: cubit),
      ),
    );
  }

  testWidgets('renders servant sections without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('خادم'), findsOneWidget);
    expect(find.text('الجلسات القادمة'), findsOneWidget);
    expect(find.text('طلابي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance CTA navigates to session creation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('تسجيل حضور'));
    await tester.tap(find.text('تسجيل حضور'));
    await tester.pumpAndSettle();

    expect(find.text(attendanceSessionCreate), findsOneWidget);
  });
}
