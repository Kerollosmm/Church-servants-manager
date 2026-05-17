import 'dart:convert';
import 'dart:developer' as developer;

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:hive/hive.dart';

/// Result of a pruning operation across all boxes.
class PruneResult {
  final int totalPruned;
  final Map<String, int> perBox;

  const PruneResult({required this.totalPruned, required this.perBox});
}

/// Deletes synced Hive entries older than a configurable age (default 30 days).
///
/// Run on app startup or as a periodic maintenance task.
class HivePruningService {
  static const Duration _defaultMaxAge = Duration(days: 30);

  /// Prunes the typed [SyncEntry] queue box.
  Future<int> pruneSyncQueue({Duration maxAge = _defaultMaxAge}) async {
    final box = Hive.box<SyncEntry>('sync_queue_box');
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = <String>[];

    for (final entry in box.values) {
      if (entry.createdAt.isBefore(cutoff)) {
        toRemove.add(entry.id);
      }
    }

    if (toRemove.isNotEmpty) {
      await box.deleteAll(toRemove);
      developer.log(
        'Pruned ${toRemove.length} entries from sync_queue_box',
        name: 'HivePruningService',
      );
    }
    return toRemove.length;
  }

  /// Prunes a generic String box where entries contain a timestamp field.
  Future<int> pruneStringBox({
    required String boxName,
    Duration maxAge = _defaultMaxAge,
    required DateTime? Function(String json) timestampExtractor,
  }) async {
    final box = Hive.box<String>(boxName);
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = <String>[];

    for (final key in box.keys) {
      final value = box.get(key);
      if (value == null) continue;

      final timestamp = timestampExtractor(value);
      if (timestamp != null && timestamp.isBefore(cutoff)) {
        toRemove.add(key.toString());
      }
    }

    if (toRemove.isNotEmpty) {
      await box.deleteAll(toRemove);
      developer.log(
        'Pruned ${toRemove.length} entries from $boxName',
        name: 'HivePruningService',
      );
    }
    return toRemove.length;
  }

  /// Runs pruning across all known cache boxes.
  Future<PruneResult> pruneAll({Duration maxAge = _defaultMaxAge}) async {
    final perBox = <String, int>{};

    perBox['sync_queue_box'] = await pruneSyncQueue(maxAge: maxAge);

    if (Hive.isBoxOpen('attendance_marks_cache') ||
        await Hive.boxExists('attendance_marks_cache')) {
      perBox['attendance_marks_cache'] = await pruneStringBox(
        boxName: 'attendance_marks_cache',
        maxAge: maxAge,
        timestampExtractor: _extractCachedAt,
      );
    }

    if (Hive.isBoxOpen('attendance_sessions_cache_box') ||
        await Hive.boxExists('attendance_sessions_cache_box')) {
      perBox['attendance_sessions_cache_box'] = await pruneStringBox(
        boxName: 'attendance_sessions_cache_box',
        maxAge: maxAge,
        timestampExtractor: _extractCachedAt,
      );
    }

    final total = perBox.values.fold(0, (sum, v) => sum + v);
    developer.log(
      'Pruning complete: $total entries removed across ${perBox.length} boxes',
      name: 'HivePruningService',
    );
    return PruneResult(totalPruned: total, perBox: perBox);
  }

  DateTime? _extractCachedAt(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final cachedAt = map['cachedAt'];
      if (cachedAt is String) return DateTime.tryParse(cachedAt);
      return null;
    } catch (_) {
      return null;
    }
  }
}
