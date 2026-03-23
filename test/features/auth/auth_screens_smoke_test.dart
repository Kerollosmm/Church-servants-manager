import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/register_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authBloc.close()).thenAnswer((_) async {});
  });

  Widget buildSubject(Widget screen) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(theme: AppTheme.light(), home: screen),
    );
  }

  testWidgets('RegisterScreen renders fields', (tester) async {
    await tester.pumpWidget(buildSubject(const RegisterScreen()));

    expect(find.text('إنشاء حساب'), findsNWidgets(2));
    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen renders fields', (tester) async {
    await tester.pumpWidget(buildSubject(const ForgotPasswordScreen()));

    expect(find.text('إعادة تعيين كلمة المرور'), findsOneWidget);
    expect(
      find.text('أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين'),
      findsOneWidget,
    );
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
  });

  testWidgets('VerifyEmailScreen renders info', (tester) async {
    when(() => authBloc.state).thenReturn(const AuthNeedsVerification());

    await tester.pumpWidget(buildSubject(const VerifyEmailScreen()));

    expect(find.text('تحقق من بريدك الإلكتروني'), findsOneWidget);
    expect(
      find.text(
        'أرسلنا رابط التحقق إلى بريدك الإلكتروني. افتح بريدك واضغط على الرابط للمتابعة.',
      ),
      findsOneWidget,
    );
  });
}
