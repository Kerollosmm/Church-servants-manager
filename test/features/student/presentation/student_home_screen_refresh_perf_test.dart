import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthEventCheckStatus());
  });

  testWidgets('measures refresh callback completion time', (tester) async {
    final authBloc = MockAuthBloc();

    const user = AuthUser(
      uid: 'student-1',
      email: 'student@test.com',
      name: 'Student',
      role: UserRole.student,
      isEmailVerified: true,
    );

    const authenticatedState = AuthAuthenticated(user);

    when(() => authBloc.state).thenReturn(authenticatedState);
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: authenticatedState,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const StudentHomeScreen(user: user),
        ),
      ),
    );
    await tester.pump();

    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );

    final start = tester.binding.clock.now();
    var completed = false;

    refreshIndicator.onRefresh().then((_) {
      completed = true;
    });

    await tester.pump();

    var ticks = 0;
    while (!completed && ticks < 300) {
      await tester.pump(const Duration(milliseconds: 10));
      ticks++;
    }

    final elapsed = tester.binding.clock.now().difference(start);
    debugPrint('student_home_refresh_elapsed_ms=${elapsed.inMilliseconds}');

    expect(completed, isTrue);
    expect(
      elapsed.inMilliseconds,
      lessThan(100),
      reason:
          'Refresh callback should complete promptly without an artificial delay.',
    );
    verify(() => authBloc.add(const AuthEventRefreshUser())).called(1);
  });
}
