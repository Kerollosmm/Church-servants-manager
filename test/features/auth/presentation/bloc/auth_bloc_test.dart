import 'dart:async';

import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockObserveAuthStateUseCase extends Mock
    implements ObserveAuthStateUseCase {}

void main() {
  late MockAuthService authService;
  late MockObserveAuthStateUseCase observeAuthStateUseCase;
  late StreamController<Object?> authStateController;

  setUp(() {
    authService = MockAuthService();
    observeAuthStateUseCase = MockObserveAuthStateUseCase();
    authStateController = StreamController<Object?>.broadcast();

    when(
      () => observeAuthStateUseCase.authStateChanges,
    ).thenAnswer((_) => authStateController.stream.cast());
  });

  tearDown(() async {
    await authStateController.close();
  });

  test(
    'emits AuthPendingPasswordReset when user has restorePendingPasswordReset set',
    () async {
      final user = const AuthUser(
        uid: 'u1',
        email: 'u1@test.com',
        name: 'User',
        role: UserRole.servant,
        restorePendingPasswordReset: true,
      );

      when(() => observeAuthStateUseCase.checkStatus()).thenAnswer((_) async {
        return AuthSessionResolution.authenticated(user);
      });

      final bloc = AuthBloc(
        authService: authService,
        observeAuthStateUseCase: observeAuthStateUseCase,
      );

      final emittedStates = <AuthState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(const AuthEventCheckStatus());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedStates.any((s) => s is AuthPendingPasswordReset), isTrue);

      await subscription.cancel();
      await bloc.close();
    },
  );

  test(
    'rapid double-dispatch of AuthEventCheckStatus emits exactly one loading state',
    () async {
      when(() => observeAuthStateUseCase.checkStatus()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const AuthSessionResolution.unauthenticated();
      });

      final bloc = AuthBloc(
        authService: authService,
        observeAuthStateUseCase: observeAuthStateUseCase,
      );
      final emittedStates = <AuthState>[];
      final subscription = bloc.stream.listen(emittedStates.add);

      bloc.add(const AuthEventCheckStatus());
      bloc.add(const AuthEventCheckStatus());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emittedStates.whereType<AuthLoading>(), hasLength(1));

      await subscription.cancel();
      await bloc.close();
    },
  );
}
