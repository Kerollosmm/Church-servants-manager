import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart'
    hide SyncStatus;
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/servant/data/local/servant_local_datasource.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart'
    hide ServantsPage;
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/servant/domain/entities/servant_page.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

typedef _ServantDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

/// Repository for managing servant data.
/// Servants are stored in the Users collection with role == 'servant'.
class ServantDataRepository implements IServantRepository {
  final FirebaseFirestore _firestore;
  final ServantLocalDatasource _localDatasource;
  final SyncService _syncService;
  final Connectivity _connectivity;

  ServantDataRepository({
    required FirebaseFirestore firestore,
    ServantLocalDatasource? localDatasource,
    required SyncService syncService,
    Connectivity? connectivity,
  }) : _firestore = firestore,
       _localDatasource = localDatasource ?? ServantLocalDatasource(),
       _syncService = syncService,
       _connectivity = connectivity ?? Connectivity();

  /// Reference to Users collection (servants are users with role == servant)
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.servants);

  /// Base query for all servants (users with role == servant)
  Query<Map<String, dynamic>> get _servantsQuery =>
      _usersCollection.where('role', isEqualTo: UserRole.servant.name);

  Query<Map<String, dynamic>> _sortedServantsQuery() {
    return _servantsQuery.orderBy('name');
  }

  Servant? _servantFromData(
    Map<String, dynamic> data,
    String docId,
    bool includeArchived,
  ) {
    final servant = ServantModel.fromMap(data, docId);
    if (!includeArchived && servant.isArchived) {
      return null;
    }
    return servant.toDomain();
  }

  List<Servant> _servantsFromDocs(
    List<_ServantDoc> docs,
    bool includeArchived,
  ) {
    final servants = <Servant>[];
    for (final doc in docs) {
      final servant = _servantFromData(doc.data(), doc.id, includeArchived);
      if (servant != null) {
        servants.add(servant);
      }
    }
    return servants;
  }

  Map<String, dynamic> _normalizeServantWriteData(Servant servant) {
    final model = ServantModel.fromDomain(servant);
    final data = model.toMap();
    data['role'] = model.role.name;

    if (model.role != UserRole.servant) {
      // Clear servant-only scoping fields when user is no longer a servant.
      data['groupId'] = FieldValue.delete();
      data['assignedTeamIds'] = FieldValue.delete();
    }

    return data;
  }

  @override
  Future<Servant?> getServantById(
    String docId, {
    bool includeArchived = false,
  }) async {
    try {
      final doc = await _usersCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        // Verify this user has servant role
        final data = doc.data()!;
        if (data['role'] != UserRole.servant.name) return null;
        return _servantFromData(data, doc.id, includeArchived);
      }
      return null;
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<Servant?> getServantByUid(
    String uid, {
    bool includeArchived = false,
  }) async {
    try {
      final canonicalDoc = await _usersCollection.doc(uid).get();
      if (canonicalDoc.exists && canonicalDoc.data() != null) {
        final data = canonicalDoc.data()!;
        if (data['role'] == UserRole.servant.name) {
          return _servantFromData(data, canonicalDoc.id, includeArchived);
        }
      }

      final snapshot = await _servantsQuery
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return _servantFromData(doc.data(), doc.id, includeArchived);
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<({List<Servant> servants, bool isFromCache})>
  getServantsByGroupWithFallback(
    String groupId, {
    bool includeArchived = false,
  }) async {
    try {
      final cacheSnapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.cache));
      if (cacheSnapshot.docs.isNotEmpty) {
        return (
          servants: _servantsFromDocs(cacheSnapshot.docs, includeArchived),
          isFromCache: true,
        );
      }
    } catch (_) {
      // Cache miss or other cache error is expected, fallback to server
    }

    try {
      final serverSnapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions());
      return (
        servants: _servantsFromDocs(serverSnapshot.docs, includeArchived),
        isFromCache: false,
      );
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<Servant>> getAllServants({
    int limit = 20,
    PaginationCursor? cursor,
    bool includeArchived = false,
  }) async {
    Query<Map<String, dynamic>> query = _sortedServantsQuery();

    if (limit > 0) {
      query = query.limit(limit);
    }

    final lastDocument = cursor?.token as DocumentSnapshot?;
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    try {
      final cacheSnapshot = await query.get(
        const GetOptions(source: Source.cache),
      );
      if (cacheSnapshot.docs.isNotEmpty) {
        return _servantsFromDocs(cacheSnapshot.docs, includeArchived);
      }
    } catch (_) {
      // Cache miss or other cache error is expected, fallback to server
    }

    try {
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      return _servantsFromDocs(serverSnapshot.docs, includeArchived);
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<ServantsPage> getServantsPage({
    int limit = 50,
    PaginationCursor? cursor,
    bool includeArchived = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _sortedServantsQuery().limit(
        limit + 1,
      );

      final token = cursor?.token;
      final lastDocument = token is DocumentSnapshot<Map<String, dynamic>>
          ? token
          : null;
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final pageDocs = hasMore ? docs.take(limit).toList() : docs;

      final nextDoc = pageDocs.isEmpty ? lastDocument : pageDocs.last;

      return ServantsPage(
        servants: _servantsFromDocs(pageDocs, includeArchived),
        lastDocument: nextDoc != null
            ? PaginationCursor.fromToken(nextDoc)
            : null,
        hasMore: hasMore,
      );
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<Servant>> getServantsByTeam(
    String teamName, {
    bool includeArchived = false,
  }) async {
    try {
      try {
        final cacheSnapshot = await _usersCollection
            .where('role', isEqualTo: UserRole.servant.name)
            .where('groupId', isEqualTo: teamName)
            .get(const GetOptions(source: Source.cache));

        if (cacheSnapshot.docs.isNotEmpty) {
          return _servantsFromDocs(cacheSnapshot.docs, includeArchived);
        }
      } catch (_) {
        // Cache miss or other cache error is expected, fallback to server
      }

      final snapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: teamName)
          .get(const GetOptions());

      return _servantsFromDocs(snapshot.docs, includeArchived);
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<Servant>> searchServants(
    String query, {
    int limit = 20,
    bool includeArchived = false,
  }) async {
    try {
      if (query.isEmpty) {
        return getAllServants(limit: limit, includeArchived: includeArchived);
      }

      // 1. Check local Hive cache first
      final normalizedQuery = query.toLowerCase().trim();
      final cachedModels = await _localDatasource.getCachedServants(
        includeArchived: includeArchived,
      );
      final cachedMatches = cachedModels
          .where((s) => s.name.toLowerCase().contains(normalizedQuery))
          .map((m) => m.toDomain())
          .take(limit)
          .toList();

      if (cachedMatches.isNotEmpty) {
        developer.log(
          'Found ${cachedMatches.length} search matches for "$query" in local cache',
          name: 'ServantDataRepository',
        );
        return cachedMatches;
      }

      // 2. Debounce local search key typing before remote firestore query
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final snapshot = await _sortedServantsQuery()
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get();

      final remoteResults = _servantsFromDocs(snapshot.docs, includeArchived);
      // Cache remote results locally
      for (final doc in snapshot.docs) {
        try {
          await _localDatasource.cacheServant(
            ServantModel.fromMap(doc.data(), doc.id),
          );
        } catch (_) {}
      }
      return remoteResults;
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<String> createServant(Servant servant) async {
    try {
      final docRef = servant.docID.isNotEmpty
          ? _usersCollection.doc(servant.docID)
          : _usersCollection.doc();

      final model = ServantModel.fromDomain(servant);
      final finalServant = model.copyWith(
        docID: docRef.id,
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );

      await _localDatasource.cacheServant(finalServant);

      final connectivity = await _connectivity.checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);

      if (isOffline) {
        final syncEntry = SyncEntry(
          id: 'create_servant_${docRef.id}',
          actionType: 'CREATE_SERVANT',
          payload: _normalizeServantWriteData(finalServant.toDomain()),
          createdAt: DateTime.now(),
        );
        await _syncService.enqueue(syncEntry);
        return docRef.id;
      }

      try {
        await docRef.set(_normalizeServantWriteData(finalServant.toDomain()));
        final syncedServant = finalServant.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.cacheServant(syncedServant);
      } catch (e) {
        final syncEntry = SyncEntry(
          id: 'create_servant_${docRef.id}',
          actionType: 'CREATE_SERVANT',
          payload: _normalizeServantWriteData(finalServant.toDomain()),
          createdAt: DateTime.now(),
        );
        await _syncService.enqueue(syncEntry);
      }

      return docRef.id;
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> upsertServant(Servant servant) async {
    try {
      final model = ServantModel.fromDomain(servant);
      final finalServant = model.copyWith(
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );

      await _localDatasource.cacheServant(finalServant);

      final connectivity = await _connectivity.checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);

      if (isOffline) {
        final syncEntry = SyncEntry(
          id: 'upsert_servant_${servant.docID}',
          actionType: 'CREATE_SERVANT',
          payload: _normalizeServantWriteData(finalServant.toDomain()),
          createdAt: DateTime.now(),
        );
        await _syncService.enqueue(syncEntry);
        return;
      }

      try {
        await _usersCollection
            .doc(servant.docID)
            .set(
              _normalizeServantWriteData(finalServant.toDomain()),
              SetOptions(merge: true),
            );
        final syncedServant = finalServant.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.cacheServant(syncedServant);
      } catch (e) {
        final syncEntry = SyncEntry(
          id: 'upsert_servant_${servant.docID}',
          actionType: 'CREATE_SERVANT',
          payload: _normalizeServantWriteData(finalServant.toDomain()),
          createdAt: DateTime.now(),
        );
        await _syncService.enqueue(syncEntry);
      }
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> updateServant(Servant servant) async {
    return upsertServant(servant);
  }

  @override
  Future<void> updateServantFields(
    String docId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final existing = await _localDatasource.getCachedServantById(docId);
      if (existing != null) {
        final updatedData = {...existing.toMap(), ...fields};
        final updated = ServantModel.fromMap(updatedData, docId).copyWith(
          syncStatus: SyncStatus.pending,
          clientUpdatedAt: DateTime.now(),
        );
        await _localDatasource.cacheServant(updated);
      }

      final connectivity = await _connectivity.checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);

      if (isOffline) {
        final syncEntry = SyncEntry(
          id: 'update_servant_$docId',
          actionType: 'CREATE_SERVANT',
          payload: {'docId': docId, ...fields},
          createdAt: DateTime.now(),
        );
        await _syncService.enqueue(syncEntry);
        return;
      }

      try {
        await _usersCollection.doc(docId).update(fields);
        if (existing != null) {
          final updatedData = {...existing.toMap(), ...fields};
          final synced = ServantModel.fromMap(
            updatedData,
            docId,
          ).copyWith(syncStatus: SyncStatus.synced);
          await _localDatasource.cacheServant(synced);
        }
      } catch (e) {
        final syncEntry = SyncEntry(
          id: 'update_servant_$docId',
          actionType: 'CREATE_SERVANT',
          payload: {'docId': docId, ...fields},
          createdAt: DateTime.now(),
        );
        await _syncService.enqueue(syncEntry);
      }
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> deleteServant(
    String docId, {
    required String performedByUid,
  }) async {
    try {
      final fields = {
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedByUserId': performedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final existing = await _localDatasource.getCachedServantById(docId);
      if (existing != null) {
        final updated = existing.copyWith(
          isArchived: true,
          archivedAt: DateTime.now(),
          archivedByUserId: performedByUid,
          syncStatus: SyncStatus.pending,
          clientUpdatedAt: DateTime.now(),
        );
        await _localDatasource.cacheServant(updated);
      }

      try {
        await _usersCollection.doc(docId).update(fields);
        if (existing != null) {
          final synced = existing.copyWith(
            isArchived: true,
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.cacheServant(synced);
        }
      } catch (_) {
        // Retain pending status locally.
      }
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> restoreServant(
    String docId, {
    required String performedByUid,
    String? assignedTeamId,
    List<String>? assignedTeamIds,
  }) async {
    try {
      final fields = <String, dynamic>{
        'isArchived': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredByUserId': performedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (assignedTeamId != null) fields['assignedTeamId'] = assignedTeamId;
      if (assignedTeamIds != null) fields['assignedTeamIds'] = assignedTeamIds;

      final existing = await _localDatasource.getCachedServantById(docId);
      if (existing != null) {
        final updated = existing.copyWith(
          isArchived: false,
          restoredAt: DateTime.now(),
          restoredByUserId: performedByUid,
          assignedTeamId: assignedTeamId ?? existing.assignedTeamId,
          assignedTeamIds: assignedTeamIds ?? existing.assignedTeamIds,
          syncStatus: SyncStatus.pending,
          clientUpdatedAt: DateTime.now(),
        );
        await _localDatasource.cacheServant(updated);
      }

      try {
        await _usersCollection.doc(docId).update(fields);
        if (existing != null) {
          final synced = existing.copyWith(
            isArchived: false,
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.cacheServant(synced);
        }
      } catch (_) {
        // Retain pending status locally.
      }
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> propagateServantNameToTeams({
    required String servantUid,
    required String newName,
  }) async {
    try {
      final teamsSnapshot = await _firestore
          .collection(FirestoreCollections.classes)
          .where('assignedServantId', isEqualTo: servantUid)
          .get();

      if (teamsSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in teamsSnapshot.docs) {
        batch.update(doc.reference, {
          'assignedServantName': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }
}
