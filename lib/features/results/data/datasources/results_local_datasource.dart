import 'package:church_management_system/features/results/data/models/results_model.dart';
import 'package:hive/hive.dart';

/// Local Hive datasource for results.
///
/// Provides a fast, offline-first cache for results data.
class ResultsLocalDatasource {
  static const String boxName = 'results_cache_box';

  Box<ResultsModel>? _resultsBox;

  Future<void> init() async {
    _resultsBox ??= await Hive.openBox<ResultsModel>(boxName);
  }

  // ---- Cache Operations ----

  Future<void> cacheResult(String docId, ResultsModel result) async {
    await init();
    await _resultsBox!.put(docId, result);
  }

  Future<void> cacheResults(Map<String, ResultsModel> resultsMap) async {
    await init();
    await _resultsBox!.putAll(resultsMap);
  }

  Future<ResultsModel?> getCachedResultForStudent(String studentId) async {
    await init();
    // Assuming we want the latest or a specific term...
    // Here we just find the first match or we should match term.
    // For now we'll match just studentId as a fallback.
    try {
      return _resultsBox!.values.firstWhere((r) => r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  /// Returns cached results filtered by groupId.
  Future<List<ResultsModel>> getCachedResultsForGroup(String groupId) async {
    await init();
    return _resultsBox!.values.where((r) => r.groupId == groupId).toList();
  }
}
