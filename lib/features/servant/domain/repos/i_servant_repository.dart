import 'package:church_management_system/core/utils/pagination_cursor.dart';
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
    PaginationCursor? cursor,
    bool includeArchived,
  });

  Future<ServantsPage> getServantsPage({
    int limit,
    PaginationCursor? cursor,
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

  Future<String> createServant(ServantModel servant);

  Future<void> upsertServant(ServantModel servant);

  Future<void> updateServant(ServantModel servant);

  Future<void> updateServantFields(String docId, Map<String, dynamic> fields);

  Future<void> deleteServant(String docId, {required String performedByUid});

  Future<void> restoreServant(
    String docId, {
    required String performedByUid,
    String? assignedTeamId,
    List<String>? assignedTeamIds,
  });

  Future<void> propagateServantNameToTeams({
    required String servantUid,
    required String newName,
  });
}
