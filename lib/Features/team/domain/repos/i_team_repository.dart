import 'package:church_management_system/features/team/data/models/team_model.dart';

/// Interface for team repository operations.
abstract class ITeamRepository {
  /// Get all teams for a specific group/year.
  Future<List<TeamModel>> getTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
  });

  /// Watch all teams for a specific group/year.
  Stream<List<TeamModel>> watchTeamsByGroup(
    String groupId, {
    bool includeArchived = false,
  });

  /// Get all teams across all groups.
  Future<List<TeamModel>> getAllTeams({bool includeArchived = false});

  /// Watch all teams across all groups.
  Stream<List<TeamModel>> watchAllTeams({bool includeArchived = false});

  /// Get a single team by its document ID.
  Future<TeamModel?> getTeamById(String id, {bool includeArchived = false});

  /// Create a new team. Returns the Firestore document ID.
  Future<String> createTeam(TeamModel team);

  /// Update an existing team.
  Future<void> updateTeam(TeamModel team);

  /// Delete a team by its document ID.
  Future<void> deleteTeam(String id, {required String performedByUid});

  /// Restore an archived team by its document ID.
  Future<void> restoreTeam(String id, {required String performedByUid});
}
