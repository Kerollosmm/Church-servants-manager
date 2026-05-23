import 'package:church_management_system/features/admin/data/models/analytics_summary_model.dart';

/// Contract for fetching sector-level analytics.
abstract class IAnalyticsRepository {
  /// Returns pre-aggregated analytics for [sectorId].
  ///
  /// When [forceRefresh] is `false` (default), serves cached data if it is
  /// less than 1 hour old. Pass `true` to bypass the cache.
  ///
  /// Throws [FirebaseException] if Firestore is unreachable and no stale
  /// cache is available.
  Future<AnalyticsSummaryModel> getSectorAnalytics(
    String sectorId, {
    bool forceRefresh = false,
  });
}
