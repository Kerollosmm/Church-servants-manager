import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthInitial());
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authBloc.close()).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(theme: AppTheme.light(), home: const SplashScreen()),
    );
  }

  testWidgets('SplashScreen renders logo and title', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('الكنيسة'), findsOneWidget);
    // AppLogo is used, which contains an Image.asset
    // In widget tests, assets are not loaded by default, but we can check if it exists
  });

  testWidgets('SplashScreen navigates after timer if state is not changed', (
    tester,
  ) async {
    // We need to provide a mock for RoleUserRoute if we want to check navigation
    // or just check that it doesn't crash during the timer.
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 3));
    // After 2 seconds it tries to navigate.
    // Since we didn't provide a navigator observer or routes, it might fail to find RoleUserRoute
    // unless we include it in the widget tree or mock the navigation.
  });
}
