import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';
import 'package:church_management_system/features/servant/domain/repo/i_servant_repository.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';

typedef _ServantDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

class ServantsPage {
  final List<ServantModel> servants;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
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

  ServantDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

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
    return docs
        .map((doc) => _servantFromData(doc.data(), doc.id, includeArchived))
        .whereType<ServantModel>()
        .toList();
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
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      if (data['role'] != UserRole.servant.name) return null;
      return _servantFromData(data, doc.id, includeArchived);
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
    } catch (_) {}

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
    DocumentSnapshot? lastDocument,
    bool includeArchived = false,
  }) async {
    Query<Map<String, dynamic>> query = _sortedServantsQuery();

    if (limit > 0) {
      query = query.limit(limit);
    }

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
    } catch (_) {}

    try {
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      return _servantsFromDocs(serverSnapshot.docs, includeArchived);
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  Future<ServantsPage> getServantsPage({
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool includeArchived = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _sortedServantsQuery().limit(
        limit + 1,
      );

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final hasMore = docs.length > limit;
      final pageDocs = hasMore ? docs.take(limit).toList() : docs;

      return ServantsPage(
        servants: _servantsFromDocs(pageDocs, includeArchived),
        lastDocument: pageDocs.isEmpty ? lastDocument : pageDocs.last,
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
    final baseQuery = _usersCollection
        .where('role', isEqualTo: UserRole.servant.name)
        .where('groupId', isEqualTo: teamName);

    try {
      final cacheSnapshot = await baseQuery.get(
        const GetOptions(source: Source.cache),
      );
      if (cacheSnapshot.docs.isNotEmpty) {
        return _servantsFromDocs(cacheSnapshot.docs, includeArchived);
      }
    } catch (_) {}

    try {
      final snapshot = await baseQuery.get(
        const GetOptions(source: Source.server),
      );
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
      final data = _normalizeServantWriteData(servant);
      await _usersCollection.doc(servant.docID).update(data);
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
  Future<void> deleteServant(String docId) async {
    try {
      await _usersCollection.doc(docId).set({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedByUserId': 'system',
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
  Future<void> restoreServant(String docId) async {
    try {
      await _usersCollection.doc(docId).set({
        'isArchived': false,
        'restorePendingPasswordReset': true,
        'restoredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }
}
