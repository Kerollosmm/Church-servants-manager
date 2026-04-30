import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/screens/student_management_screen.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataBloc extends Mock implements StudentDataBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockTeamRepository extends Mock implements TeamRepository {}

class MockAdminTeamService extends Mock implements AdminTeamService {}

void main() {
  late MockStudentDataBloc mockStudentDataBloc;
  late MockAuthBloc mockAuthBloc;
  late MockTeamRepository mockTeamRepository;
  late MockAdminTeamService mockAdminTeamService;

  setUpAll(() {
    final getIt = GetIt.instance;
    mockTeamRepository = MockTeamRepository();
    mockAdminTeamService = MockAdminTeamService();
    // Allow re-registration if needed
    getIt.allowReassignment = true;
    getIt.registerLazySingleton<TeamRepository>(() => mockTeamRepository);
    getIt.registerLazySingleton<AdminTeamService>(() => mockAdminTeamService);
  });

  setUp(() {
    mockStudentDataBloc = MockStudentDataBloc();
    mockAuthBloc = MockAuthBloc();

    final adminUser = AuthUser(
      uid: 'admin1',
      email: 'admin@example.com',
      name: 'Admin',
      role: UserRole.admin,
    );

    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(adminUser));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(
      () => mockStudentDataBloc.state,
    ).thenReturn(const StudentDataInitial());
    when(
      () => mockStudentDataBloc.stream,
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => mockTeamRepository.getTeamsByGroup(any()),
    ).thenAnswer((_) async => []);
  });

  testWidgets('StudentManagementScreen renders correctly in initial state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<StudentDataBloc>.value(value: mockStudentDataBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const StudentManagementScreen(),
        ),
      ),
    );

    expect(find.text('إدارة المخدومين'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Search field
  });

  testWidgets('StudentManagementScreen shows empty state when no students', (
    WidgetTester tester,
  ) async {
    when(() => mockStudentDataBloc.state).thenReturn(
      const StudentDataLoaded(
        students: [],
        allStudents: [],
        studentsByDocId: {},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<StudentDataBloc>.value(value: mockStudentDataBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const StudentManagementScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('لا يوجد مخدومون'), findsOneWidget);
  });

  testWidgets(
    'StudentManagementScreen shows student list when data is loaded',
    (WidgetTester tester) async {
      final student = StudentModel(
        uid: 's1',
        docID: 's1',
        name: 'Ahmed Mohamed',
        imageUrl: null,
        role: UserRole.student,
        mobile: '01234567890',
        group: Group.year1,
        teamName: 'Team A',
        motherPhone: '01234567890',
        fatherPhone: '01234567890',
        grade: 1,
        educationStage: EducationStage.preparatory,
        school: 'School X',
        address: 'Address Y',
        birthdate: DateTime(2010),
        fatherOfConfession: 'Fr. Test',
        notes: 'Some notes',
        classId: 'team1',
      );

      when(() => mockStudentDataBloc.state).thenReturn(
        StudentDataLoaded(
          students: [student],
          allStudents: [student],
          studentsByDocId: {'s1': student},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<StudentDataBloc>.value(value: mockStudentDataBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: const StudentManagementScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Ahmed Mohamed'), findsOneWidget);
    },
  );
}
