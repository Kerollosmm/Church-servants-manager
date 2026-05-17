import 'dart:convert';

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class WeeklyStats {
  final int totalSessions;
  final int totalPresent;
  final DateTime updatedAt;

  const WeeklyStats({
    required this.totalSessions,
    required this.totalPresent,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalPresent': totalPresent,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory WeeklyStats.fromMap(Map<String, dynamic> map) {
    return WeeklyStats(
      totalSessions: map['totalSessions'] ?? 0,
      totalPresent: map['totalPresent'] ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] as int? ?? 0,
      ),
    );
  }
}

class GlobalDashboardStats {
  final int totalSessions;
  final int totalPresent;
  final int totalRosterEntries;
  final DateTime updatedAt;

  const GlobalDashboardStats({
    required this.totalSessions,
    required this.totalPresent,
    required this.totalRosterEntries,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalPresent': totalPresent,
      'totalRosterEntries': totalRosterEntries,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory GlobalDashboardStats.fromMap(Map<String, dynamic> map) {
    return GlobalDashboardStats(
      totalSessions: map['totalSessions'] ?? 0,
      totalPresent: map['totalPresent'] ?? 0,
      totalRosterEntries: map['totalRosterEntries'] ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] as int? ?? 0,
      ),
    );
  }
}

class AdminStatisticsService {
  final FirebaseFirestore _firestore;
  static const String _boxName = 'admin_stats_box';
  static const Duration _ttl = Duration(hours: 1);

  AdminStatisticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<GlobalDashboardStats> getGlobalDashboardStats({
    bool forceRefresh = false,
  }) async {
    final box = await Hive.openBox<String>(_boxName);
    const cacheKey = 'global_dashboard_stats';

    if (!forceRefresh) {
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        try {
          final map = jsonDecode(cachedData) as Map<String, dynamic>;
          final stats = GlobalDashboardStats.fromMap(map);
          if (DateTime.now().difference(stats.updatedAt) < _ttl) {
            return stats;
          }
        } catch (_) {
          // Fallback to remote if parsing fails
        }
      }
    }

    final sessionsQuery = _firestore.collectionGroup(FirestoreCollections.attendanceSessions);

    final aggregateQuery = await sessionsQuery
        .aggregate(count(), sum('presentCount'), sum('totalRosterEntries'))
        .get();

    final totalSessions = aggregateQuery.count ?? 0;
    final totalPresent = (aggregateQuery.getSum('presentCount') ?? 0.0).toInt();
    final totalRosterEntries = (aggregateQuery.getSum('totalRosterEntries') ?? 0.0).toInt();

    final stats = GlobalDashboardStats(
      totalSessions: totalSessions,
      totalPresent: totalPresent,
      totalRosterEntries: totalRosterEntries,
      updatedAt: DateTime.now(),
    );

    await box.put(cacheKey, jsonEncode(stats.toMap()));

    return stats;
  }

  /// Retrieves weekly attendance statistics.
  ///
  /// Fetches from local Hive cache if valid (TTL < 1 hour) and `forceRefresh` is false.
  /// Otherwise, queries Firestore using AggregateQuery to minimize read operations.
  Future<WeeklyStats> getWeeklyAttendanceStats(
    String teamId, {
    bool forceRefresh = false,
  }) async {
    final box = await Hive.openBox<String>(_boxName);
    final cacheKey = 'weekly_stats_$teamId';

    if (!forceRefresh) {
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        try {
          final map = jsonDecode(cachedData) as Map<String, dynamic>;
          final stats = WeeklyStats.fromMap(map);
          if (DateTime.now().difference(stats.updatedAt) < _ttl) {
            return stats;
          }
        } catch (_) {
          // Fallback to remote if parsing fails
        }
      }
    }

    final now = DateTime.now();
    // Assuming Sunday is the start of the week.
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday % 7));
    final startOfWeekTimestamp = Timestamp.fromDate(startOfWeek);

    final sessionsQuery = _firestore
        .collection(FirestoreCollections.classes)
        .doc(teamId)
        .collection(FirestoreCollections.attendanceSessions)
        .where('startsAt', isGreaterThanOrEqualTo: startOfWeekTimestamp);

    // Perform aggregate queries (Zero document downloads, only aggregation costs)
    final aggregateQuery = await sessionsQuery
        .aggregate(count(), sum('presentCount'))
        .get();

    final totalSessions = aggregateQuery.count ?? 0;
    final totalPresent = (aggregateQuery.getSum('presentCount') ?? 0.0).toInt();

    final stats = WeeklyStats(
      totalSessions: totalSessions,
      totalPresent: totalPresent,
      updatedAt: DateTime.now(),
    );

    // Cache the result
    await box.put(cacheKey, jsonEncode(stats.toMap()));

    return stats;
  }
}
