import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentDataBloc extends MockBloc<StudentDataEvent, StudentDataState>
    implements StudentDataBloc {}

void main() {
  late MockStudentDataBloc studentBloc;

  setUp(() {
    studentBloc = MockStudentDataBloc();
  });

  const adminActor = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin',
    role: UserRole.admin,
  );

  Widget createWidgetUnderTest({StudentEditArgs? args}) {
    return MaterialApp(
      home: BlocProvider<StudentDataBloc>.value(
        value: studentBloc,
        child: StudentEditScreen(
          args: args ?? StudentEditArgs(actor: adminActor),
        ),
      ),
    );
  }

  group('StudentEditScreen', () {
    testWidgets('should show validation errors when required fields are empty', (tester) async {
      when(() => studentBloc.state).thenReturn(const StudentDataInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Scroll to bottom to find the button
      final buttonFinder = find.byKey(const Key('submit_student_button'));
      
      await tester.scrollUntilVisible(
        buttonFinder,
        500.0,
        scrollable: find.byType(Scrollable).first, // Find the main scrollable
      );
      await tester.pumpAndSettle();

      // Find Create Student button and tap it
      await tester.tap(buttonFinder);
      await tester.pump();

      // Check for validation errors
      // Note: ListView unbuilds items off-screen, so we might need to scroll back up to find "Name is required"
      final nameErrorFinder = find.text('Name is required');
      await tester.scrollUntilVisible(
        nameErrorFinder,
        -500.0, // Try negative to scroll up? scrollUntilVisible takes maxScroll. 
        // Actually, to scroll UP we usually drag. But let's try finding the Name field.
        scrollable: find.byType(Scrollable).first,
      );
      // Fallback: simple drag if scrollUntilVisible fails for 'up'
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000)); 
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
