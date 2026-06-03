import 'package:church_management_system/features/team/domain/entities/team.dart';

/// Domain interface for team repository.
/// Enables dependency inversion: presentation and domain layers
/// depend on this abstraction, not concrete Firebase implementations.
abstract class ITeamRepository {
  Future<List<Team>> getAllTeams({bool includeArchived});

  Future<List<Team>> getTeamsByGroup(String groupId, {bool includeArchived});

  Future<({List<Team> teams, bool isFromCache})> getTeamsByGroupWithFallback(
    String groupId, {
    bool includeArchived,
  });

  Future<List<Team>> getTeamsByIds(List<String> ids, {bool includeArchived});

  Future<Team?> getTeamById(String docId);

  Future<String> createTeam(Team team);

  Future<void> updateTeam(Team team);

  Future<void> deleteTeam(String docId);

  Future<void> restoreTeam(String docId);

  Future<void> syncOfflineCreate(Map<String, dynamic> payload);
  Future<void> syncOfflineUpdate(Map<String, dynamic> payload);
  Future<void> syncOfflineDelete(Map<String, dynamic> payload);
  Future<void> syncOfflineRestore(Map<String, dynamic> payload);
}
