import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:hive/hive.dart';

/// Local Hive datasource for servants.
///
/// Provides a fast, offline-first cache for servant data and a
/// sync queue for mutations that need to be pushed to Firestore.
class ServantLocalDatasource {
  static const String boxName = 'servants_box';

  Box<ServantModel>? _servantsBox;

  Future<void> init() async {
    _servantsBox ??= await Hive.openBox<ServantModel>(
      boxName,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
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
    try {
      return _servantsBox!.get(docId);
    } catch (_) {
      // Corrupted entry – remove and return null.
      await _servantsBox!.delete(docId);
      return null;
    }
  }

  /// Returns all cached servants, optionally filtering out archived ones.
  Future<List<ServantModel>> getCachedServants({
    bool includeArchived = false,
  }) async {
    await init();
    final servants = <ServantModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _servantsBox!.keys) {
      try {
        final s = _servantsBox!.get(key);
        if (s != null) {
          if (includeArchived || !s.isArchived) {
            servants.add(s);
          }
        }
      } catch (_) {
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _servantsBox!.deleteAll(corruptedKeys);
    }
    return servants;
  }

  /// Returns cached servants filtered by groupId (team name).
  Future<List<ServantModel>> getCachedServantsByGroup(
    String groupId, {
    bool includeArchived = false,
  }) async {
    await init();
    final servants = <ServantModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _servantsBox!.keys) {
      try {
        final s = _servantsBox!.get(key);
        if (s != null && s.teamName == groupId) {
          if (includeArchived || !s.isArchived) {
            servants.add(s);
          }
        }
      } catch (_) {
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _servantsBox!.deleteAll(corruptedKeys);
    }
    return servants;
  }

  Future<void> removeCachedServant(String docId) async {
    await init();
    await _servantsBox!.delete(docId);
  }
}
