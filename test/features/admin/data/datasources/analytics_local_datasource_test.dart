import 'dart:io';

import 'package:church_management_system/features/admin/data/datasources/analytics_local_datasource.dart';
import 'package:church_management_system/features/admin/data/models/analytics_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Helper to build a test [AnalyticsSummaryModel] with sensible defaults.
AnalyticsSummaryModel buildTestSummary({
  String sectorId = 'sector-1',
  int totalStudentsCount = 42,
  double averageAttendanceRate = 0.85,
  int pendingVisitationsCount = 3,
  Map<String, dynamic> topActiveServants = const {'Alice': 10, 'Bob': 7},
  DateTime? lastComputedAt,
  DateTime? fetchedAt,
}) {
  return AnalyticsSummaryModel(
    sectorId: sectorId,
    totalStudentsCount: totalStudentsCount,
    averageAttendanceRate: averageAttendanceRate,
    pendingVisitationsCount: pendingVisitationsCount,
    topActiveServants: topActiveServants,
    lastComputedAt: lastComputedAt ?? DateTime(2026, 5, 20, 10),
    fetchedAt: fetchedAt ?? DateTime(2026, 5, 20, 11),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('analytics_ds_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(AnalyticsSummaryModelAdapter());
    }
  });

  tearDown(() async {
    // Clear box data between tests so each test starts clean.
    if (Hive.isBoxOpen(AnalyticsLocalDatasource.boxName)) {
      final box = Hive.box<AnalyticsSummaryModel>(
        AnalyticsLocalDatasource.boxName,
      );
      await box.clear();
    }
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('AnalyticsLocalDatasource', () {
    late AnalyticsLocalDatasource datasource;

    setUp(() {
      datasource = AnalyticsLocalDatasource();
    });

    test('getSummary returns null when no data exists', () async {
      final result = await datasource.getSummary('nonexistent-sector');
      expect(result, isNull);
    });

    test('saveSummary persists model keyed by sectorId', () async {
      final model = buildTestSummary(sectorId: 'sector-abc');

      await datasource.saveSummary(model);

      // Open the box directly to verify the key exists.
      final box = Hive.box<AnalyticsSummaryModel>(
        AnalyticsLocalDatasource.boxName,
      );
      expect(box.containsKey('sector-abc'), isTrue);
      expect(box.get('sector-abc')!.sectorId, 'sector-abc');
      expect(box.get('sector-abc')!.totalStudentsCount, 42);
    });

    test('getSummary returns saved model after saveSummary', () async {
      final model = buildTestSummary(
        sectorId: 'sector-xyz',
        totalStudentsCount: 99,
        averageAttendanceRate: 0.73,
        pendingVisitationsCount: 5,
      );

      await datasource.saveSummary(model);
      final result = await datasource.getSummary('sector-xyz');

      expect(result, isNotNull);
      expect(result!.sectorId, 'sector-xyz');
      expect(result.totalStudentsCount, 99);
      expect(result.averageAttendanceRate, 0.73);
      expect(result.pendingVisitationsCount, 5);
      expect(result.lastComputedAt, DateTime(2026, 5, 20, 10));
      expect(result.fetchedAt, DateTime(2026, 5, 20, 11));
    });

    test('saveSummary overwrites existing model for same sectorId', () async {
      final original = buildTestSummary(
        totalStudentsCount: 10,
        averageAttendanceRate: 0.5,
      );
      final updated = buildTestSummary(
        totalStudentsCount: 200,
        averageAttendanceRate: 0.95,
      );

      await datasource.saveSummary(original);
      await datasource.saveSummary(updated);
      final result = await datasource.getSummary('sector-1');

      expect(result, isNotNull);
      expect(result!.totalStudentsCount, 200);
      expect(result.averageAttendanceRate, 0.95);
      // Verify only one entry for this key.
      final box = Hive.box<AnalyticsSummaryModel>(
        AnalyticsLocalDatasource.boxName,
      );
      expect(box.length, 1);
    });

    test('clearAll removes all cached summaries', () async {
      await datasource.saveSummary(buildTestSummary(sectorId: 's1'));
      await datasource.saveSummary(buildTestSummary(sectorId: 's2'));
      await datasource.saveSummary(buildTestSummary(sectorId: 's3'));

      final box = Hive.box<AnalyticsSummaryModel>(
        AnalyticsLocalDatasource.boxName,
      );
      expect(box.length, 3);

      await datasource.clearAll();

      expect(box.isEmpty, isTrue);
      expect(await datasource.getSummary('s1'), isNull);
      expect(await datasource.getSummary('s2'), isNull);
      expect(await datasource.getSummary('s3'), isNull);
    });

    test('init is idempotent (calling twice does not throw)', () async {
      // init() is called internally on every operation.
      // Calling it explicitly twice should be safe.
      await datasource.init();
      await datasource.init(); // Should not throw.

      // Verify the datasource is still functional.
      final result = await datasource.getSummary('any-key');
      expect(result, isNull);
    });
  });
}
