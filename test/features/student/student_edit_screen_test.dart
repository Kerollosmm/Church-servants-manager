import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
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
  });
}
