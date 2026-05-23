import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/admin/data/datasources/analytics_local_datasource.dart';
import 'package:church_management_system/features/admin/data/models/analytics_summary_model.dart';
import 'package:church_management_system/features/admin/domain/repos/i_analytics_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads pre-aggregated sector analytics from a single Firestore document
/// (`/SectorsAnalytics/{sectorId}`) with a strict 1-hour Hive cache cooldown.
///
/// This eliminates per-record counting and protects Firebase Spark Plan quotas.
class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final FirebaseFirestore _firestore;
  final AnalyticsLocalDatasource _localDatasource;

  static const Duration _cacheCooldown = Duration(hours: 1);

  AnalyticsRepositoryImpl({
    required FirebaseFirestore firestore,
    required AnalyticsLocalDatasource localDatasource,
  })  : _firestore = firestore,
        _localDatasource = localDatasource;

  @override
  Future<AnalyticsSummaryModel> getSectorAnalytics(
    String sectorId, {
    bool forceRefresh = false,
  }) async {
    // 1. Check Hive cache first (zero Firestore reads).
    if (!forceRefresh) {
      final cached = await _localDatasource.getSummary(sectorId);
      if (cached != null && _isCacheFresh(cached.fetchedAt)) {
        return cached;
      }
    }

    // 2. Cache is stale or missing — fetch from Firestore.
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.sectorsAnalytics)
          .doc(sectorId)
          .get();

      if (!doc.exists || doc.data() == null) {
        // No server data — return stale cache if available, otherwise throw.
        final stale = await _localDatasource.getSummary(sectorId);
        if (stale != null) return stale;
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'SectorsAnalytics/$sectorId does not exist',
        );
      }

      final model = AnalyticsSummaryModel.fromMap(doc.data()!, doc.id);

      // 3. Persist to Hive with fetchedAt = now.
      await _localDatasource.saveSummary(model);

      return model;
    } on FirebaseException {
      // 4. Firestore failed — serve stale cache if we have it.
      final stale = await _localDatasource.getSummary(sectorId);
      if (stale != null) {
        developer.log(
          'Firestore unreachable, serving stale cache for $sectorId',
          name: 'AnalyticsRepository',
        );
        return stale;
      }
      rethrow;
    }
  }

  bool _isCacheFresh(DateTime fetchedAt) {
    return DateTime.now().difference(fetchedAt) < _cacheCooldown;
  }
}
