import 'dart:io';

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late DeadLetterQueue dlq;

  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('dlq_test_').path);
    Hive.registerAdapter(SyncEntryAdapter());
  });

  setUp(() async {
    dlq = DeadLetterQueue();
    await dlq.init();
  });

  tearDown(() async {
    final box = Hive.box<SyncEntry>('dead_letter_queue_box');
    await box.clear();
  });

  group('DeadLetterQueue', () {
    test('init opens the box', () {
      expect(dlq.boxName, 'dead_letter_queue_box');
      expect(dlq.isEmpty, isTrue);
    });

    test('add stores entry with failedAt timestamp', () async {
      final entry = SyncEntry(
        id: 'dlq_1',
        actionType: 'MARK_ATTENDANCE',
        payload: {'studentId': 's1'},
        createdAt: DateTime(2026),
      );
      await dlq.add(entry);
      expect(dlq.length, 1);

      final stored = dlq.getAll().first;
      expect(stored.id, 'dlq_1');
      expect(stored.failedAt, isNotNull);
    });

    test('getAll returns entries sorted by failedAt descending', () async {
      final entry1 = SyncEntry(
        id: 'dlq_1',
        actionType: 'MARK_ATTENDANCE',
        payload: {},
        createdAt: DateTime(2026),
      );
      final entry2 = SyncEntry(
        id: 'dlq_2',
        actionType: 'UPSERT_STUDENT',
        payload: {},
        createdAt: DateTime(2026, 1, 2),
      );

      await dlq.add(entry1);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await dlq.add(entry2);

      final all = dlq.getAll();
      expect(all.length, 2);
      expect(all.first.id, 'dlq_2');
    });

    test('remove deletes entry by id', () async {
      final entry = SyncEntry(
        id: 'dlq_remove',
        actionType: 'MARK_ATTENDANCE',
        payload: {},
        createdAt: DateTime(2026),
      );
      await dlq.add(entry);
      expect(dlq.length, 1);

      await dlq.remove('dlq_remove');
      expect(dlq.length, 0);
    });

    test('clear removes all entries', () async {
      await dlq.add(SyncEntry(
        id: 'a',
        actionType: 'X',
        payload: {},
        createdAt: DateTime(2026),
      ));
      await dlq.add(SyncEntry(
        id: 'b',
        actionType: 'Y',
        payload: {},
        createdAt: DateTime(2026, 1, 2),
      ));
      expect(dlq.length, 2);

      await dlq.clear();
      expect(dlq.length, 0);
      expect(dlq.isEmpty, isTrue);
    });
  });
}
