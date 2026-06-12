import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/features/attendance/data/local/mark_sync_entry.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
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

  /// Prunes a generic box where entries contain a timestamp field.
  Future<int> pruneStringBox({
    required String boxName,
    Duration maxAge = _defaultMaxAge,
    required DateTime? Function(Object val) timestampExtractor,
  }) async {
    final wasOpen = Hive.isBoxOpen(boxName);
    final box = await _getOrOpenBox(boxName);
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = <dynamic>[];

    for (final key in box.keys) {
      final value = box.get(key);
      if (value == null) continue;

      final timestamp = timestampExtractor(value);
      if (timestamp != null && timestamp.isBefore(cutoff)) {
        toRemove.add(key);
      }
    }

    if (toRemove.isNotEmpty) {
      await box.deleteAll(toRemove);
      developer.log(
        'Pruned ${toRemove.length} entries from $boxName',
        name: 'HivePruningService',
      );
    }

    if (!wasOpen) {
      await box.close();
    }
    return toRemove.length;
  }

  /// Opens or retrieves a box using the correct type parameter to prevent Hive type mismatch errors.
  Future<Box> _getOrOpenBox(String boxName) async {
    final wasOpen = Hive.isBoxOpen(boxName);
    if (boxName == 'attendance_marks_v2') {
      return wasOpen
          ? Hive.box<AttendanceMark>(boxName)
          : await Hive.openBox<AttendanceMark>(boxName);
    } else if (boxName == 'attendance_marks_sync_queue_v2') {
      return wasOpen
          ? Hive.box<MarkSyncEntry>(boxName)
          : await Hive.openBox<MarkSyncEntry>(boxName);
    } else if (boxName == 'attendance_sessions_cache_box') {
      return wasOpen
          ? Hive.box<AttendanceSessionModel>(boxName)
          : await Hive.openBox<AttendanceSessionModel>(boxName);
    } else if (boxName == 'attendance_marks_cache') {
      return wasOpen
          ? Hive.box<String>(boxName)
          : await Hive.openBox<String>(boxName);
    } else {
      return wasOpen
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
    }
  }

  /// Runs pruning across all known cache boxes.
  Future<PruneResult> pruneAll({Duration maxAge = _defaultMaxAge}) async {
    final perBox = <String, int>{};

    perBox['sync_queue_box'] = await pruneSyncQueue(maxAge: maxAge);

    if (Hive.isBoxOpen('attendance_marks_v2') ||
        await Hive.boxExists('attendance_marks_v2')) {
      perBox['attendance_marks_v2'] = await pruneStringBox(
        boxName: 'attendance_marks_v2',
        maxAge: maxAge,
        timestampExtractor: _extractCachedAt,
      );
    }

    if (Hive.isBoxOpen('attendance_marks_sync_queue_v2') ||
        await Hive.boxExists('attendance_marks_sync_queue_v2')) {
      perBox['attendance_marks_sync_queue_v2'] = await pruneStringBox(
        boxName: 'attendance_marks_sync_queue_v2',
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

  DateTime? _extractCachedAt(Object val) {
    if (val is String) {
      try {
        final map = jsonDecode(val) as Map<String, Object?>;
        final cachedAt = map['cachedAt'] ?? map['updatedAt'] ?? map['createdAt'] ?? map['queuedAt'] ?? map['markedAt'];
        if (cachedAt is String) return DateTime.tryParse(cachedAt);
      } catch (_) {}
    }
    if (val is AttendanceMark) return val.updatedAt;
    if (val is AttendanceSessionModel) return val.createdAt;
    if (val is MarkSyncEntry) return val.queuedAt;
    if (val is SyncEntry) return val.createdAt;
    return null;
  }
}
