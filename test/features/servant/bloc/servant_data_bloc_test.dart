import 'package:bloc_test/bloc_test.dart';
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
  late MockServantDataRepository mockRepository;
  late MockAuthService mockAuthService;
  late List<ServantModel> allServants;

  const admin = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  const servant = AuthUser(
    uid: 'servant-1',
    email: 's@test.com',
    name: 'Servant',
    role: UserRole.servant,
    groupId: 'team-a',
    isEmailVerified: true,
  );

  setUpAll(() {
    registerFallbackValue(
      ServantModel(
        uid: 'fallback',
        docID: 'fallback',
        name: 'Fallback',
        phone: '0',
        email: null,
        imageUrl: null,
        role: UserRole.servant,
        teamName: 'Team',
        fatherOfConfession: 'Fr.',
        birthdate: null,
        notes: null,
      ),
    );
  });

  setUp(() {
    mockRepository = MockServantDataRepository();
    mockAuthService = MockAuthService();

    allServants = List.generate(10, (i) {
      return ServantModel(
        uid: 'uid-$i',
        docID: 'doc-$i',
        name: 'Servant $i',
        phone: '01234567890',
        email: 'servant$i@test.com',
        imageUrl: null,
        role: UserRole.servant,
        teamName: i.isEven ? 'Team A' : 'Team B',
        fatherOfConfession: 'Fr. Test',
        birthdate: null,
        notes: null,
      );
    });

    when(
      () => mockRepository.getAllServants(limit: any(named: 'limit')),
    ).thenAnswer((_) async => allServants);
    when(
      () => mockRepository.searchServants('Servant 1'),
    ).thenAnswer((_) async => [allServants[1]]);
  });

  group('ServantDataCubit', () {
    blocTest<ServantDataCubit, ServantDataState>(
      'non-admin is blocked from loading servants',
      build: () => ServantDataCubit(
        repository: mockRepository,
        authService: mockAuthService,
      ),
      act: (cubit) => cubit.loadServants(actor: servant),
      expect: () => [
        isA<ServantDataError>().having(
          (s) => s.message,
          'message',
          'Permission denied: Only admins can manage servants.',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepository.getAllServants(limit: any(named: 'limit')),
        );
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'admin can load all servants',
      build: () => ServantDataCubit(
        repository: mockRepository,
        authService: mockAuthService,
      ),
      act: (cubit) => cubit.loadServants(actor: admin),
      expect: () => [
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>()
            .having((s) => s.servants.length, 'count', 10)
            .having((s) => s.currentQuery, 'query', null),
      ],
      verify: (_) {
        verify(() => mockRepository.getAllServants(limit: 200)).called(1);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'admin search filters cached list',
      build: () => ServantDataCubit(
        repository: mockRepository,
        authService: mockAuthService,
      ),
      act: (cubit) async {
        await cubit.loadServants(actor: admin);
        await cubit.searchServants(actor: admin, query: 'Servant 1');
      },
      expect: () => [
        isA<ServantDataLoading>(), // from load
        isA<ServantDataLoaded>().having(
          (s) => s.servants.length,
          'count',
          10,
        ), // from load
        isA<ServantDataLoading>(), // from search
        isA<ServantDataLoaded>()
            .having((s) => s.servants.length, 'count', 1)
            .having((s) => s.currentQuery, 'query', 'Servant 1'), // from search
      ],
      verify: (_) {
        verify(() => mockRepository.getAllServants(limit: 200)).called(1);
        verifyNever(() => mockRepository.searchServants(any()));
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'admin create emits success',
      build: () {
        when(
          () => mockRepository.createServant(any()),
        ).thenAnswer((_) async => 'new-doc');
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      act: (cubit) {
        final newServant = ServantModel(
          uid: 'new-uid',
          docID: 'temp',
          name: 'New Servant',
          phone: '01234567890',
          email: 'new@test.com',
          imageUrl: null,
          role: UserRole.servant,
          teamName: 'Team A',
          fatherOfConfession: 'Fr.',
          birthdate: null,
          notes: null,
        );
        cubit.createServant(actor: admin, servant: newServant);
      },
      expect: () => [
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>(),
        isA<ServantDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.createServant(any())).called(1);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'admin update emits success',
      build: () {
        when(
          () => mockRepository.updateServant(any()),
        ).thenAnswer((_) async {});
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      act: (cubit) {
        final existingServant = allServants.first;
        cubit.updateServant(actor: admin, servant: existingServant);
      },
      expect: () => [
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>(),
        isA<ServantDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.updateServant(any())).called(1);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'admin delete emits success',
      build: () {
        when(
          () => mockRepository.deleteServant(any()),
        ).thenAnswer((_) async {});
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      act: (cubit) {
        cubit.deleteServant(actor: admin, docId: 'doc-0');
      },
      expect: () => [
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>(),
        isA<ServantDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteServant('doc-0')).called(1);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'create avoids reload when list already loaded',
      build: () {
        when(
          () => mockRepository.createServant(any()),
        ).thenAnswer((_) async => 'new-doc');
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      seed: () => ServantDataLoaded(servants: allServants),
      act: (cubit) async {
        await cubit.loadServants(actor: admin); // Populate cache
        final newServant = ServantModel(
          uid: 'new-uid',
          docID: 'temp',
          name: 'New Servant',
          phone: '01234567890',
          email: 'new@test.com',
          imageUrl: null,
          role: UserRole.servant,
          teamName: 'Team A',
          fatherOfConfession: 'Fr.',
          birthdate: null,
          notes: null,
        );
        await cubit.createServant(actor: admin, servant: newServant);
      },
      expect: () => [
        // from load
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>().having((s) => s.servants.length, 'count', 10),
        // from create optimistic
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>()
            .having((s) => s.servants.length, 'count', 11)
            .having(
              (s) => s.servants.any((x) => x.docID == 'new-doc'),
              'contains new doc',
              true,
            ),
        isA<ServantDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.createServant(any())).called(1);
        verify(() => mockRepository.getAllServants(limit: 200)).called(1);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'update always reloads list from server after successful write',
      build: () {
        when(
          () => mockRepository.updateServant(any()),
        ).thenAnswer((_) async {});
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      seed: () => ServantDataLoaded(servants: allServants),
      act: (cubit) async {
        await cubit.loadServants(actor: admin); // Populate cache
        final updatedServant = allServants.first.copyWith(
          name: 'Servant 0 Updated',
        );
        await cubit.updateServant(actor: admin, servant: updatedServant);
      },
      expect: () => [
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>(),
        isA<ServantDataLoading>(),
        // After update, list is reloaded from server (not optimistic)
        isA<ServantDataLoaded>().having((s) => s.servants.length, 'count', 10),
        isA<ServantDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.updateServant(any())).called(1);
        verify(
          () => mockRepository.getAllServants(limit: any(named: 'limit')),
        ).called(2);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'update reloads list from server after role change',
      build: () {
        when(
          () => mockRepository.updateServant(any()),
        ).thenAnswer((_) async {});
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      seed: () => ServantDataLoaded(servants: allServants),
      act: (cubit) async {
        await cubit.loadServants(actor: admin); // Populate cache
        final promoted = allServants.first.copyWith(role: UserRole.admin);
        await cubit.updateServant(actor: admin, servant: promoted);
      },
      expect: () => [
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>(),
        isA<ServantDataLoading>(),
        // List is reloaded from server, so it returns the original 10
        isA<ServantDataLoaded>().having((s) => s.servants.length, 'count', 10),
        isA<ServantDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.updateServant(any())).called(1);
        verify(
          () => mockRepository.getAllServants(limit: any(named: 'limit')),
        ).called(2);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'admin delete removes servant from list optimistically',
      build: () {
        when(
          () => mockRepository.deleteServant(any()),
        ).thenAnswer((_) async {});
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      seed: () => ServantDataLoaded(servants: allServants),
      act: (cubit) async {
        await cubit.loadServants(actor: admin); // Populate cache
        await cubit.deleteServant(actor: admin, docId: 'doc-0');
      },
      expect: () => [
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>(),
        isA<ServantDataLoading>(),
        isA<ServantDataLoaded>()
            .having((s) => s.servants.length, 'count', 9)
            .having(
              (s) => s.servants.any((x) => x.docID == 'doc-0'),
              'no longer contains deleted',
              false,
            ),
        isA<ServantDataOperationSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteServant('doc-0')).called(1);
      },
    );

    blocTest<ServantDataCubit, ServantDataState>(
      'emits error on repository exception',
      build: () {
        when(
          () => mockRepository.getAllServants(limit: any(named: 'limit')),
        ).thenThrow(Exception('Network error'));
        return ServantDataCubit(
          repository: mockRepository,
          authService: mockAuthService,
        );
      },
      act: (cubit) => cubit.loadServants(actor: admin),
      expect: () => [isA<ServantDataLoading>(), isA<ServantDataError>()],
    );
  });
}
