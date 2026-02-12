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

  @override
  Future<List<ServantModel>> getAllServants({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .orderBy('name')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<List<ServantModel>> getServantsByTeam(String teamName) async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: UserRole.servant.name)
          .where('groupId', isEqualTo: teamName)
          .get();

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
      final docRef = _usersCollection.doc();
      final data = servant.copyWith(docID: docRef.id).toMap();
      // Ensure role is strictly set to servant
      data['role'] = UserRole.servant.name;
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw mapExceptionToServantFailure(e);
    }
  }

  @override
  Future<void> upsertServant(ServantModel servant) async {
    try {
      final Map<String, dynamic> data = servant.toMap();
      // Ensure role is strictly set to servant
      data['role'] = UserRole.servant.name;

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
      final data = servant.toMap();
      // Role should generally not be changed here unless intended, but good to keep consistency
      data['role'] = UserRole.servant.name;
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
