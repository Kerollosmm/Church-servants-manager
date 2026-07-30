import 'package:church_management_system/features/admin/data/models/analytics_summary_model.dart';
import 'package:church_management_system/features/admin/domain/entities/analytics_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();

  final model = AnalyticsSummaryModel(
    sectorId: 'sector-100',
    totalStudentsCount: 42,
    averageAttendanceRate: 0.85,
    pendingVisitationsCount: 3,
    topActiveServants: const {'Servant A': 12, 'Servant B': 8},
    lastComputedAt: now,
    fetchedAt: now,
  );

  group('AnalyticsSummary & Model Mapping Tests', () {
    test('toDomain maps model attributes correctly to domain entity', () {
      final domain = model.toDomain();

      expect(domain.sectorId, equals('sector-100'));
      expect(domain.totalStudentsCount, equals(42));
      expect(domain.averageAttendanceRate, equals(0.85));
      expect(domain.pendingVisitationsCount, equals(3));
      expect(
        domain.topActiveServants,
        equals({'Servant A': 12, 'Servant B': 8}),
      );
      expect(domain.lastComputedAt, equals(now));
      expect(domain.fetchedAt, equals(now));
    });

    test('fromDomain converts domain entity back to data model', () {
      final domain = AnalyticsSummary(
        sectorId: 'sector-200',
        totalStudentsCount: 15,
        averageAttendanceRate: 0.90,
        pendingVisitationsCount: 1,
        topActiveServants: const {'Servant C': 5},
        lastComputedAt: now,
        fetchedAt: now,
      );

      final convertedModel = AnalyticsSummaryModel.fromDomain(domain);

      expect(convertedModel.sectorId, equals('sector-200'));
      expect(convertedModel.totalStudentsCount, equals(15));
      expect(convertedModel.averageAttendanceRate, equals(0.90));
      expect(convertedModel.pendingVisitationsCount, equals(1));
      expect(convertedModel.topActiveServants, equals({'Servant C': 5}));
    });
  });
}
