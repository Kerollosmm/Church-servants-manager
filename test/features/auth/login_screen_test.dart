import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AuthEventCheckStatus());
  });

  setUp(() {
    authBloc = MockAuthBloc();
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
    when(() => authBloc.add(any())).thenReturn(null);
    when(() => authBloc.close()).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return MaterialApp(
      theme: AppTheme.light(),
      routes: <String, WidgetBuilder>{
        '/forgot-password': (_) => const Scaffold(body: SizedBox()),
        '/register': (_) => const Scaffold(body: SizedBox()),
      },
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const LoginScreen(),
      ),
    );
  }

  testWidgets('login screen renders email and password fields', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('tapping login with empty fields shows validators', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
    expect(find.text('كلمة المرور مطلوبة'), findsOneWidget);
  });

  testWidgets('primary button shows loading indicator when bloc is loading', (
    tester,
  ) async {
    when(() => authBloc.state).thenReturn(const AuthLoading());

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
