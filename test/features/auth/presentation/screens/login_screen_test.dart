import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/widgets/ochre_auth_card.dart';
import 'package:church_management_system/features/auth/presentation/widgets/ochre_background.dart';
import 'package:church_management_system/features/auth/presentation/widgets/ochre_button.dart';
import 'package:church_management_system/features/auth/presentation/widgets/ochre_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => Stream.value(AuthInitial()));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('should render all Ochre Sanctuary components', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(OchreBackground), findsOneWidget);
      expect(find.byType(OchreAuthCard), findsOneWidget);
      expect(find.byType(OchreTextField), findsNWidgets(2)); // Email & Password
      expect(find.byType(OchreButton), findsOneWidget);
      expect(find.text('نظام إدارة الكنيسة'), findsOneWidget);
    });

    testWidgets(
      'should toggle password visibility when suffix icon is pressed',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // Password field should be obscured initially
        final passwordField = tester.widget<TextField>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is OchreTextField && w.label == 'كلمة المرور',
            ),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordField.obscureText, isTrue);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();

        // Should now be visible
        final toggledField = tester.widget<TextField>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is OchreTextField && w.label == 'كلمة المرور',
            ),
            matching: find.byType(TextField),
          ),
        );
        expect(toggledField.obscureText, isFalse);
      },
    );

    testWidgets('should show loading state in button when AuthLoading', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());
      when(
        () => mockAuthBloc.stream,
      ).thenAnswer((_) => Stream.value(AuthLoading()));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
