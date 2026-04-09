import 'package:church_management_system/features/team/data/models/team_model.dart';

/// Domain interface for team repository.
/// Enables dependency inversion: presentation and domain layers
/// depend on this abstraction, not concrete Firebase implementations.
abstract class ITeamRepository {
  Future<List<TeamModel>> getAllTeams({bool includeArchived});

  Future<List<TeamModel>> getTeamsByGroup(
    String groupId, {
    bool includeArchived,
  });

  Future<List<TeamModel>> getTeamsByIds(
    List<String> ids, {
    bool includeArchived,
  });

  Stream<List<TeamModel>> watchTeamsByGroup(
    String groupId, {
    bool includeArchived,
  });

  Stream<List<TeamModel>> watchAllTeams({bool includeArchived});

  Future<TeamModel?> getTeamById(String docId);

  Future<String> createTeam(TeamModel team);

  Future<void> updateTeam(TeamModel team);

  Future<void> deleteTeam(String docId);

  Future<void> restoreTeam(String docId);
}
