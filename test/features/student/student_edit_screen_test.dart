import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_edit_screen.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataBloc extends MockBloc<StudentDataEvent, StudentDataState>
    implements StudentDataBloc {}

class MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  late MockStudentDataBloc studentBloc;
  late MockTeamRepository teamRepository;

  setUp(() {
    studentBloc = MockStudentDataBloc();
    when(() => studentBloc.state).thenReturn(const StudentDataInitial());

    teamRepository = MockTeamRepository();
    when(() => teamRepository.getTeamsByGroup(any())).thenAnswer(
      (_) async => const [
        TeamModel(id: 'team-1', name: 'Team 1', groupId: 'year1'),
      ],
    );
    when(
      () => teamRepository.watchTeamsByGroup(any()),
    ).thenAnswer((_) => const Stream.empty());
  });

  const adminActor = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin',
    role: UserRole.admin,
  );
  const servantActor = AuthUser(
    uid: 'servant-1',
    email: 'servant@test.com',
    name: 'Servant',
    role: UserRole.servant,
    groupId: 'year1',
  );

  StudentModel buildStudentForEdit({String uid = 'student-1'}) {
    return StudentModel(
      uid: uid,
      docID: 'student-doc-1',
      name: 'Student One',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: 'Team 1',
      motherPhone: '01111111111',
      fatherPhone: '02222222222',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: 'Fr.',
      notes: null,
      classId: 'team-1',
    );
  }

  Widget createWidgetUnderTest({StudentEditArgs? args}) {
    return MaterialApp(
      home: RepositoryProvider<TeamRepository>.value(
        value: teamRepository,
        child: BlocProvider<StudentDataBloc>.value(
          value: studentBloc,
          child: StudentEditScreen(
            args: args ?? StudentEditArgs(actor: adminActor),
          ),
        ),
      ),
    );
  }

  group('StudentEditScreen', () {
    testWidgets(
      'should show validation errors when required fields are empty',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        final scrollable = find.byType(Scrollable).first;
        final buttonFinder = find.byKey(const Key('submit_student_button'));

        await tester.drag(scrollable, const Offset(0, -2000));
        await tester.pumpAndSettle();

        expect(buttonFinder, findsOneWidget);
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        expect(find.text('Name is required'), findsOneWidget);
      },
    );

    testWidgets('shows role selector for admin when editing', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          args: StudentEditArgs(
            actor: adminActor,
            student: buildStudentForEdit(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('student_role_field')), findsOneWidget);
    });

    testWidgets('hides role selector for non-admin when editing', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          args: StudentEditArgs(
            actor: servantActor,
            student: buildStudentForEdit(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('student_role_field')), findsNothing);
    });

    testWidgets('blocks promotion to servant when linked uid is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          args: StudentEditArgs(
            actor: adminActor,
            student: buildStudentForEdit(uid: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('student_role_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('servant').last);
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      final buttonFinder = find.byKey(const Key('submit_student_button'));
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Cannot promote student without linked user account.'),
        findsOneWidget,
      );
    });
  });
}
