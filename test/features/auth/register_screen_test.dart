import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    registerFallbackValue(const AuthEventCheckStatus());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen', () {
    testWidgets('should show validation errors when fields are empty', (tester) async {
      when(() => authBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Find Sign Up button and tap it
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Should show validation errors from Validators
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should show error for invalid email', (tester) async {
      when(() => authBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid email
      await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });
  });
}
