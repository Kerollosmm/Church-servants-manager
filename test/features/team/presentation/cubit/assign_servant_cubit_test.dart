import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/team/presentation/cubit/assign_servant_cubit.dart';
import 'package:church_management_system/features/team/presentation/cubit/assign_servant_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockServantRepository extends Mock implements IServantRepository {}

void main() {
  late MockServantRepository mockRepository;
  late AssignServantCubit cubit;

  final servantA = ServantModel(docID: 's1', name: 'Servant A');
  final servantB = ServantModel(docID: 's2', name: 'Servant B');
  final servantADuplicate = ServantModel(docID: 's1', name: 'Servant A Copy');

  setUp(() {
    mockRepository = MockServantRepository();
    cubit = AssignServantCubit(servantRepository: mockRepository);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('AssignServantCubit', () {
    test('initial state is AssignServantInitial', () {
      expect(cubit.state, isA<AssignServantInitial>());
    });

    test('loadServants emits [loading, loaded] on success', () async {
      when(
        () => mockRepository.getServantsByGroupWithFallback(
          'group1',
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer(
        (_) async => (servants: [servantA, servantB], isFromCache: false),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AssignServantLoading>(),
          isA<AssignServantLoaded>().having(
            (s) => s.servants.length,
            'count',
            2,
          ),
        ]),
      );

      await cubit.loadServants('group1');
      await expectation;
    });

    test('loadServants emits [loading, error] on failure', () async {
      when(
        () => mockRepository.getServantsByGroupWithFallback(
          'group1',
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenThrow(Exception('network error'));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AssignServantLoading>(),
          isA<AssignServantError>().having(
            (s) => s.message,
            'message',
            contains('network error'),
          ),
        ]),
      );

      await cubit.loadServants('group1');
      await expectation;
    });

    test('loadServants deduplicates servants by docID', () async {
      when(
        () => mockRepository.getServantsByGroupWithFallback(
          'group1',
          includeArchived: any(named: 'includeArchived'),
        ),
      ).thenAnswer(
        (_) async => (
          servants: [servantA, servantADuplicate, servantB],
          isFromCache: false,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AssignServantLoading>(),
          isA<AssignServantLoaded>().having(
            (s) => s.servants.length,
            'deduplicated count',
            2,
          ),
        ]),
      );

      await cubit.loadServants('group1');
      await expectation;
    });

    test('normalizeSelectedId returns null for non-existent id', () {
      final result = cubit.normalizeSelectedId('missing', [servantA, servantB]);
      expect(result, isNull);
    });

    test('normalizeSelectedId returns id when it exists', () {
      final result = cubit.normalizeSelectedId('s1', [servantA, servantB]);
      expect(result, 's1');
    });

    test('normalizeSelectedId returns null for null input', () {
      final result = cubit.normalizeSelectedId(null, [servantA, servantB]);
      expect(result, isNull);
    });

    test('findServant returns matching servant', () {
      final result = cubit.findServant([servantA, servantB], 's2');
      expect(result, servantB);
    });

    test('findServant returns null for non-existent id', () {
      final result = cubit.findServant([servantA, servantB], 'missing');
      expect(result, isNull);
    });

    test('findServant returns null for null id', () {
      final result = cubit.findServant([servantA, servantB], null);
      expect(result, isNull);
    });
  });
}
