import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/role_router.dart';
import 'package:church_management_system/features/admin/presentation/widget/admin_gate.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildHarness() {
    return MaterialApp(
      routes: {
        '/': (_) => BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const AdminGate(child: Scaffold(body: Text('Admin Child'))),
        ),
        login: (_) => const Scaffold(body: Text('Login Screen')),
      },
    );
  }

  group('AdminGate', () {
    testWidgets('shows child for authenticated admins', (tester) async {
      when(
        () => authBloc.state,
      ).thenReturn(AuthAuthenticated(_buildUser(UserRole.admin)));

      await tester.pumpWidget(buildHarness());

      expect(find.text('Admin Child'), findsOneWidget);
      expect(find.text('Login Screen'), findsNothing);
    });

    testWidgets('redirects servants to login', (tester) async {
      when(
        () => authBloc.state,
      ).thenReturn(AuthAuthenticated(_buildUser(UserRole.servant)));

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.text('Admin Child'), findsNothing);
    });

    testWidgets('redirects unauthenticated users to login', (tester) async {
      when(() => authBloc.state).thenReturn(const AuthUnauthenticated());

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
      expect(find.text('Admin Child'), findsNothing);
    });

    testWidgets('shows refresh-required screen for degraded admins', (
      tester,
    ) async {
      when(() => authBloc.state).thenReturn(
        AuthDegraded(
          user: _buildUser(UserRole.admin),
          message: 'Refresh required',
        ),
      );

      await tester.pumpWidget(buildHarness());

      expect(find.byType(AdminRefreshRequiredScreen), findsOneWidget);
      expect(find.text('Refresh required'), findsOneWidget);
    });
  });
}

AuthUser _buildUser(UserRole role) => AuthUser(
  uid: 'user-${role.name}',
  email: '${role.name}@example.com',
  name: role.name,
  role: role,
  isEmailVerified: true,
);
