import 'package:church_management_system/features/student/data/models/pastoral_record_model.dart';
import 'package:hive/hive.dart';

class PastoralLocalDatasource {
  static const String boxName = 'pastoral_records_cache';

  Box<PastoralRecordModel>? _pastoralBox;
  Future<void>? _initFuture;

  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    _pastoralBox = await Hive.openBox<PastoralRecordModel>(
      boxName,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );
  }

  Future<void> savePastoralRecord(PastoralRecordModel record) async {
    await init();
    await _pastoralBox!.put(record.recordId, record);
  }

  Future<void> savePastoralRecords(List<PastoralRecordModel> records) async {
    await init();
    final map = {for (final r in records) r.recordId: r};
    await _pastoralBox!.putAll(map);
  }

  Future<List<PastoralRecordModel>> getCachedRecordsForStudent(
    String studentId,
  ) async {
    await init();
    final records = <PastoralRecordModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _pastoralBox!.keys) {
      try {
        final r = _pastoralBox!.get(key);
        if (r != null && r.studentId == studentId) {
          records.add(r);
        }
      } catch (_) {
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _pastoralBox!.deleteAll(corruptedKeys);
    }
    // Return sorted by createdAt descending
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<List<PastoralRecordModel>> getAllCachedRecords() async {
    await init();
    final records = <PastoralRecordModel>[];
    final corruptedKeys = <dynamic>[];
    for (final key in _pastoralBox!.keys) {
      try {
        final r = _pastoralBox!.get(key);
        if (r != null) {
          records.add(r);
        }
      } catch (_) {
        corruptedKeys.add(key);
      }
    }
    if (corruptedKeys.isNotEmpty) {
      await _pastoralBox!.deleteAll(corruptedKeys);
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }
}
