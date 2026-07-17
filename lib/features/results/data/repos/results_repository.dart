import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/sync_action_type.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/cache_tracker.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/core/utils/sync_error_classifier.dart';
import 'package:church_management_system/features/results/data/datasources/results_local_datasource.dart';
import 'package:church_management_system/features/results/data/models/results_model.dart';
import 'package:church_management_system/features/results/domain/entities/result.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ResultsRepository implements IResultsRepository {
  final FirebaseFirestore _firestore;
  final ResultsLocalDatasource _localDatasource;
  final Connectivity _connectivity;
  final SyncService Function() _syncServiceGetter;

  ResultsRepository({
    required FirebaseFirestore firestore,
    required SyncService Function() syncServiceGetter,
    ResultsLocalDatasource? localDatasource,
    Connectivity? connectivity,
  }) : _firestore = firestore,
       _syncServiceGetter = syncServiceGetter,
       _localDatasource = localDatasource ?? ResultsLocalDatasource(),
       _connectivity = connectivity ?? Connectivity();

  @override
  Future<({List<Result> results, bool isFromCache})> getResultsForServant(
    String groupId, {
    PaginationCursor? startAfter,
  }) async {
    final lastDoc = startAfter?.token as DocumentSnapshot?;
    // If not paginating, try to return cached first for instant UI
    if (lastDoc == null) {
      final cached = await _localDatasource.getCachedResultsForGroup(groupId);
      if (cached.isNotEmpty) {
        final cacheKey = 'results_group_$groupId';
        if (CacheTracker.shouldRevalidate(cacheKey)) {
          unawaited(
            _firestore
                .collectionGroup('terms')
                .where('groupId', isEqualTo: groupId)
                .limit(30)
                .get(const GetOptions(source: Source.server))
                .catchError(
                  (_) => _firestore
                      .collectionGroup('terms')
                      .where('groupId', isEqualTo: groupId)
                      .limit(30)
                      .get(const GetOptions(source: Source.cache)),
                )
                .timeout(const Duration(seconds: 10))
                .then((snapshot) {
                  final results = snapshot.docs
                      .map((doc) => ResultsModel.fromMap(doc.data(), doc.id))
                      .toList();
                  if (results.isNotEmpty) {
                    final resultsMap = {
                      for (final r in results) r.studentId: r,
                    };
                    _localDatasource.cacheResults(resultsMap);
                    CacheTracker.markFetched(cacheKey);
                  }
                })
                .catchError((_) {}),
          );
        }
        return (
          results: cached.map((c) => c.toDomain()).toList(),
          isFromCache: true,
        );
      }
    }

    var query = _firestore
        .collectionGroup('terms')
        .where('groupId', isEqualTo: groupId)
        .limit(30);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    try {
      final snapshot = await query.get(const GetOptions(source: Source.server));
      final results = snapshot.docs
          .map((doc) => ResultsModel.fromMap(doc.data(), doc.id))
          .toList();

      // Cache the first page
      if (lastDoc == null && results.isNotEmpty) {
        final resultsMap = {for (final r in results) r.studentId: r};
        await _localDatasource.cacheResults(resultsMap);
      }
      return (
        results: results.map((r) => r.toDomain()).toList(),
        isFromCache: false,
      );
    } catch (_) {
      try {
        final cachedSnapshot = await query.get(
          const GetOptions(source: Source.cache),
        );
        final results = cachedSnapshot.docs
            .map((doc) => ResultsModel.fromMap(doc.data(), doc.id))
            .toList();
        return (
          results: results.map((r) => r.toDomain()).toList(),
          isFromCache: true,
        );
      } catch (_) {
        if (lastDoc == null) {
          final cached = await _localDatasource.getCachedResultsForGroup(
            groupId,
          );
          return (
            results: cached.map((c) => c.toDomain()).toList(),
            isFromCache: true,
          );
        }
        return (results: <Result>[], isFromCache: false);
      }
    }
  }

  @override
  Future<Result?> getResultForStudent(String studentId) async {
    final cached = await _localDatasource.getCachedResultForStudent(studentId);
    if (cached != null) {
      final cacheKey = 'result_student_$studentId';
      if (CacheTracker.shouldRevalidate(cacheKey)) {
        unawaited(
          _firestore
              .collection('results')
              .doc(studentId)
              .collection('terms')
              .get(const GetOptions(source: Source.server))
              .catchError(
                (_) => _firestore
                    .collection('results')
                    .doc(studentId)
                    .collection('terms')
                    .get(const GetOptions(source: Source.cache)),
              )
              .timeout(const Duration(seconds: 10))
              .then((termsSnapshot) {
                if (termsSnapshot.docs.isNotEmpty) {
                  final result = ResultsModel.fromMap(
                    termsSnapshot.docs.first.data(),
                    termsSnapshot.docs.first.id,
                  );
                  _localDatasource.cacheResult(result.studentId, result);
                  CacheTracker.markFetched(cacheKey);
                }
              })
              .catchError((_) {}),
        );
      }
      return cached.toDomain();
    }

    try {
      final termsSnapshot = await _firestore
          .collection('results')
          .doc(studentId)
          .collection('terms')
          .get();
      if (termsSnapshot.docs.isEmpty) return null;
      final result = ResultsModel.fromMap(
        termsSnapshot.docs.first.data(),
        termsSnapshot.docs.first.id,
      );
      await _localDatasource.cacheResult(result.studentId, result);
      return result.toDomain();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateResult(Result result) async {
    final model = ResultsModel.fromDomain(result);
    // 1. Write to local Hive cache FIRST
    try {
      await _localDatasource.cacheResult(model.studentId, model);
    } catch (e) {
      developer.log(
        'Local cache update failed in ResultsRepository',
        error: e,
        name: 'ResultsRepository',
      );
    }

    // 2. Try online write or fallback to outbox queue
    final syncEntry = SyncEntry.create(
      id: 'update_result_${model.studentId}_${model.termId}',
      action: SyncActionType.updateResult,
      payload: model.toMap(),
      createdAt: DateTime.now(),
    );

    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        await _syncServiceGetter().enqueue(syncEntry);
        return;
      }

      await _firestore
          .collection('results')
          .doc(model.studentId)
          .collection('terms')
          .doc(model.termId)
          .set(model.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        developer.log(
          'Firestore write failed with network error, enqueuing for offline sync',
          error: e,
          name: 'ResultsRepository',
        );
        await _syncServiceGetter().enqueue(syncEntry);
      } else {
        developer.log(
          'Update result failed with firebase error',
          error: e,
          name: 'ResultsRepository',
        );
        rethrow;
      }
    } catch (e) {
      if (!SyncErrorClassifier.isRetriable(e)) {
        rethrow;
      }
      developer.log(
        'Update result failed, enqueuing for offline sync',
        error: e,
        name: 'ResultsRepository',
      );
      await _syncServiceGetter().enqueue(syncEntry);
    }
  }

  @override
  Future<void> syncOfflineUpdate(Map<String, dynamic> payload) async {
    try {
      final studentId = payload['studentId'] as String;
      final termId = payload['termId'] as String;
      final createdAtString = payload['updatedAt'] as String?;
      final createdAt = createdAtString != null
          ? DateTime.parse(createdAtString)
          : DateTime.now();

      final docRef = _firestore
          .collection('results')
          .doc(studentId)
          .collection('terms')
          .doc(termId);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            final dbTimestamp = data['updatedAt'];
            if (dbTimestamp is Timestamp) {
              if (dbTimestamp.toDate().isAfter(createdAt)) {
                return; // Database is newer, abort write (LWW)
              }
            }
          }
        }

        transaction.set(docRef, {
          ...payload,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      developer.log('Sync offline result failed', name: 'ResultsRepository');
      rethrow;
    }
  }
}
