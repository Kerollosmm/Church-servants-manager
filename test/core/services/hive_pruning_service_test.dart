import 'dart:io';

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/hive_pruning_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late HivePruningService pruner;
  late DeadLetterQueue dlq;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prune_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(SyncEntryAdapter());
    }
    dlq = DeadLetterQueue();
    await dlq.init();
    pruner = HivePruningService(deadLetterQueue: dlq);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('HivePruningService', () {
    test('pruneSyncQueue moves entries older than 30 days to DLQ', () async {
      final box = await Hive.openBox<SyncEntry>('sync_queue_box');

      await box.put(
        'old_1',
        SyncEntry(
          id: 'old_1',
          actionType: 'MARK_ATTENDANCE',
          payload: {},
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
      );

      await box.put(
        'recent_1',
        SyncEntry(
          id: 'recent_1',
          actionType: 'MARK_ATTENDANCE',
          payload: {},
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      );

      final pruned = await pruner.pruneSyncQueue();
      expect(pruned, 1);
      expect(box.length, 1);
      expect(box.containsKey('recent_1'), isTrue);
      expect(box.containsKey('old_1'), isFalse);

      // Entry should be in DLQ, not lost
      expect(dlq.length, 1);
      expect(dlq.getAll().first.id, 'old_1');

      await box.close();
    });

    test('pruneStringBox removes cached entries by timestamp field', () async {
      final box = await Hive.openBox<String>('attendance_marks_cache');

      await box.put(
        'mark_old',
        '{"studentId":"s1","cachedAt":"${DateTime.now().subtract(const Duration(days: 45)).toIso8601String()}"}',
      );

      await box.put(
        'mark_recent',
        '{"studentId":"s2","cachedAt":"${DateTime.now().toIso8601String()}"}',
      );

      final pruned = await pruner.pruneStringBox(
        boxName: 'attendance_marks_cache',
        timestampExtractor: (json) {
          final jsonStr = json as String;
          final match = RegExp(r'"cachedAt":"([^"]+)"').firstMatch(jsonStr);
          return match != null ? DateTime.tryParse(match.group(1)!) : null;
        },
      );

      expect(pruned, 1);
      expect(box.length, 1);
      expect(box.containsKey('mark_recent'), isTrue);

      await box.close();
    });

    test('pruneSyncQueue returns 0 when all entries are recent', () async {
      final box = await Hive.openBox<SyncEntry>('sync_queue_box');
      await box.put(
        'new_1',
        SyncEntry(
          id: 'new_1',
          actionType: 'X',
          payload: {},
          createdAt: DateTime.now(),
        ),
      );

      final pruned = await pruner.pruneSyncQueue();
      expect(pruned, 0);
      expect(box.length, 1);

      await box.close();
    });

    test('pruneSyncQueue returns 0 when box is not open', () async {
      final pruned = await pruner.pruneSyncQueue();
      expect(pruned, 0);
    });

    test('pruneAll runs all prunable boxes', () async {
      final syncBox = await Hive.openBox<SyncEntry>('sync_queue_box');
      await syncBox.put(
        'old',
        SyncEntry(
          id: 'old',
          actionType: 'X',
          payload: {},
          createdAt: DateTime.now().subtract(const Duration(days: 40)),
        ),
      );

      final result = await pruner.pruneAll();
      expect(result.totalPruned, greaterThanOrEqualTo(1));
      expect(syncBox.isEmpty, isTrue);

      // Old entry moved to DLQ
      expect(dlq.length, greaterThanOrEqualTo(1));

      await syncBox.close();
    });
  });
}
