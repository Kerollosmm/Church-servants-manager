import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef _ServantDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

/// A paginated result of servant data from [ServantDataRepository].
class ServantsPage {
  final List<ServantModel> servants;
  final PaginationCursor? lastDocument;
  final bool hasMore;

  const ServantsPage({
    required this.servants,
    required this.lastDocument,
    required this.hasMore,
  });
}

/// Repository for managing servant data.
/// Servants are stored in the Users collection with role == 'servant'.
class ServantDataRepository implements IServantRepository {
  final FirebaseFirestore _firestore;

  ServantDataRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Reference to Users collection (servants are users with role == servant)
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  /// Base query for all servants (users with role == servant)
  Query<Map<String, dynamic>> get _servantsQuery =>
      _usersCollection.where('role', isEqualTo: UserRole.servant.name);

  Query<Map<String, dynamic>> _sortedServantsQuery() {
    return _servantsQuery.orderBy('name');
  }

  ServantModel? _servantFromData(
    Map<String, dynamic> data,
    String docId,
    bool includeArchived,
  ) {
    final servant = ServantModel.fromMap(data, docId);
    if (!includeArchived && servant.isArchived) {
      return null;
    }
    return servant;
  }

  List<ServantModel> _servantsFromDocs(
    List<_ServantDoc> docs,
    bool includeArchived,
  ) {
    final servants = <ServantModel>[];
    for (final doc in docs) {
      final servant = _servantFromData(doc.data(), doc.id, includeArchived);
      if (servant != null) {
        servants.add(servant);
      }
    }
    return servants;
  }

  Map<String, dynamic> _normalizeServantWriteData(ServantModel servant) {
    final data = servant.toMap();
    data['role'] = servant.role.name;

    if (servant.role != UserRole.servant) {
      // Clear servant-only scoping fields when user is no longer a servant.
      data['groupId'] = FieldValue.delete();
      data['assignedTeamId'] = FieldValue.delete();
      data['assignedTeamIds'] = FieldValue.delete();
    }

    return data;
  }

  @override
  Future<ServantModel?> getServantById(
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
  Future<ServantModel?> getServantByUid(
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
  Future<({List<ServantModel> servants, bool isFromCache})>
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
    } catch (e) {
      // Cache miss or other cache error is expected, fallback to server
    }

    try {
      final serverSnapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.server));
      return (
        servants: _servantsFromDocs(serverSnapshot.docs, includeArchived),
        isFromCache: false,
      );
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<ServantModel>> getAllServants({
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
    } catch (e) {
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
  Future<List<ServantModel>> getServantsByTeam(
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
      } catch (e) {
        // Cache miss or other cache error is expected, fallback to server
      }

      final snapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: teamName)
          .get(const GetOptions(source: Source.server));

      return _servantsFromDocs(snapshot.docs, includeArchived);
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<ServantModel>> searchServants(
    String query, {
    int limit = 20,
    bool includeArchived = false,
  }) async {
    try {
      if (query.isEmpty) {
        return getAllServants(limit: limit, includeArchived: includeArchived);
      }

      final snapshot = await _sortedServantsQuery()
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get();

      return _servantsFromDocs(snapshot.docs, includeArchived);
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Stream<List<ServantModel>> getServantsStream({bool includeArchived = false}) {
    return _sortedServantsQuery().snapshots().map((snapshot) {
      return _servantsFromDocs(snapshot.docs, includeArchived);
    });
  }

  @override
  Future<String> createServant(ServantModel servant) async {
    try {
      final normalizedUid = servant.uid?.trim();
      final docId = (normalizedUid != null && normalizedUid.isNotEmpty)
          ? normalizedUid
          : _usersCollection.doc().id;
      final normalizedServant = servant.copyWith(
        docID: docId,
        uid: normalizedUid == null || normalizedUid.isEmpty
            ? servant.uid
            : normalizedUid,
      );
      final data = _normalizeServantWriteData(normalizedServant);
      await _usersCollection.doc(docId).set(data, SetOptions(merge: true));
      return docId;
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> upsertServant(ServantModel servant) async {
    try {
      final data = _normalizeServantWriteData(servant);

      await _usersCollection
          .doc(servant.docID)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> updateServant(ServantModel servant) async {
    try {
      final oldServant = await getServantById(
        servant.docID,
        includeArchived: true,
      );
      final data = _normalizeServantWriteData(servant);
      await _usersCollection.doc(servant.docID).update(data);

      if (oldServant != null && oldServant.name != servant.name) {
        await propagateServantNameToTeams(
          servantUid: servant.docID,
          newName: servant.name,
        );
      }
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> updateServantFields(
    String docId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _usersCollection.doc(docId).update(fields);
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
      await _usersCollection.doc(docId).set({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedByUserId': performedByUid.trim().isEmpty
            ? 'system'
            : performedByUid,
        'restorePendingPasswordReset': false,
        'assignedTeamId': FieldValue.delete(),
        'assignedTeamIds': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      final updates = <String, dynamic>{
        'isArchived': false,
        'restorePendingPasswordReset': true,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredByUserId': performedByUid.trim().isEmpty
            ? 'system'
            : performedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (assignedTeamId != null) {
        updates['assignedTeamId'] = assignedTeamId;
      }
      if (assignedTeamIds != null) {
        updates['assignedTeamIds'] = assignedTeamIds;
      }

      await _usersCollection.doc(docId).set(updates, SetOptions(merge: true));
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  /// Propagates a servant's name change to all teams where this servant
  /// is assigned as the responsible servant (NFR-04.2(a)).
  ///
  /// This is the single update owner for `assignedServantName` denormalization.
  /// Called after servant name is successfully updated. Best-effort: catches
  /// and logs failures via debugPrint rather than throwing.
  /// Chunks updates into batches of 500 to respect Firestore limits.
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

      final chunks = teamsSnapshot.docs.chunk(500);
      for (final chunk in chunks) {
        final batch = _firestore.batch();
        for (final teamDoc in chunk) {
          batch.update(teamDoc.reference, {
            'assignedServantName': newName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      developer.log(
        'Failed to propagate servant name to teams',
        error: e,
        name: 'ServantDataRepository',
      );
    }
  }
}
