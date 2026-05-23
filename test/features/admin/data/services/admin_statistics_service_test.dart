import 'dart:convert';

import 'package:church_management_system/features/admin/data/services/admin_statistics_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminStatisticsService service;

  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('test_hive');
  });

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = AdminStatisticsService(firestore: firestore);
    // Clear Hive box before each test
    await Hive.deleteBoxFromDisk('admin_stats_box');
  });

  group('AdminStatisticsService Models', () {
    test('WeeklyStats serialization', () {
      final now = DateTime.now();
      final stats = WeeklyStats(
        totalSessions: 5,
        totalPresent: 45,
        updatedAt: now,
      );

      final map = stats.toMap();
      expect(map['totalSessions'], 5);
      expect(map['totalPresent'], 45);

      final deserialized = WeeklyStats.fromMap(map);
      expect(deserialized.totalSessions, 5);
      expect(deserialized.totalPresent, 45);
      // Millisecond precision check
      expect(deserialized.updatedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('GlobalDashboardStats serialization', () {
      final now = DateTime.now();
      final stats = GlobalDashboardStats(
        totalSessions: 10,
        totalPresent: 150,
        totalRosterEntries: 200,
        updatedAt: now,
      );

      final map = stats.toMap();
      expect(map['totalSessions'], 10);
      expect(map['totalPresent'], 150);
      expect(map['totalRosterEntries'], 200);

      final deserialized = GlobalDashboardStats.fromMap(map);
      expect(deserialized.totalSessions, 10);
      expect(deserialized.totalPresent, 150);
      expect(deserialized.totalRosterEntries, 200);
      expect(deserialized.updatedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });
  });

  group('AdminStatisticsService Firestore Queries', () {
    test('getGlobalDashboardStats handles empty firestore gracefully', () async {
      final stats = await service.getGlobalDashboardStats(forceRefresh: true);

      expect(stats.totalSessions, 0);
      expect(stats.totalPresent, 0);
      expect(stats.totalRosterEntries, 0);
    });

    test('getWeeklyAttendanceStats handles empty firestore gracefully', () async {
      final stats = await service.getWeeklyAttendanceStats('team1', forceRefresh: true);

      expect(stats.totalSessions, 0);
      expect(stats.totalPresent, 0);
    });

    // We skip complex aggregation tests because `fake_cloud_firestore` doesn't fully support
    // `getSum` and `aggregate` queries yet. The service throws errors or returns default
    // values, but we can verify the fallback mechanism handles it.
  });

  group('AdminStatisticsService Caching Logic', () {
    test('Returns cached GlobalDashboardStats if valid and no forceRefresh', () async {
      // Setup cache
      final box = await Hive.openBox<String>('admin_stats_box');
      final cachedStats = GlobalDashboardStats(
        totalSessions: 42,
        totalPresent: 100,
        totalRosterEntries: 150,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await box.put('global_dashboard_stats', jsonEncode(cachedStats.toMap()));

      // Fetch
      final stats = await service.getGlobalDashboardStats();

      expect(stats.totalSessions, 42);
      expect(stats.totalPresent, 100);
    });

    test('Ignores cache if forceRefresh is true', () async {
      // Setup cache
      final box = await Hive.openBox<String>('admin_stats_box');
      final cachedStats = GlobalDashboardStats(
        totalSessions: 42,
        totalPresent: 100,
        totalRosterEntries: 150,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await box.put('global_dashboard_stats', jsonEncode(cachedStats.toMap()));

      // Fetch
      final stats = await service.getGlobalDashboardStats(forceRefresh: true);

      // Should return 0 since Firestore is empty
      expect(stats.totalSessions, 0);
    });

    test('Ignores expired cache', () async {
      // Setup cache
      final box = await Hive.openBox<String>('admin_stats_box');
      final cachedStats = GlobalDashboardStats(
        totalSessions: 42,
        totalPresent: 100,
        totalRosterEntries: 150,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)), // Expired
      );
      await box.put('global_dashboard_stats', jsonEncode(cachedStats.toMap()));

      // Fetch
      final stats = await service.getGlobalDashboardStats();

      // Should hit Firestore (empty) instead of returning 42
      expect(stats.totalSessions, 0);
    });

    test('Returns cached WeeklyStats if valid and no forceRefresh', () async {
      // Setup cache
      final box = await Hive.openBox<String>('admin_stats_box');
      final cachedStats = WeeklyStats(
        totalSessions: 5,
        totalPresent: 45,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      await box.put('weekly_stats_team1', jsonEncode(cachedStats.toMap()));

      // Fetch
      final stats = await service.getWeeklyAttendanceStats('team1');

      expect(stats.totalSessions, 5);
      expect(stats.totalPresent, 45);
    });
  });
}
