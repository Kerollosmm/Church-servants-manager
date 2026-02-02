import 'package:bloc_test/bloc_test.dart';
import 'package:church_managment_system/core/error/failures.dart';
import 'package:church_managment_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/shared/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  final testUser = UserEntity(
    id: '123',
    email: 'test@test.com',
    name: 'Test User',
    role: UserRole.admin,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthCheckStatus is added and user exists',
      build: () {
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [
        AuthLoading(),
        AuthAuthenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when AuthCheckStatus is added and user is null',
      build: () {
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Left(CacheFailure('No user')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [
        AuthLoading(),
        AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when AuthLoginRequested is successful',
      build: () {
        when(() => mockAuthRepository.login(any(), any()))
            .thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(email: 'e', password: 'p')),
      expect: () => [
        AuthLoading(),
        AuthAuthenticated(testUser),
      ],
    );
  });
}
