import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'team_state.dart';

/// Cubit for managing team/class data.
/// - Admin: full CRUD across all groups
/// - Servant: load teams for their group
class TeamCubit extends Cubit<TeamState> {
  final TeamRepository _teamRepository;

  TeamCubit({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const TeamInitial());

  /// Load teams for a specific group/year.
  Future<void> loadTeamsByGroup(String groupId, {String? defaultTeamId}) async {
    emit(const TeamLoading());
    try {
      final teams = await _teamRepository.getTeamsByGroup(groupId);
      emit(TeamLoaded(teams: teams, selectedTeamId: defaultTeamId));
    } catch (e) {
      debugPrint('TeamCubit: Failed to load teams - $e');
      emit(TeamError('Failed to load teams: $e'));
    }
  }

  /// Load all teams across all groups (admin use).
  Future<void> loadAllTeams() async {
    emit(const TeamLoading());
    try {
      final teams = await _teamRepository.getAllTeams();
      emit(TeamLoaded(teams: teams));
    } catch (e) {
      debugPrint('TeamCubit: Failed to load all teams - $e');
      emit(TeamError('Failed to load teams: $e'));
    }
  }

  /// Create a new team (admin only).
  Future<void> createTeam(TeamModel team) async {
    emit(const TeamLoading());
    try {
      await _teamRepository.createTeam(team);
      emit(const TeamOperationSuccess('Team created successfully'));
      // Reload teams for the group this team belongs to.
      await loadTeamsByGroup(team.groupId);
    } catch (e) {
      debugPrint('TeamCubit: Failed to create team - $e');
      emit(TeamError('Failed to create team: $e'));
    }
  }

  /// Update an existing team (admin only).
  Future<void> updateTeam(TeamModel team) async {
    emit(const TeamLoading());
    try {
      await _teamRepository.updateTeam(team);
      emit(const TeamOperationSuccess('Team updated successfully'));
      await loadTeamsByGroup(team.groupId);
    } catch (e) {
      debugPrint('TeamCubit: Failed to update team - $e');
      emit(TeamError('Failed to update team: $e'));
    }
  }

  /// Delete a team (admin only).
  Future<void> deleteTeam(String teamId, String groupId) async {
    emit(const TeamLoading());
    try {
      await _teamRepository.deleteTeam(teamId);
      emit(const TeamOperationSuccess('Team deleted successfully'));
      await loadTeamsByGroup(groupId);
    } catch (e) {
      debugPrint('TeamCubit: Failed to delete team - $e');
      emit(TeamError('Failed to delete team: $e'));
    }
  }

  /// Select a team (for dropdown usage).
  void selectTeam(String? teamId) {
    final currentState = state;
    if (currentState is TeamLoaded) {
      emit(TeamLoaded(teams: currentState.teams, selectedTeamId: teamId));
    }
  }
}
