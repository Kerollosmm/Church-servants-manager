import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockStudentDataBloc extends MockBloc<StudentDataEvent, StudentDataState>
    implements StudentDataBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthEventCheckStatus());
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

  testWidgets('admin sees manage students title and list items', (
    tester,
  ) async {
    final authBloc = MockAuthBloc();
    final studentBloc = MockStudentDataBloc();

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

    final studentsState = StudentDataLoaded(students: [student]);

    when(() => authBloc.state).thenReturn(const AuthAuthenticated(actor));
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(actor),
    );

    when(() => studentBloc.state).thenReturn(studentsState);
    whenListen(
      studentBloc,
      Stream<StudentDataState>.fromIterable([studentsState]),
      initialState: studentsState,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<StudentDataBloc>.value(value: studentBloc),
        ],
        child: const MaterialApp(home: StudentManagementScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Manage Students'), findsOneWidget);
    expect(find.text('Test Student'), findsOneWidget);
  });
}
