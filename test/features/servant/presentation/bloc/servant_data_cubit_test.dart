import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockServantDataRepository extends Mock implements ServantDataRepository {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockServantDataRepository repository;
  late MockAuthService authService;

  AuthUser actor(UserRole role) => AuthUser(
    uid: 'u1',
    email: 'user@example.com',
    name: 'Test User',
    role: role,
    isEmailVerified: true,
  );

  ServantModel servant(String id, String name) =>
      ServantModel(docID: id, uid: id, name: name, role: UserRole.servant);

  setUpAll(() {
    registerFallbackValue(servant('fallback', 'Fallback'));
  });

  setUp(() {
    repository = MockServantDataRepository();
    authService = MockAuthService();
  });

  test('denies non-admin load with permission error', () async {
    final cubit = ServantDataCubit(
      repository: repository,
      authService: authService,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ServantDataError>().having(
          (s) => s.message,
          'message',
          'Permission denied: Only admins can manage servants.',
        ),
      ]),
    );

    await cubit.loadServants(actor: actor(UserRole.servant));
    await expectation;
    verifyNever(
      () => repository.getServantsPage(limit: 50, lastDocument: null),
    );
    await cubit.close();
  });

  test(
    'loads first servants page and emits sorted results with hasMore',
    () async {
      when(
        () => repository.getServantsPage(limit: 50, lastDocument: null),
      ).thenAnswer(
        (_) async => ServantsPage(
          servants: [servant('2', 'Mina'), servant('1', 'Andrew')],
          lastDocument: null,
          hasMore: true,
        ),
      );

      final cubit = ServantDataCubit(
        repository: repository,
        authService: authService,
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ServantDataLoading>(),
          isA<ServantDataLoaded>().having(
            (s) => s.servants.map((e) => e.name).toList(),
            'sortedNames',
            ['Andrew', 'Mina'],
          ),
        ]),
      );

      await cubit.loadServants(actor: actor(UserRole.admin));
      await expectation;
      final loaded = cubit.state as ServantDataLoaded;
      expect(loaded.hasMore, isTrue);
      verify(
        () => repository.getServantsPage(limit: 50, lastDocument: null),
      ).called(1);
      await cubit.close();
    },
  );

  test('create rolls back linked auth user when servant write fails', () async {
    final admin = actor(UserRole.admin);
    final newServant = servant('draft-id', 'Andrew');
    final linkedAuthUser = AuthUser(
      uid: 'auth-uid',
      email: 'servant@example.com',
      name: newServant.name,
      role: UserRole.servant,
      isEmailVerified: false,
    );

    when(
      () => authService.createUserAsAdmin(
        email: 'servant@example.com',
        password: 'secret123',
        name: newServant.name,
        role: UserRole.servant,
      ),
    ).thenAnswer((_) async => linkedAuthUser);
    when(
      () => repository.createServant(
        newServant.copyWith(uid: 'auth-uid', docID: 'auth-uid'),
      ),
    ).thenThrow(Exception('write failed'));
    when(
      () => authService.rollbackAdminCreatedUser(
        uid: 'auth-uid',
        email: 'servant@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async {});

    final cubit = ServantDataCubit(
      repository: repository,
      authService: authService,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ServantDataLoading>(),
        isA<ServantDataError>().having(
          (s) => s.message,
          'message',
          'Exception: write failed',
        ),
      ]),
    );

    await cubit.createServant(
      actor: admin,
      servant: newServant,
      email: 'servant@example.com',
      password: 'secret123',
    );

    await expectation;
    verify(() => repository.createServant(any())).called(1);
    verify(
      () => authService.rollbackAdminCreatedUser(
        uid: 'auth-uid',
        email: 'servant@example.com',
        password: 'secret123',
      ),
    ).called(1);
    await cubit.close();
  });
}
