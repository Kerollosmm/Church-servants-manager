import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/results/data/datasources/results_local_datasource.dart';
import 'package:church_management_system/features/results/data/models/results_model.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ResultsRepository implements IResultsRepository {
  final FirebaseFirestore _firestore;
  final ResultsLocalDatasource _localDatasource;

  ResultsRepository({
    required FirebaseFirestore firestore,
    ResultsLocalDatasource? localDatasource,
  }) : _firestore = firestore,
       _localDatasource = localDatasource ?? ResultsLocalDatasource();

  @override
  Future<List<ResultsModel>> getResultsForServant(
    String groupId, {
    DocumentSnapshot? startAfter,
  }) async {
    // If not paginating, try to return cached first for instant UI
    if (startAfter == null) {
      final cached = await _localDatasource.getCachedResultsForGroup(groupId);
      if (cached.isNotEmpty) {
        unawaited(
          _firestore
              .collectionGroup('terms')
              .where('groupId', isEqualTo: groupId)
              .limit(30)
              .get(const GetOptions(source: Source.server))
              .then((snapshot) {
                final results = snapshot.docs
                    .map((doc) => ResultsModel.fromMap(doc.data(), doc.id))
                    .toList();
                if (results.isNotEmpty) {
                  final resultsMap = {for (final r in results) r.studentId: r};
                  _localDatasource.cacheResults(resultsMap);
                }
              })
              .catchError((_) {}),
        );
        return cached;
      }
    }

    // MANDATORY: Add a 'groupId' filter to all servant-level result queries
    // to prevent fetching unauthorized student data, staying within Spark Plan limits.
    // Note: We use collectionGroup for 'terms' as the results are now nested.
    var query = _firestore
        .collectionGroup('terms')
        .where('groupId', isEqualTo: groupId)
        .limit(30);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    try {
      final snapshot = await query.get(const GetOptions(source: Source.server));
      final results = snapshot.docs
          .map((doc) => ResultsModel.fromMap(doc.data(), doc.id))
          .toList();

      // Cache the first page
      if (startAfter == null && results.isNotEmpty) {
        final resultsMap = {for (final r in results) r.studentId: r};
        await _localDatasource.cacheResults(resultsMap);
      }
      return results;
    } catch (_) {
      if (startAfter == null) {
        return await _localDatasource.getCachedResultsForGroup(groupId);
      }
      return [];
    }
  }

  @override
  Future<ResultsModel?> getResultForStudent(String studentId) async {
    final cached = await _localDatasource.getCachedResultForStudent(studentId);
    if (cached != null) {
      unawaited(
        _firestore
            .collection('results')
            .doc(studentId)
            .collection('terms')
            .get(const GetOptions(source: Source.server))
            .then((termsSnapshot) {
              if (termsSnapshot.docs.isNotEmpty) {
                final result = ResultsModel.fromMap(
                  termsSnapshot.docs.first.data(),
                  termsSnapshot.docs.first.id,
                );
                _localDatasource.cacheResult(result.studentId, result);
              }
            })
            .catchError((_) {}),
      );
      return cached;
    }

    try {
      // Note: Using student-based nesting as per report
      final termsSnapshot = await _firestore
          .collection('results')
          .doc(studentId)
          .collection('terms')
          .get();
      if (termsSnapshot.docs.isEmpty) return null;
      // For now returning first term; real app would likely need a termId
      final result = ResultsModel.fromMap(
        termsSnapshot.docs.first.data(),
        termsSnapshot.docs.first.id,
      );
      await _localDatasource.cacheResult(result.studentId, result);
      return result;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateResult(ResultsModel result) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        final syncEntry = SyncEntry(
          id: 'update_result_${result.studentId}_${result.termId}',
          actionType: 'UPDATE_RESULT',
          payload: result.toMap(),
          createdAt: DateTime.now(),
        );
        await getIt<SyncService>().enqueue(syncEntry);
        await _localDatasource.cacheResult(result.studentId, result);
        return;
      }

      await _firestore
          .collection('results')
          .doc(result.studentId)
          .collection('terms')
          .doc(result.termId)
          .set(result.toMap(), SetOptions(merge: true));
      await _localDatasource.cacheResult(result.studentId, result);
    } catch (e) {
      developer.log('Update result failed', name: 'ResultsRepository');
      rethrow;
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
