import 'package:flutter/foundation.dart';

/// Pre-aggregated domain entity for sector-level analytics.
@immutable
class AnalyticsSummary {
  /// Sector document ID.
  final String sectorId;

  /// Total students enrolled in this sector.
  final int totalStudentsCount;

  /// Average attendance rate (0.0 – 1.0).
  final double averageAttendanceRate;

  /// Number of pending pastoral visitations.
  final int pendingVisitationsCount;

  /// Top active servants as `{servantName: sessionCount}`.
  final Map<String, int> topActiveServants;

  /// When these stats were last computed server-side.
  final DateTime lastComputedAt;

  /// Client-side timestamp for cooldown enforcement.
  final DateTime fetchedAt;

  const AnalyticsSummary({
    required this.sectorId,
    this.totalStudentsCount = 0,
    this.averageAttendanceRate = 0.0,
    this.pendingVisitationsCount = 0,
    this.topActiveServants = const {},
    required this.lastComputedAt,
    required this.fetchedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSummary &&
          runtimeType == other.runtimeType &&
          sectorId == other.sectorId &&
          totalStudentsCount == other.totalStudentsCount &&
          averageAttendanceRate == other.averageAttendanceRate &&
          pendingVisitationsCount == other.pendingVisitationsCount &&
          lastComputedAt == other.lastComputedAt &&
          fetchedAt == other.fetchedAt;

  @override
  int get hashCode =>
      sectorId.hashCode ^
      totalStudentsCount.hashCode ^
      averageAttendanceRate.hashCode ^
      pendingVisitationsCount.hashCode ^
      lastComputedAt.hashCode ^
      fetchedAt.hashCode;
}
