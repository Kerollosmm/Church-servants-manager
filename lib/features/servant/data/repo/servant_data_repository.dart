import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/core/constants/firestore_collections.dart';
import '../models/servant_models.dart';

/// Repository for managing servant data.
/// Servants are stored in the Users collection with role == 'servant'.
class ServantDataRepository {
  final FirebaseFirestore _firestore;

  ServantDataRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to Users collection (servants are users with role == servant)
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  /// Base query for all servants (users with role == servant)
  Query<Map<String, dynamic>> get _servantsQuery =>
      _usersCollection.where('role', isEqualTo: 'servant');

  /// Get a single servant by document ID.
  Future<ServantModel?> getServantById(String docId) async {
    try {
      final doc = await _usersCollection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        // Verify this user has servant role
        final data = doc.data()!;
        if (data['role'] != 'servant') return null;
        return ServantModel.fromMap(data, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch servant: $e');
    }
  }

  /// Get a servant by Firebase Auth UID.
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
      throw Exception('Failed to fetch servant by uid: $e');
    }
  }

  /// Get all servants with pagination support.
  Future<List<ServantModel>> getAllServants({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _usersCollection
          .where('role', isEqualTo: 'servant')
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
      throw Exception('Failed to fetch servants: $e');
    }
  }

  /// Get servants by team name.
  Future<List<ServantModel>> getServantsByTeam(String teamName) async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: 'servant')
          .where('groupId', isEqualTo: teamName)
          .get();

      return snapshot.docs
          .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch servants by team: $e');
    }
  }

  /// Search servants by name (case-insensitive prefix search).
  Future<List<ServantModel>> searchServants(
    String query, {
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) return getAllServants(limit: limit);

      final snapshot = await _usersCollection
          .where('role', isEqualTo: 'servant')
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ServantModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to search servants: $e');
    }
  }

  /// Get all servants as a stream.
  Stream<List<ServantModel>> getServantsStream() {
    return _usersCollection.where('role', isEqualTo: 'servant').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return ServantModel.fromMap(doc.data(), doc.id);
        }).toList();
      },
    );
  }

  /// Create a new servant (adds a user with role = servant).
  Future<String> createServant(ServantModel servant) async {
    try {
      final docRef = _usersCollection.doc();
      final data = servant.copyWith(docID: docRef.id).toMap();
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create servant: $e');
    }
  }

  /// Upsert a servant document (merge).
  Future<void> upsertServant(ServantModel servant) async {
    try {
      await _usersCollection
          .doc(servant.docID)
          .set(servant.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to upsert servant: $e');
    }
  }

  /// Update an existing servant.
  Future<void> updateServant(ServantModel servant) async {
    try {
      final data = servant.toMap();
      await _usersCollection.doc(servant.docID).update(data);
    } catch (e) {
      throw Exception('Failed to update servant: $e');
    }
  }

  /// Update specific fields of a servant.
  Future<void> updateServantFields(
    String docId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _usersCollection.doc(docId).update(fields);
    } catch (e) {
      throw Exception('Failed to update servant fields: $e');
    }
  }

  /// Delete a servant by document ID.
  /// Note: This changes the user's role, not actually deleting them.
  Future<void> deleteServant(String docId) async {
    try {
      // Option 1: Actually delete the user document
      await _usersCollection.doc(docId).delete();
      // Option 2: If you want to just change role instead:
      // await _usersCollection.doc(docId).update({'role': 'student'});
    } catch (e) {
      throw Exception('Failed to delete servant: $e');
    }
  }
}
