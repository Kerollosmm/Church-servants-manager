import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncEntry', () {
    test('failedAt is null by default', () {
      final entry = SyncEntry(
        id: 'test_1',
        actionType: 'MARK_ATTENDANCE',
        payload: {'key': 'value'},
        createdAt: DateTime(2026),
      );
      expect(entry.failedAt, isNull);
    });

    test('failedAt can be set', () {
      final now = DateTime(2026, 1, 15);
      final entry = SyncEntry(
        id: 'test_2',
        actionType: 'MARK_ATTENDANCE',
        payload: {'key': 'value'},
        createdAt: DateTime(2026),
        failedAt: now,
      );
      expect(entry.failedAt, now);
    });

    test('toJson includes failedAt', () {
      final now = DateTime(2026, 1, 15);
      final entry = SyncEntry(
        id: 'test_3',
        actionType: 'MARK_ATTENDANCE',
        payload: {'key': 'value'},
        createdAt: DateTime(2026),
        failedAt: now,
      );
      final json = entry.toJson();
      expect(json['failedAt'], now.toIso8601String());
    });

    test('retryCount defaults to 0', () {
      final entry = SyncEntry(
        id: 'test',
        actionType: 'MARK_ATTENDANCE',
        payload: {'key': 'value'},
        createdAt: DateTime(2026),
      );
      expect(entry.retryCount, 0);
    });

    test('toJson returns all fields', () {
      final entry = SyncEntry(
        id: 'test',
        actionType: 'MARK_ATTENDANCE',
        payload: {'studentId': 'abc'},
        createdAt: DateTime(2026),
      );
      final json = entry.toJson();
      expect(json['id'], 'test');
      expect(json['actionType'], 'MARK_ATTENDANCE');
      expect(json['payload'], {'studentId': 'abc'});
      expect(json['retryCount'], 0);
      expect(json['failedAt'], isNull);
    });
  });
}
