import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_management_screen.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockStudentDataBloc extends MockBloc<StudentDataEvent, StudentDataState>
    implements StudentDataBloc {}

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthEventCheckStatus());
    registerFallbackValue(const StudentsListeningStopped());
    registerFallbackValue(
      StudentsLoadRequested(
        actor: AuthUser(
          uid: 'a',
          email: 'a@a.com',
          name: 'A',
          role: UserRole.admin,
        ),
      ),
    );
  });

  Widget buildTestApp({
    required MockAuthBloc authBloc,
    required MockStudentDataBloc studentBloc,
    required MockTeamRepository teamRepository,
  }) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TeamRepository>.value(value: teamRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<StudentDataBloc>.value(value: studentBloc),
        ],
        child: const MaterialApp(home: StudentManagementScreen()),
      ),
    );
  }

  ({AuthUser actor, StudentModel student, StudentDataLoaded loaded})
  buildAdminFixture() {
    const actor = AuthUser(
      uid: 'admin-1',
      email: 'admin@test.com',
      name: 'Admin',
      role: UserRole.admin,
      isEmailVerified: true,
    );

    final student = StudentModel(
      uid: 'student-1',
      docID: 'doc-1',
      name: 'Test Student',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team A',
      motherPhone: '01111111111',
      fatherPhone: '02222222222',
      grade: 8,
      educationStage: EducationStage.preparatory,
      school: 'Test School',
      address: 'Test Address',
      birthdate: DateTime(2010, 5, 1),
      fatherOfConfession: 'Fr. Test',
      notes: null,
      classId: 'year1',
    );

    return (
      actor: actor,
      student: student,
      loaded: StudentDataLoaded(students: [student]),
    );
  }

  testWidgets('admin sees manage students title and list items', (
    tester,
  ) async {
    final authBloc = MockAuthBloc();
    final studentBloc = MockStudentDataBloc();
    final teamRepository = MockTeamRepository();

    final fixture = buildAdminFixture();
    final actor = fixture.actor;
    final studentsState = fixture.loaded;

    when(() => authBloc.state).thenReturn(AuthAuthenticated(actor));
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(actor),
    );

    when(() => studentBloc.state).thenReturn(studentsState);
    whenListen(
      studentBloc,
      Stream<StudentDataState>.fromIterable([studentsState]),
      initialState: studentsState,
    );
    when(
      () => teamRepository.watchTeamsByGroup(any()),
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      buildTestApp(
        authBloc: authBloc,
        studentBloc: studentBloc,
        teamRepository: teamRepository,
      ),
    );

    await tester.pump();

    expect(find.text('Manage Students'), findsOneWidget);
    expect(find.text('Test Student'), findsOneWidget);
  });

  testWidgets(
    'keeps previously loaded list visible during operation success state',
    (tester) async {
      final authBloc = MockAuthBloc();
      final studentBloc = MockStudentDataBloc();
      final teamRepository = MockTeamRepository();
      final fixture = buildAdminFixture();
      final actor = fixture.actor;
      final loaded = fixture.loaded;
      const success = StudentDataOperationSuccess(
        'Student updated successfully',
      );

      when(() => authBloc.state).thenReturn(AuthAuthenticated(actor));
      whenListen(
        authBloc,
        const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(actor),
      );

      when(() => studentBloc.state).thenReturn(loaded);
      whenListen(
        studentBloc,
        Stream<StudentDataState>.fromIterable([success]),
        initialState: loaded,
      );

      when(
        () => teamRepository.watchTeamsByGroup(any()),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        buildTestApp(
          authBloc: authBloc,
          studentBloc: studentBloc,
          teamRepository: teamRepository,
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Test Student'), findsOneWidget);
      expect(find.text('Student updated successfully'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps previously loaded list visible and shows snackbar on error state',
    (tester) async {
      final authBloc = MockAuthBloc();
      final studentBloc = MockStudentDataBloc();
      final teamRepository = MockTeamRepository();
      final fixture = buildAdminFixture();
      final actor = fixture.actor;
      final loaded = fixture.loaded;
      const error = StudentDataError(
        'Unable to update student. Please try again.',
      );

      when(() => authBloc.state).thenReturn(AuthAuthenticated(actor));
      whenListen(
        authBloc,
        const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(actor),
      );

      when(() => studentBloc.state).thenReturn(loaded);
      whenListen(
        studentBloc,
        Stream<StudentDataState>.fromIterable([error]),
        initialState: loaded,
      );

      when(
        () => teamRepository.watchTeamsByGroup(any()),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        buildTestApp(
          authBloc: authBloc,
          studentBloc: studentBloc,
          teamRepository: teamRepository,
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Test Student'), findsOneWidget);
      expect(
        find.text('Unable to update student. Please try again.'),
        findsOneWidget,
      );
    },
  );
}
