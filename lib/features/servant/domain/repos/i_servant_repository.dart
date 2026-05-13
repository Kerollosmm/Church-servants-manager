import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';

/// Domain interface for servant repository.
/// Enables dependency inversion: presentation and domain layers
/// depend on this abstraction, not concrete Firebase implementations.
abstract class IServantRepository {
  Future<ServantModel?> getServantById(String docId, {bool includeArchived = false});

  Future<ServantModel?> getServantByUid(String uid, {bool includeArchived = false});

  Future<({List<ServantModel> servants, bool isFromCache})>
  getServantsByGroupWithFallback(
    String groupId, {
    bool includeArchived = false,
  });

  Future<ServantsPage> getServantsPage({
    int limit = 50,
    PaginationCursor? cursor,
    bool includeArchived = false,
  });

  Future<List<ServantModel>> getAllServants({
    int limit = 20,
    PaginationCursor? cursor,
    bool includeArchived = false,
  });

  Future<List<ServantModel>> getServantsByTeam(
    String teamName, {
    bool includeArchived = false,
  });

  Future<List<ServantModel>> searchServants(
    String query, {
    int limit = 20,
    bool includeArchived = false,
  });

  Future<void> updateServant(ServantModel servant);

  Future<void> upsertServant(ServantModel servant);

  Future<void> updateServantFields(
    String docId,
    Map<String, dynamic> fields,
  );

  Future<String> createServant(ServantModel servant);

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
