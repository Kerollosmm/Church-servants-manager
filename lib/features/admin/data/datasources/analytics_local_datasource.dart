import 'package:church_management_system/features/admin/data/models/analytics_summary_model.dart';
import 'package:hive/hive.dart';

/// Local Hive storage for [AnalyticsSummaryModel] snapshots.
///
/// Follows the [StudentLocalDatasource] pattern: typed box with lazy init.
class AnalyticsLocalDatasource {
  static const String boxName = 'analytics_summary_box';

  late final Box<AnalyticsSummaryModel> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<AnalyticsSummaryModel>(
      boxName,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
    _initialized = true;
  }

  /// Returns the cached summary for [sectorId], or `null` if none exists.
  Future<AnalyticsSummaryModel?> getSummary(String sectorId) async {
    await init();
    return _box.get(sectorId);
  }

  /// Persists [model] keyed by its [AnalyticsSummaryModel.sectorId].
  Future<void> saveSummary(AnalyticsSummaryModel model) async {
    await init();
    await _box.put(model.sectorId, model);
  }

  /// Clears all cached analytics summaries.
  Future<void> clearAll() async {
    await init();
    await _box.clear();
  }
}
