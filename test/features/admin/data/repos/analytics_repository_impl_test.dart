import 'package:church_management_system/features/admin/data/datasources/analytics_local_datasource.dart';
import 'package:church_management_system/features/admin/data/models/analytics_summary_model.dart';
import 'package:church_management_system/features/admin/data/repos/analytics_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockAnalyticsLocalDatasource extends Mock
    implements AnalyticsLocalDatasource {}

class FakeAnalyticsSummaryModel extends Fake
    implements AnalyticsSummaryModel {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockAnalyticsLocalDatasource mockLocalDatasource;
  late AnalyticsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeAnalyticsSummaryModel());
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockLocalDatasource = MockAnalyticsLocalDatasource();
    repository = AnalyticsRepositoryImpl(
      firestore: mockFirestore,
      localDatasource: mockLocalDatasource,
    );
  });

  AnalyticsSummaryModel buildSummary({
    String sectorId = 'sector-1',
    int totalStudentsCount = 42,
    double averageAttendanceRate = 0.85,
    int pendingVisitationsCount = 3,
    Map<String, dynamic> topActiveServants = const {'Alice': 10},
    DateTime? lastComputedAt,
    DateTime? fetchedAt,
  }) {
    return AnalyticsSummaryModel(
      sectorId: sectorId,
      totalStudentsCount: totalStudentsCount,
      averageAttendanceRate: averageAttendanceRate,
      pendingVisitationsCount: pendingVisitationsCount,
      topActiveServants: topActiveServants,
      lastComputedAt: lastComputedAt ?? DateTime(2026, 5, 20, 10, 0),
      fetchedAt: fetchedAt ?? DateTime(2026, 5, 20, 11, 0),
    );
  }

  group('AnalyticsRepositoryImpl', () {
    test('returns cached data when cache is fresh (< 1 hour)', () async {
      final freshSummary = buildSummary(
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      when(() => mockLocalDatasource.getSummary('sector-1'))
          .thenAnswer((_) async => freshSummary);

      final result = await repository.getSectorAnalytics('sector-1');

      expect(result.sectorId, 'sector-1');
      expect(result.totalStudentsCount, 42);
      verifyNever(() => mockFirestore.collection(any()));
    });

    test('fetches from Firestore when cache is stale (> 1 hour)', () async {
      final staleSummary = buildSummary(
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      when(() => mockLocalDatasource.getSummary('sector-1'))
          .thenAnswer((_) async => staleSummary);

      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = MockDocumentSnapshot();

      when(() => mockFirestore.collection('SectorsAnalytics'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('sector-1')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(true);
      when(() => mockDocSnap.id).thenReturn('sector-1');
      when(() => mockDocSnap.data()).thenReturn({
        'totalStudentsCount': 100,
        'averageAttendanceRate': 0.92,
        'pendingVisitationsCount': 5,
        'topActiveServants': <String, dynamic>{'John': 15},
        'lastComputedAt': DateTime(2026, 5, 21, 9, 0).toIso8601String(),
      });

      when(() => mockLocalDatasource.saveSummary(any()))
          .thenAnswer((_) async {});

      final result = await repository.getSectorAnalytics('sector-1');

      expect(result.totalStudentsCount, 100);
      expect(result.averageAttendanceRate, 0.92);
      verify(() => mockFirestore.collection('SectorsAnalytics')).called(1);
      verify(() => mockLocalDatasource.saveSummary(any())).called(1);
    });

    test('fetches from Firestore when cache is empty', () async {
      when(() => mockLocalDatasource.getSummary('sector-1'))
          .thenAnswer((_) async => null);

      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = MockDocumentSnapshot();

      when(() => mockFirestore.collection('SectorsAnalytics'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('sector-1')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(true);
      when(() => mockDocSnap.id).thenReturn('sector-1');
      when(() => mockDocSnap.data()).thenReturn({
        'totalStudentsCount': 50,
        'averageAttendanceRate': 0.75,
        'pendingVisitationsCount': 2,
        'topActiveServants': <String, dynamic>{},
        'lastComputedAt': DateTime(2026, 5, 21, 8, 0).toIso8601String(),
      });

      when(() => mockLocalDatasource.saveSummary(any()))
          .thenAnswer((_) async {});

      final result = await repository.getSectorAnalytics('sector-1');

      expect(result.totalStudentsCount, 50);
      expect(result.sectorId, 'sector-1');
    });

    test('saves fetched data with updated fetchedAt', () async {
      when(() => mockLocalDatasource.getSummary('sector-1'))
          .thenAnswer((_) async => null);

      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = MockDocumentSnapshot();

      when(() => mockFirestore.collection('SectorsAnalytics'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('sector-1')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(true);
      when(() => mockDocSnap.id).thenReturn('sector-1');
      when(() => mockDocSnap.data()).thenReturn({
        'totalStudentsCount': 50,
        'averageAttendanceRate': 0.75,
        'pendingVisitationsCount': 2,
        'topActiveServants': <String, dynamic>{},
        'lastComputedAt': DateTime(2026, 5, 21, 8, 0).toIso8601String(),
      });

      AnalyticsSummaryModel? savedModel;
      when(() => mockLocalDatasource.saveSummary(any())).thenAnswer((invocation) async {
        savedModel = invocation.positionalArguments[0] as AnalyticsSummaryModel;
      });

      await repository.getSectorAnalytics('sector-1');

      expect(savedModel, isNotNull);
      expect(savedModel!.fetchedAt, isNotNull);
      // fetchedAt should be recent (within last minute)
      expect(
        DateTime.now().difference(savedModel!.fetchedAt).inMinutes,
        lessThan(1),
      );
    });

    test('returns stale cache when Firestore fails', () async {
      final staleSummary = buildSummary(
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
        totalStudentsCount: 99,
      );

      when(() => mockLocalDatasource.getSummary('sector-1'))
          .thenAnswer((_) async => staleSummary);

      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();

      when(() => mockFirestore.collection('SectorsAnalytics'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('sector-1')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', message: 'Network error'),
      );

      final result = await repository.getSectorAnalytics('sector-1');

      expect(result.totalStudentsCount, 99);
      expect(result.sectorId, 'sector-1');
    });

    test('throws when Firestore fails and no cache exists', () async {
      when(() => mockLocalDatasource.getSummary('sector-1'))
          .thenAnswer((_) async => null);

      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();

      when(() => mockFirestore.collection('SectorsAnalytics'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('sector-1')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', message: 'Network error'),
      );

      expect(
        () => repository.getSectorAnalytics('sector-1'),
        throwsA(isA<FirebaseException>()),
      );
    });

    test('bypasses cache when forceRefresh is true', () async {
      final freshSummary = buildSummary(
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      when(() => mockLocalDatasource.getSummary('sector-1'))
          .thenAnswer((_) async => freshSummary);

      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = MockDocumentSnapshot();

      when(() => mockFirestore.collection('SectorsAnalytics'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('sector-1')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(true);
      when(() => mockDocSnap.id).thenReturn('sector-1');
      when(() => mockDocSnap.data()).thenReturn({
        'totalStudentsCount': 200,
        'averageAttendanceRate': 0.95,
        'pendingVisitationsCount': 1,
        'topActiveServants': <String, dynamic>{},
        'lastComputedAt': DateTime(2026, 5, 21, 10, 0).toIso8601String(),
      });

      when(() => mockLocalDatasource.saveSummary(any()))
          .thenAnswer((_) async {});

      final result = await repository.getSectorAnalytics(
        'sector-1',
        forceRefresh: true,
      );

      expect(result.totalStudentsCount, 200);
      verify(() => mockFirestore.collection('SectorsAnalytics')).called(1);
    });

    test('uses correct Firestore collection path', () async {
      when(() => mockLocalDatasource.getSummary('sector-abc'))
          .thenAnswer((_) async => null);

      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = MockDocumentSnapshot();

      when(() => mockFirestore.collection('SectorsAnalytics'))
          .thenReturn(mockCollection);
      when(() => mockCollection.doc('sector-abc')).thenReturn(mockDocRef);
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(true);
      when(() => mockDocSnap.id).thenReturn('sector-abc');
      when(() => mockDocSnap.data()).thenReturn({
        'totalStudentsCount': 10,
        'averageAttendanceRate': 0.5,
        'pendingVisitationsCount': 0,
        'topActiveServants': <String, dynamic>{},
        'lastComputedAt': DateTime(2026, 5, 21, 7, 0).toIso8601String(),
      });

      when(() => mockLocalDatasource.saveSummary(any()))
          .thenAnswer((_) async {});

      await repository.getSectorAnalytics('sector-abc');

      verify(() => mockFirestore.collection('SectorsAnalytics')).called(1);
      verify(() => mockCollection.doc('sector-abc')).called(1);
    });
  });
}
