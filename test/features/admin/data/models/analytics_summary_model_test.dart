import 'dart:io';

import 'package:church_management_system/features/admin/data/models/analytics_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('analytics_model_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(AnalyticsSummaryModelAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('AnalyticsSummaryModel', () {
    test('fromJson/toJson roundtrip preserves all fields', () {
      final original = AnalyticsSummaryModel(
        sectorId: 'sector-1',
        totalStudentsCount: 42,
        averageAttendanceRate: 0.85,
        pendingVisitationsCount: 3,
        topActiveServants: {'Alice': 10, 'Bob': 7},
        lastComputedAt: DateTime(2026, 5, 20, 10, 0),
        fetchedAt: DateTime(2026, 5, 20, 11, 0),
      );

      final json = original.toJson();
      final restored = AnalyticsSummaryModel.fromJson(json);

      expect(restored.sectorId, original.sectorId);
      expect(restored.totalStudentsCount, original.totalStudentsCount);
      expect(restored.averageAttendanceRate, original.averageAttendanceRate);
      expect(restored.pendingVisitationsCount, original.pendingVisitationsCount);
      expect(restored.topActiveServants, original.topActiveServants);
      expect(restored.lastComputedAt, original.lastComputedAt);
      expect(restored.fetchedAt, original.fetchedAt);
    });

    test('fromMap creates model with correct fields', () {
      final data = <String, dynamic>{
        'totalStudentsCount': 100,
        'averageAttendanceRate': 0.92,
        'pendingVisitationsCount': 5,
        'topActiveServants': {'John': 15, 'Jane': 12},
        'lastComputedAt': DateTime(2026, 5, 20, 9, 0).toIso8601String(),
      };

      final model = AnalyticsSummaryModel.fromMap(data, 'test-sector');

      expect(model.sectorId, 'test-sector');
      expect(model.totalStudentsCount, 100);
      expect(model.averageAttendanceRate, 0.92);
      expect(model.pendingVisitationsCount, 5);
      expect(model.topActiveServants, {'John': 15, 'Jane': 12});
      expect(model.fetchedAt, isNotNull);
    });

    test('toMap excludes fetchedAt field', () {
      final model = AnalyticsSummaryModel(
        sectorId: 'sector-1',
        totalStudentsCount: 42,
        averageAttendanceRate: 0.85,
        pendingVisitationsCount: 3,
        topActiveServants: {'Alice': 10},
        lastComputedAt: DateTime(2026, 5, 20, 10, 0),
        fetchedAt: DateTime(2026, 5, 20, 11, 0),
      );

      final map = model.toMap();

      expect(map.containsKey('fetchedAt'), isFalse);
      expect(map['totalStudentsCount'], 42);
      expect(map['averageAttendanceRate'], 0.85);
      expect(map['pendingVisitationsCount'], 3);
    });

    test('topActiveServantsTyped returns typed Map<String, int>', () {
      final model = AnalyticsSummaryModel(
        sectorId: 'sector-1',
        lastComputedAt: DateTime(2026, 5, 20, 10, 0),
        fetchedAt: DateTime(2026, 5, 20, 11, 0),
        topActiveServants: {'Alice': 10, 'Bob': 7},
      );

      final typed = model.topActiveServantsTyped;

      expect(typed, isA<Map<String, int>>());
      expect(typed['Alice'], 10);
      expect(typed['Bob'], 7);
    });

    test('default values are correct', () {
      final model = AnalyticsSummaryModel(
        sectorId: 'sector-1',
        lastComputedAt: DateTime(2026, 5, 20, 10, 0),
        fetchedAt: DateTime(2026, 5, 20, 11, 0),
      );

      expect(model.totalStudentsCount, 0);
      expect(model.averageAttendanceRate, 0.0);
      expect(model.pendingVisitationsCount, 0);
      expect(model.topActiveServants, isEmpty);
    });

    test('Hive serialization roundtrip preserves data', () async {
      final box = await Hive.openBox<AnalyticsSummaryModel>('test_model_box');

      final original = AnalyticsSummaryModel(
        sectorId: 'hive-sector',
        totalStudentsCount: 55,
        averageAttendanceRate: 0.78,
        pendingVisitationsCount: 2,
        topActiveServants: {'Servant1': 20, 'Servant2': 15},
        lastComputedAt: DateTime(2026, 5, 20, 10, 0),
        fetchedAt: DateTime(2026, 5, 20, 11, 0),
      );

      await box.put('hive-sector', original);
      final restored = box.get('hive-sector');

      expect(restored, isNotNull);
      expect(restored!.sectorId, original.sectorId);
      expect(restored.totalStudentsCount, original.totalStudentsCount);
      expect(restored.averageAttendanceRate, original.averageAttendanceRate);
      expect(restored.pendingVisitationsCount, original.pendingVisitationsCount);
      expect(restored.topActiveServants, original.topActiveServants);
      expect(restored.lastComputedAt, original.lastComputedAt);
      expect(restored.fetchedAt, original.fetchedAt);

      await box.close();
    });
  });
}
