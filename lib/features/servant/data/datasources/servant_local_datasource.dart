import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:hive/hive.dart';

class ServantLocalDatasource {
  static const String boxName = 'servants_box';
  static const String syncQueueBoxName = 'servants_sync_queue_box';

  Box<ServantModel>? _servantsBox;
  Box<ServantModel>? _syncQueueBox;

  Future<void> init() async {
    _servantsBox ??= await Hive.openBox<ServantModel>(boxName);
    _syncQueueBox ??= await Hive.openBox<ServantModel>(syncQueueBoxName);
  }

  Future<void> saveServant(ServantModel servant) async {
    await init();
    await _servantsBox!.put(servant.docID, servant);
  }

  Future<ServantModel?> getServant(String docId) async {
    await init();
    return _servantsBox!.get(docId);
  }

  Future<void> queueForSync(ServantModel servant) async {
    await init();
    await _syncQueueBox!.put(servant.docID, servant);
  }

  Future<void> removeFromSyncQueue(String docId) async {
    await init();
    await _syncQueueBox!.delete(docId);
  }

  /// Saves multiple servants to the local cache in a single pass.
  Future<void> saveServants(List<ServantModel> servants) async {
    await init();
    final Map<String, ServantModel> map = {
      for (final s in servants) s.docID: s,
    };
    await _servantsBox!.putAll(map);
  }

  /// Returns all cached servants from the local box.
  List<ServantModel> getAllCachedServants() {
    if (_servantsBox == null || !_servantsBox!.isOpen) return [];
    return _servantsBox!.values.toList();
  }

  /// Returns all servants pending Firestore sync.
  List<ServantModel> getPendingSyncQueue() {
    if (_syncQueueBox == null || !_syncQueueBox!.isOpen) return [];
    return _syncQueueBox!.values.toList();
  }

  /// Clears the entire servant cache.
  Future<void> clearCache() async {
    await init();
    await _servantsBox!.clear();
  }

  /// Clears the entire sync queue.
  Future<void> clearSyncQueue() async {
    await init();
    await _syncQueueBox!.clear();
  }
}
