import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart'
    show ServantsPage;

/// Domain interface for servant repository.
/// Enables dependency inversion: presentation and domain layers
/// depend on this abstraction, not concrete Firebase implementations.
abstract class IServantRepository {
  Future<ServantModel?> getServantById(String docId, {bool includeArchived});

  Future<ServantModel?> getServantByUid(String uid, {bool includeArchived});

  Future<({List<ServantModel> servants, bool isFromCache})>
  getServantsByGroupWithFallback(String groupId, {bool includeArchived});

  Future<List<ServantModel>> getAllServants({
    int limit,
    DocumentSnapshot? lastDocument,
    bool includeArchived,
  });

  Future<ServantsPage> getServantsPage({
    int limit,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool includeArchived,
  });

  Future<List<ServantModel>> getServantsByTeam(
    String teamName, {
    bool includeArchived,
  });

  Future<List<ServantModel>> searchServants(
    String query, {
    int limit,
    bool includeArchived,
  });

  Stream<List<ServantModel>> getServantsStream({bool includeArchived});

  Future<String> createServant(ServantModel servant);

  Future<void> upsertServant(ServantModel servant);

  Future<void> updateServant(ServantModel servant);

  Future<void> updateServantFields(String docId, Map<String, dynamic> fields);

  Future<void> deleteServant(String docId);

  Future<void> restoreServant(
    String docId, {
    String? assignedTeamId,
    List<String>? assignedTeamIds,
  });

  Future<void> propagateServantNameToTeams({
    required String servantUid,
    required String newName,
  });
}
