import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/servant/domain/entities/servant_page.dart';

/// Domain interface for servant repository.
/// Enables dependency inversion: presentation and domain layers
/// depend on this abstraction, not concrete Firebase implementations.
abstract class IServantRepository {
  Future<Servant?> getServantById(String docId, {bool includeArchived = false});

  Future<Servant?> getServantByUid(String uid, {bool includeArchived = false});

  Future<({List<Servant> servants, bool isFromCache})>
  getServantsByGroupWithFallback(
    String groupId, {
    bool includeArchived = false,
  });

  Future<ServantsPage> getServantsPage({
    int limit = 50,
    PaginationCursor? cursor,
    bool includeArchived = false,
  });

  Future<List<Servant>> getAllServants({
    int limit = 20,
    PaginationCursor? cursor,
    bool includeArchived = false,
  });

  Future<List<Servant>> getServantsByTeam(
    String teamName, {
    bool includeArchived = false,
  });

  Future<List<Servant>> searchServants(
    String query, {
    int limit = 20,
    bool includeArchived = false,
  });

  Future<void> updateServant(Servant servant);

  Future<void> upsertServant(Servant servant);

  Future<void> updateServantFields(String docId, Map<String, dynamic> fields);

  Future<String> createServant(Servant servant);

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
