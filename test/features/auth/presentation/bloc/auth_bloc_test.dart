import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/repos/firebase_auth_repository.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements FirebaseAuthRepository {}

void main() {
  late MockAuthService authService;

  AuthUser testUser({bool isEmailVerified = true}) {
    return AuthUser(
      uid: 'u1',
      email: 'user@example.com',
      name: 'Test User',
      role: UserRole.student,
      isEmailVerified: isEmailVerified,
    );
  }

  setUp(() {
    authService = MockAuthService();
    when(
      () => authService.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
  });

  test('emits loading then authenticated on successful sign in', () async {
    when(
      () => authService.signIn(email: 'user@example.com', password: 'password'),
    ).thenAnswer((_) async => testUser());

    final bloc = AuthBloc(authService: authService);
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user.uid, 'uid', 'u1'),
      ]),
    );

    bloc.add(
      const AuthEventSignIn(email: 'user@example.com', password: 'password'),
    );
    await expectation;
    await bloc.close();
  });

  test(
    'emits loading then needs verification when email is not verified',
    () async {
      when(
        () => authService.signIn(email: 'user@example.com', password: 'pw'),
      ).thenThrow(const EmailNotVerifiedFailure());

      final bloc = AuthBloc(authService: authService);
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthNeedsVerification>()]),
      );

      bloc.add(
        const AuthEventSignIn(email: 'user@example.com', password: 'pw'),
      );
      await expectation;
      await bloc.close();
    },
  );

  test('emits unauthenticated when check status has no user', () async {
    when(
      () => authService.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));
    when(() => authService.currentUser).thenReturn(null);

    final bloc = AuthBloc(authService: authService);
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
    );

    bloc.add(const AuthEventCheckStatus());
    await expectation;

    verifyNever(
      () => authService.getCurrentAppUser(
        forceRefresh: any(named: 'forceRefresh'),
      ),
    );
    await bloc.close();
  });

  test('emits authenticated when check status finds verified user', () async {
    final currentUser = testUser();
    final fullUser = testUser();

    when(
      () => authService.authStateChanges,
    ).thenAnswer((_) => Stream.value(currentUser));
    when(() => authService.reloadUser()).thenAnswer((_) async {});
    when(() => authService.currentUser).thenReturn(currentUser);
    when(
      () => authService.getCurrentAppUser(forceRefresh: true),
    ).thenAnswer((_) async => fullUser);

    final bloc = AuthBloc(authService: authService);
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.email,
          'email',
          'user@example.com',
        ),
      ]),
    );

    bloc.add(const AuthEventCheckStatus());
    await expectation;
    await bloc.close();
  });

  test(
    'emits degraded when check status fails but cached user exists',
    () async {
      final adminUser = AuthUser(
        uid: 'admin1',
        email: 'admin@example.com',
        name: 'Admin',
        role: UserRole.admin,
        isEmailVerified: true,
      );

      when(
        () => authService.authStateChanges,
      ).thenAnswer((_) => Stream.value(adminUser));
      when(
        () => authService.reloadUser(),
      ).thenThrow(const GenericAuthFailure('reload failed'));
      when(() => authService.currentUser).thenReturn(adminUser);
      when(() => authService.lastKnownAppUser).thenReturn(adminUser);

      final bloc = AuthBloc(authService: authService);
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthDegraded>().having(
            (s) => s.user.role,
            'role',
            UserRole.admin,
          ),
        ]),
      );

      bloc.add(const AuthEventCheckStatus());
      await expectation;
      await bloc.close();
    },
  );

  test(
    'emits degraded on refresh failure when cached user matches session',
    () async {
      final adminUser = AuthUser(
        uid: 'admin1',
        email: 'admin@example.com',
        name: 'Admin',
        role: UserRole.admin,
        isEmailVerified: true,
      );

      when(
        () => authService.refreshCurrentAppUser(),
      ).thenThrow(const GenericAuthFailure('refresh failed'));
      when(() => authService.currentUser).thenReturn(adminUser);
      when(() => authService.lastKnownAppUser).thenReturn(adminUser);

      final bloc = AuthBloc(authService: authService);
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthDegraded>().having((s) => s.user.uid, 'uid', 'admin1'),
        ]),
      );

      bloc.add(const AuthEventRefreshUser());
      await expectation;
      await bloc.close();
    },
  );

  test('emits authenticated on refresh when service returns user', () async {
    final refreshedUser = AuthUser(
      uid: 'u2',
      email: 'refreshed@example.com',
      name: 'Refreshed',
      role: UserRole.servant,
      isEmailVerified: true,
    );

    when(
      () => authService.refreshCurrentAppUser(),
    ).thenAnswer((_) async => refreshedUser);

    final bloc = AuthBloc(authService: authService);
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthAuthenticated>().having(
          (s) => s.user.email,
          'email',
          'refreshed@example.com',
        ),
      ]),
    );

    bloc.add(const AuthEventRefreshUser());
    await expectation;
    await bloc.close();
  });

  test('emits archived when resolved user is archived on startup', () async {
    final archivedUser = AuthUser(
      uid: 'u1',
      email: 'archived@example.com',
      name: 'Archived User',
      role: UserRole.student,
      isEmailVerified: true,
      isArchived: true,
    );

    when(() => authService.currentUser).thenReturn(archivedUser);
    when(() => authService.reloadUser()).thenAnswer((_) async {});
    when(
      () => authService.getCurrentAppUser(forceRefresh: true),
    ).thenAnswer((_) async => archivedUser);

    final bloc = AuthBloc(authService: authService);
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthArchived>().having(
          (s) => s.email,
          'email',
          'archived@example.com',
        ),
      ]),
    );

    bloc.add(const AuthEventCheckStatus());
    await expectation;
    await bloc.close();
  });

  test('reacts to live auth session stream updates after bootstrap', () async {
    final controller = StreamController<AuthUser?>.broadcast();
    when(
      () => authService.authStateChanges,
    ).thenAnswer((_) => controller.stream);
    when(() => authService.currentUser).thenReturn(null);
    when(() => authService.getCurrentAppUser()).thenAnswer((_) async => null);

    final bloc = AuthBloc(authService: authService);
    
    // Bootstrap the bloc
    bloc.add(const AuthEventCheckStatus());
    await Future<void>.delayed(Duration.zero);
    controller.add(null);
    await Future<void>.delayed(Duration.zero);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthAuthenticated>().having((s) => s.user.uid, 'uid', 'u1'),
        isA<AuthUnauthenticated>(),
      ]),
    );

    controller.add(testUser());
    controller.add(null);

    await expectation;
    await controller.close();
    await bloc.close();
  });
}
