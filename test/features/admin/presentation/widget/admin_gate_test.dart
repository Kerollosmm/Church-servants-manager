import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/domain/admin_policy.dart';
import 'package:church_management_system/features/admin/presentation/widget/admin_gate.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockAdminPolicy extends Mock implements AdminPolicy {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockAdminPolicy mockAdminPolicy;

  const adminUser = AuthUser(
    uid: 'admin1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  const nonAdminUser = AuthUser(
    uid: 'servant1',
    email: 'servant@example.com',
    name: 'Servant',
    role: UserRole.servant,
    isEmailVerified: true,
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockAdminPolicy = MockAdminPolicy();
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: AdminGate(
          policy: mockAdminPolicy,
          child: const Text('Admin Content'),
        ),
      ),
    );
  }

  group('AdminGate Widget', () {
    testWidgets('shows CircularProgressIndicator when state is AuthInitial', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when state is AuthLoading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows child widget for AuthAuthenticated with Admin + Fresh Session', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(adminUser));
      when(() => mockAdminPolicy.canAccessAdminArea(user: adminUser, isSessionFresh: true))
          .thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Admin Content'), findsOneWidget);
    });

    testWidgets('shows Access Denied for AuthAuthenticated Non-Admin', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(nonAdminUser));
      when(() => mockAdminPolicy.canAccessAdminArea(user: nonAdminUser, isSessionFresh: true))
          .thenReturn(false);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('وصول غير مسموح'), findsOneWidget);
      expect(find.text('مطلوب صلاحيات مسؤول'), findsOneWidget);
    });

    testWidgets('shows Access Denied for AuthAuthenticated Admin with Stale Session', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthAuthenticated(adminUser));
      when(() => mockAdminPolicy.canAccessAdminArea(user: adminUser, isSessionFresh: true))
          .thenReturn(false);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('وصول غير مسموح'), findsOneWidget);
    });

    testWidgets('shows Requires Fresh Session for AuthDegraded', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthDegraded(user: adminUser, message: 'Need refresh'),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('تأكيد الوصول للمسؤول'), findsOneWidget);
      expect(find.text('Need refresh'), findsOneWidget);
    });

    testWidgets('shows account not available for AuthArchived', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthArchived(message: 'Archived'),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('هذا الحساب غير متاح حاليا.'), findsOneWidget);
    });

    testWidgets('dispatches AuthEventRefreshUser on refresh button tap', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthDegraded(user: adminUser, message: 'Need refresh'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      
      final button = find.widgetWithText(FilledButton, 'مزامنة الوصول');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      verify(() => mockAuthBloc.add(const AuthEventRefreshUser())).called(1);
    });
  });
}
