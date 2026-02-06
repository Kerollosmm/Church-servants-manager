import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for Servant Repository.
abstract class IServantRepository {
  /// Get a single servant by document ID.
  Future<ServantModel?> getServantById(String docId);

  /// Get a servant by Firebase Auth UID.
  Future<ServantModel?> getServantByUid(String uid);

  /// Get all servants with pagination support.
  Future<List<ServantModel>> getAllServants({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  });

  /// Get servants by team name.
  Future<List<ServantModel>> getServantsByTeam(String teamName);

  /// Search servants by name.
  Future<List<ServantModel>> searchServants(String query, {int limit = 20});

  /// Get all servants as a stream.
  Stream<List<ServantModel>> getServantsStream();

  /// Create a new servant.
  Future<String> createServant(ServantModel servant);

  /// Upsert a servant document (merge).
  Future<void> upsertServant(ServantModel servant);

  /// Update an existing servant.
  Future<void> updateServant(ServantModel servant);

  /// Update specific fields of a servant.
  Future<void> updateServantFields(String docId, Map<String, dynamic> fields);

  /// Delete a servant by document ID.
  Future<void> deleteServant(String docId);
}
