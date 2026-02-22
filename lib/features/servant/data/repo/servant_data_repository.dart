import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/servant/domain/failures/servant_failures.dart';
import 'package:church_managment_system/features/servant/domain/repo/i_servant_repository.dart';
import '../models/servant_models.dart';

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
  Future<ServantModel?> getServantById(String docId) async {
    try {
      final doc = await _usersCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        // Verify this user has servant role
        final data = doc.data()!;
        if (data['role'] != UserRole.servant.name) return null;
        return ServantModel.fromMap(data, doc.id);
      }
      return null;
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<ServantModel?> getServantByUid(String uid) async {
    try {
      final canonicalDoc = await _usersCollection.doc(uid).get();
      if (canonicalDoc.exists && canonicalDoc.data() != null) {
        final data = canonicalDoc.data()!;
        if (data['role'] == UserRole.servant.name) {
          return ServantModel.fromMap(data, canonicalDoc.id);
        }
      }

      final snapshot = await _servantsQuery
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return ServantModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  Future<({List<ServantModel> servants, bool isFromCache})>
  getServantsByGroupWithFallback(String groupId) async {
    try {
      final cacheSnapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.cache));
      if (cacheSnapshot.docs.isNotEmpty) {
        return (
          servants: cacheSnapshot.docs
              .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
              .toList(growable: false),
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
        servants: serverSnapshot.docs
            .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
            .toList(growable: false),
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
  }) async {
    Query<Map<String, dynamic>> query = _usersCollection
        .where('role', isEqualTo: UserRole.servant.name)
        .orderBy('name')
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    try {
      final cacheSnapshot = await query.get(
        const GetOptions(source: Source.cache),
      );
      if (cacheSnapshot.docs.isNotEmpty) {
        return cacheSnapshot.docs
            .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (_) {}

    try {
      final serverSnapshot = await query.get(
        const GetOptions(source: Source.server),
      );
      return serverSnapshot.docs
          .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<ServantModel>> getServantsByTeam(String teamName) async {
    try {
      try {
        final cacheSnapshot = await _usersCollection
            .where('role', isEqualTo: UserRole.servant.name)
            .where('groupId', isEqualTo: teamName)
            .get(const GetOptions(source: Source.cache));

        if (cacheSnapshot.docs.isNotEmpty) {
          return cacheSnapshot.docs
              .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
              .toList();
        }
      } catch (_) {}

      final snapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: teamName)
          .get(const GetOptions(source: Source.server));

      return snapshot.docs
          .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<ServantModel>> searchServants(
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) return getAllServants(limit: limit);

      final snapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Stream<List<ServantModel>> getServantsStream() {
    return _usersCollection
        .where('role', isEqualTo: UserRole.servant.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ServantModel.fromMap(doc.data(), doc.id);
          }).toList();
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
      // Option 1: Actually delete the user document
      await _usersCollection.doc(docId).delete();
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }
}
