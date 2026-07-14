import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/cache_tracker.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/core/utils/sync_error_classifier.dart';
import 'package:church_management_system/features/student/data/datasources/pastoral_local_datasource.dart';
import 'package:church_management_system/features/student/data/models/pastoral_record_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_pastoral_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Concrete implementation of [IPastoralRepository] backed by Firestore & Hive.
///
/// Pastoral records live at: /Students/{studentId}/PastoralRecords/{recordId}
class PastoralRepository implements IPastoralRepository {
  final FirebaseFirestore _firestore;
  final PastoralLocalDatasource _localDatasource;
  final SyncService Function() _syncServiceGetter;
  final Connectivity _connectivity;

  PastoralRepository({
    required FirebaseFirestore firestore,
    PastoralLocalDatasource? localDatasource,
    required SyncService Function() syncServiceGetter,
    Connectivity? connectivity,
  }) : _firestore = firestore,
       _localDatasource = localDatasource ?? PastoralLocalDatasource(),
       _syncServiceGetter = syncServiceGetter,
       _connectivity = connectivity ?? Connectivity();

  /// Returns the sub-collection reference for a student's pastoral records.
  CollectionReference<Map<String, dynamic>> _recordsCollection(
    String studentId,
  ) {
    return _firestore
        .collection(FirestoreCollections.students)
        .doc(studentId)
        .collection(FirestoreCollections.pastoralRecords);
  }

  @override
  Future<void> createPastoralRecord(PastoralRecordModel record) async {
    final pendingRecord = record.copyWith(
      syncStatus: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    // Save to local cache first
    await _localDatasource.savePastoralRecord(pendingRecord);

    final syncEntry = SyncEntry(
      id: 'create_pastoral_record_${pendingRecord.recordId}',
      actionType: 'CREATE_PASTORAL_RECORD',
      payload: pendingRecord.toMap(),
      createdAt: DateTime.now(),
    );

    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        await _syncServiceGetter().enqueue(syncEntry);
        return;
      }

      await _recordsCollection(
        pendingRecord.studentId,
      ).doc(pendingRecord.recordId).set(pendingRecord.toMap());

      // Mark as synced locally
      await _localDatasource.savePastoralRecord(
        pendingRecord.copyWith(syncStatus: SyncStatus.synced),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        developer.log(
          'Firestore write failed with network error, enqueuing for offline sync',
          error: e,
          name: 'PastoralRepository',
        );
        await _syncServiceGetter().enqueue(syncEntry);
      } else {
        developer.log(
          'Create pastoral record failed with firebase error',
          error: e,
          name: 'PastoralRepository',
        );
        rethrow;
      }
    } catch (e) {
      if (!SyncErrorClassifier.isRetriable(e)) {
        rethrow;
      }
      developer.log(
        'Create pastoral record failed, enqueuing for offline sync',
        error: e,
        name: 'PastoralRepository',
      );
      await _syncServiceGetter().enqueue(syncEntry);
    }
  }

  @override
  Future<void> syncOfflineCreate(Map<String, dynamic> payload) async {
    final recordId = payload['recordId'] as String?;
    final studentId = payload['studentId'] as String?;

    if (recordId == null || studentId == null) {
      developer.log(
        'syncOfflineCreate: missing recordId or studentId in payload',
        name: 'PastoralRepository',
      );
      return;
    }

    // Use recordId as document ID for idempotent writes.
    await _recordsCollection(studentId).doc(recordId).set(payload);

    // Sync to local cache too
    final record = PastoralRecordModel.fromJson(
      payload,
    ).copyWith(syncStatus: SyncStatus.synced);
    await _localDatasource.savePastoralRecord(record);

    developer.log(
      'Synced pastoral record $recordId for student $studentId',
      name: 'PastoralRepository',
    );
  }

  @override
  Future<List<PastoralRecordModel>> getRecordsForStudent(
    String studentId,
  ) async {
    // 1. Read from cache first
    final cached = await _localDatasource.getCachedRecordsForStudent(studentId);

    // 2. Background revalidation if cache is not empty
    if (cached.isNotEmpty) {
      final cacheKey = 'pastoral_records_$studentId';
      if (CacheTracker.shouldRevalidate(cacheKey)) {
        unawaited(
          _recordsCollection(studentId)
              .orderBy('createdAt', descending: true)
              .get(const GetOptions(source: Source.server))
              .catchError(
                (_) => _recordsCollection(studentId)
                    .orderBy('createdAt', descending: true)
                    .get(const GetOptions(source: Source.cache)),
              )
              .timeout(const Duration(seconds: 10))
              .then((snapshot) {
                final records = snapshot.docs
                    .map(
                      (doc) => PastoralRecordModel.fromMap(doc.data(), doc.id),
                    )
                    .toList();
                if (records.isNotEmpty) {
                  _localDatasource.savePastoralRecords(records);
                  CacheTracker.markFetched(cacheKey);
                }
              })
              .catchError((_) {}),
        );
      }
      return cached;
    }

    // 3. Fallback online/cache query
    try {
      final snapshot = await _recordsCollection(studentId)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      final records = snapshot.docs
          .map((doc) => PastoralRecordModel.fromMap(doc.data(), doc.id))
          .toList();
      if (records.isNotEmpty) {
        await _localDatasource.savePastoralRecords(records);
      }
      return records;
    } catch (_) {
      try {
        final cachedSnapshot = await _recordsCollection(studentId)
            .orderBy('createdAt', descending: true)
            .get(const GetOptions(source: Source.cache));
        final records = cachedSnapshot.docs
            .map((doc) => PastoralRecordModel.fromMap(doc.data(), doc.id))
            .toList();
        return records;
      } catch (_) {
        return await _localDatasource.getCachedRecordsForStudent(studentId);
      }
    }
  }

  @override
  Future<List<PastoralRecordModel>> getAllRecords({int limit = 50}) async {
    // Cross-collection group query for admin dashboard.
    try {
      final snapshot = await _firestore
          .collectionGroup(FirestoreCollections.pastoralRecords)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));

      final records = snapshot.docs
          .map((doc) => PastoralRecordModel.fromMap(doc.data(), doc.id))
          .toList();

      if (records.isNotEmpty) {
        await _localDatasource.savePastoralRecords(records);
      }
      return records;
    } catch (_) {
      try {
        final cachedSnapshot = await _firestore
            .collectionGroup(FirestoreCollections.pastoralRecords)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get(const GetOptions(source: Source.cache));

        final records = cachedSnapshot.docs
            .map((doc) => PastoralRecordModel.fromMap(doc.data(), doc.id))
            .toList();
        return records;
      } catch (_) {
        return await _localDatasource.getAllCachedRecords();
      }
    }
  }
}
