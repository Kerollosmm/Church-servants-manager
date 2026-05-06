import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:hive/hive.dart';

class ServantLocalDatasource {
  static const String boxName = 'servants_box';
  static const String syncQueueBoxName = 'servants_sync_queue_box';

  Box<dynamic>? _servantsBox;
  Box<dynamic>? _syncQueueBox;

  Future<void> init() async {
    _servantsBox ??= await Hive.openBox(boxName);
    _syncQueueBox ??= await Hive.openBox(syncQueueBoxName);
  }

  Future<void> saveServant(ServantModel servant) async {
    await init();
    await _servantsBox!.put(servant.docID, servant.toMap());
  }

  Future<ServantModel?> getServant(String docId) async {
    await init();
    final data = _servantsBox!.get(docId);
    if (data != null) {
      final map = Map<String, dynamic>.from(data as Map);
      return ServantModel.fromMap(map, docId);
    }
    return null;
  }

  Future<void> queueForSync(ServantModel servant) async {
    await init();
    await _syncQueueBox!.put(servant.docID, servant.toMap());
  }

  Future<void> removeFromSyncQueue(String docId) async {
    await init();
    await _syncQueueBox!.delete(docId);
  }

  /// Saves multiple servants to the local cache in a single pass.
  Future<void> saveServants(List<ServantModel> servants) async {
    await init();
    for (final servant in servants) {
      await _servantsBox!.put(servant.docID, servant.toMap());
    }
  }

  /// Returns all cached servants from the local box.
  List<ServantModel> getAllCachedServants() {
    if (_servantsBox == null || !_servantsBox!.isOpen) return [];
    final servants = <ServantModel>[];
    for (final key in _servantsBox!.keys) {
      final data = _servantsBox!.get(key);
      if (data == null) continue;
      try {
        final map = Map<String, dynamic>.from(data as Map);
        servants.add(ServantModel.fromMap(map, key as String));
      } catch (_) {
        continue;
      }
    }
    return servants;
  }

  /// Returns all servants pending Firestore sync.
  List<ServantModel> getPendingSyncQueue() {
    if (_syncQueueBox == null || !_syncQueueBox!.isOpen) return [];
    final servants = <ServantModel>[];
    for (final key in _syncQueueBox!.keys) {
      final data = _syncQueueBox!.get(key);
      if (data == null) continue;
      try {
        final map = Map<String, dynamic>.from(data as Map);
        servants.add(ServantModel.fromMap(map, key as String));
      } catch (_) {
        continue;
      }
    }
    return servants;
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
