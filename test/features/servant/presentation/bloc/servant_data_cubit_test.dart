import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockServantDataRepository extends Mock implements ServantDataRepository {}

class MockProvisionServantWithAuthUseCase extends Mock
    implements ProvisionServantWithAuthUseCase {}

void main() {
  late MockServantDataRepository repository;
  late MockProvisionServantWithAuthUseCase provisionUseCase;

  AuthUser actor(UserRole role) => AuthUser(
    uid: 'u1',
    email: 'user@example.com',
    name: 'Test User',
    role: role,
    isEmailVerified: true,
  );

  ServantModel servant(String id, String name) =>
      ServantModel(docID: id, uid: id, name: name);

  setUpAll(() {
    registerFallbackValue(servant('fallback', 'Fallback'));
  });

  setUp(() {
    repository = MockServantDataRepository();
    provisionUseCase = MockProvisionServantWithAuthUseCase();
  });

  test('denies non-admin load with permission error', () async {
    final cubit = ServantDataCubit(
      repository: repository,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ServantDataError>().having((s) => s.message, 'message', isNotEmpty),
      ]),
    );

    await cubit.loadServants(actor: actor(UserRole.servant));
    await expectation;
    verifyNever(
      () => repository.getServantsPage(
        limit: any(named: 'limit'),
        lastDocument: any(named: 'lastDocument'),
        includeArchived: any(named: 'includeArchived'),
      ),
    );
    await cubit.close();
  });

  test(
    'loads first servants page and emits sorted results with hasMore',
    () async {
      when(
        () => repository.getServantsPage(
          limit: any(named: 'limit'),
          lastDocument: any(named: 'lastDocument'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer(
        (_) async => ServantsPage(
          servants: [servant('2', 'Mina'), servant('1', 'Andrew')],
          lastDocument: null,
          hasMore: true,
        ),
      );

      final cubit = ServantDataCubit(
        repository: repository,
        provisionUseCase: provisionUseCase,
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
        () => repository.getServantsPage(
          limit: any(named: 'limit'),
          lastDocument: any(named: 'lastDocument'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).called(1);
      await cubit.close();
    },
  );

  test('create calls provisionUseCase and reloads data', () async {
    final admin = actor(UserRole.admin);
    final newServant = servant('draft-id', 'Andrew');

    when(
      () => provisionUseCase.call(
        servant: newServant,
        email: 'servant@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async => 'auth-uid');

    when(
      () => repository.getServantsPage(
        limit: any(named: 'limit'),
        lastDocument: any(named: 'lastDocument'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer(
      (_) async => ServantsPage(
        servants: [servant('auth-uid', 'Andrew')],
        lastDocument: null,
        hasMore: false,
      ),
    );

    final cubit = ServantDataCubit(
      repository: repository,
      provisionUseCase: provisionUseCase,
    );

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<ServantDataLoaded>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          ServantMutationStatus.inProgress,
        ),
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          ServantMutationStatus.idle,
        ),
        isA<ServantDataLoaded>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          ServantMutationStatus.success,
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
    verify(
      () => provisionUseCase.call(
        servant: newServant,
        email: 'servant@example.com',
        password: 'secret123',
      ),
    ).called(1);
    await cubit.close();
  });

  test(
    'restoreServant restores archived servant via usecase and emits success state',
    () async {
      final admin = actor(UserRole.admin);
      final archivedServant = servant(
        's1',
        'Andrew',
      ).copyWith(isArchived: true);

      when(
        () => repository.getServantById('s1', includeArchived: true),
      ).thenAnswer((_) async => archivedServant);

      when(
        () => provisionUseCase.restore(
          docId: 's1',
          performedByUid: admin.uid,
          linkedUid: archivedServant.uid,
        ),
      ).thenAnswer((_) async {});

      when(
        () => repository.getServantsPage(
          limit: any(named: 'limit'),
          lastDocument: any(named: 'lastDocument'),
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer(
        (_) async => ServantsPage(
          servants: [servant('s2', 'Mina')],
          lastDocument: null,
          hasMore: false,
        ),
      );

      final cubit = ServantDataCubit(
        repository: repository,
        provisionUseCase: provisionUseCase,
      );

      final expectation = expectLater(
        cubit.stream,
        emitsThrough(
          isA<ServantDataLoaded>().having(
            (s) => s.feedbackMessage,
            'feedbackMessage',
            isNotEmpty,
          ),
        ),
      );

      await cubit.restoreServant(actor: admin, docId: 's1');

      await expectation;
      verify(
        () => provisionUseCase.restore(
          docId: 's1',
          performedByUid: admin.uid,
          linkedUid: archivedServant.uid,
        ),
      ).called(1);
      await cubit.close();
    },
  );
}
