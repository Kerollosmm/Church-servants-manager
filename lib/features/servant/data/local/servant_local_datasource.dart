import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:hive/hive.dart';

/// Local Hive datasource for servants.
///
/// Provides a fast, offline-first cache for servant data and a
/// sync queue for mutations that need to be pushed to Firestore.
class ServantLocalDatasource {
  static const String boxName = 'servants_box';
  static const String syncQueueBoxName = 'servants_sync_queue_box';

  Box<ServantModel>? _servantsBox;
  Box<ServantModel>? _syncQueueBox;

  Future<void> init() async {
    _servantsBox ??= await Hive.openBox<ServantModel>(boxName);
    _syncQueueBox ??= await Hive.openBox<ServantModel>(syncQueueBoxName);
  }

  // ---- Cache Operations ----

  Future<void> cacheServant(ServantModel servant) async {
    await init();
    await _servantsBox!.put(servant.docID, servant);
  }

  Future<void> cacheServants(List<ServantModel> servants) async {
    await init();
    final entries = <String, ServantModel>{
      for (final s in servants) s.docID: s,
    };
    await _servantsBox!.putAll(entries);
  }

  Future<ServantModel?> getCachedServantById(String docId) async {
    await init();
    return _servantsBox!.get(docId);
  }

  /// Returns all cached servants, optionally filtering out archived ones.
  Future<List<ServantModel>> getCachedServants({
    bool includeArchived = false,
  }) async {
    await init();
    final all = _servantsBox!.values;
    if (includeArchived) return all.toList();
    return all.where((s) => !s.isArchived).toList();
  }

  /// Returns cached servants filtered by groupId (team name).
  Future<List<ServantModel>> getCachedServantsByGroup(
    String groupId, {
    bool includeArchived = false,
  }) async {
    await init();
    return _servantsBox!.values
        .where(
          (s) => s.teamName == groupId && (includeArchived || !s.isArchived),
        )
        .toList();
  }

  Future<void> removeCachedServant(String docId) async {
    await init();
    await _servantsBox!.delete(docId);
  }

  // ---- Sync Queue Operations ----

  Future<void> queueForSync(ServantModel servant) async {
    await init();
    await _syncQueueBox!.put(servant.docID, servant);
  }

  Future<void> removeFromSyncQueue(String docId) async {
    await init();
    await _syncQueueBox!.delete(docId);
  }

  Future<List<ServantModel>> getPendingSyncEntries() async {
    await init();
    return _syncQueueBox!.values.toList();
  }
}
