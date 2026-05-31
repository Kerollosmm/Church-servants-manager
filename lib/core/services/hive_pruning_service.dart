import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:hive/hive.dart';

/// Result of a pruning operation across all boxes.
class PruneResult {
  final int totalPruned;
  final Map<String, int> perBox;

  const PruneResult({required this.totalPruned, required this.perBox});
}

/// Prunes Hive cache entries older than a configurable age (default 30 days).
///
/// Old sync queue entries are moved to [DeadLetterQueue] rather than deleted,
/// preserving them for inspection. Cache-only boxes (attendance marks/sessions)
/// are hard-deleted since they are replicas of Firestore data.
///
/// Run on app startup or as a periodic maintenance task.
class HivePruningService {
  static const Duration _defaultMaxAge = Duration(days: 30);

  final DeadLetterQueue _dlq;

  HivePruningService({required DeadLetterQueue deadLetterQueue})
    : _dlq = deadLetterQueue;

  /// Moves old sync queue entries to DLQ instead of deleting them.
  Future<int> pruneSyncQueue({Duration maxAge = _defaultMaxAge}) async {
    int totalPruned = 0;
    final List<String> syncBoxNames = [];

    final path = (Hive as dynamic).homePath as String?;
    if (path != null) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        final discovered = dir
            .listSync()
            .whereType<File>()
            .map((file) {
              final name = file.path.split(Platform.pathSeparator).last;
              if (name.endsWith('.hive')) {
                return name.substring(0, name.length - 5);
              } else if (name.endsWith('.hivec')) {
                return name.substring(0, name.length - 6);
              }
              return null;
            })
            .whereType<String>()
            .where((name) => name.startsWith('sync_queue_'))
            .toList();
        syncBoxNames.addAll(discovered);
      }
    }

    if (syncBoxNames.isEmpty) {
      developer.log(
        'No sync_queue_ boxes found on disk, skipping prune',
        name: 'HivePruningService',
      );
      return 0;
    }

    for (final boxName in syncBoxNames) {
      final wasOpen = Hive.isBoxOpen(boxName);
      final Box<SyncEntry> box = wasOpen
          ? Hive.box<SyncEntry>(boxName)
          : await Hive.openBox<SyncEntry>(boxName);

      final cutoff = DateTime.now().subtract(maxAge);
      final toMove = <SyncEntry>[];

      for (final entry in box.values) {
        if (entry.createdAt.isBefore(cutoff)) {
          toMove.add(entry);
        }
      }

      if (toMove.isNotEmpty) {
        for (final entry in toMove) {
          await box.delete(entry.id);
          await _dlq.add(entry);
        }
        developer.log(
          'Moved ${toMove.length} expired entries from $boxName to DLQ',
          name: 'HivePruningService',
        );
        totalPruned += toMove.length;
      }

      if (!wasOpen) {
        await box.close();
      }
    }
    return totalPruned;
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

    // Prune old DLQ entries
    perBox['dead_letter_queue'] = await _dlq.pruneOlderThan(maxAge);

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
