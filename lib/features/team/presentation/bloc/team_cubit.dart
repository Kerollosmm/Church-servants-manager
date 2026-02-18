import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:church_managment_system/features/admin/data/admin_team_service.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'team_state.dart';

/// Cubit for managing team/class data.
/// - Admin: full CRUD across all groups
/// - Servant: load teams for their group
class TeamCubit extends Cubit<TeamState> {
  final TeamRepository _teamRepository;
  final AdminTeamService _adminTeamService;

  TeamCubit({
    required TeamRepository teamRepository,
    required AdminTeamService adminTeamService,
  }) : _teamRepository = teamRepository,
       _adminTeamService = adminTeamService,
       super(const TeamInitial());

  void _emitUserFacingError(
    String contextLabel,
    Object error,
    String userMessage,
  ) {
    debugPrint('TeamCubit: $contextLabel - $error');
    emit(TeamError(userMessage));
  }

  /// Load teams for a specific group/year.
  Future<void> loadTeamsByGroup(String groupId, {String? defaultTeamId}) async {
    emit(const TeamLoading());
    try {
      final teams = await _teamRepository.getTeamsByGroup(groupId);
      emit(TeamLoaded(teams: teams, selectedTeamId: defaultTeamId));
    } catch (e) {
      _emitUserFacingError(
        'Failed to load teams',
        e,
        'Could not load teams. Check internet and try again.',
      );
    }
  }

  /// Load all teams across all groups (admin use).
  Future<void> loadAllTeams() async {
    emit(const TeamLoading());
    try {
      final teams = await _teamRepository.getAllTeams();
      emit(TeamLoaded(teams: teams));
    } catch (e) {
      _emitUserFacingError(
        'Failed to load all teams',
        e,
        'Could not load teams. Check internet and try again.',
      );
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
      _emitUserFacingError(
        'Failed to create team',
        e,
        'Could not create team. Please try again.',
      );
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
      _emitUserFacingError(
        'Failed to update team',
        e,
        'Could not update team. Please try again.',
      );
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
      _emitUserFacingError(
        'Failed to delete team',
        e,
        'Could not delete team. Please try again.',
      );
    }
  }

  /// Select a team (for dropdown usage).
  void selectTeam(String? teamId) {
    final currentState = state;
    if (currentState is TeamLoaded) {
      emit(TeamLoaded(teams: currentState.teams, selectedTeamId: teamId));
    }
  }

  /// Admin: assign a responsible servant to a team.
  Future<void> assignServant({
    required AuthUser actor,
    required TeamModel team,
    required ServantModel servant,
  }) async {
    emit(const TeamLoading());
    try {
      await _adminTeamService.assignServantToTeam(
        actor: actor,
        team: team,
        servant: servant,
      );
      emit(const TeamOperationSuccess('Servant assigned successfully'));
      await loadTeamsByGroup(team.groupId);
    } catch (e) {
      _emitUserFacingError(
        'Failed to assign servant',
        e,
        'Could not assign servant. Please try again.',
      );
    }
  }

  /// Admin: unassign the responsible servant from a team.
  Future<void> unassignServant({
    required AuthUser actor,
    required TeamModel team,
  }) async {
    emit(const TeamLoading());
    try {
      await _adminTeamService.unassignServantFromTeam(actor: actor, team: team);
      emit(const TeamOperationSuccess('Servant unassigned successfully'));
      await loadTeamsByGroup(team.groupId);
    } catch (e) {
      _emitUserFacingError(
        'Failed to unassign servant',
        e,
        'Could not unassign servant. Please try again.',
      );
    }
  }

  /// Admin: set the members of a team (students).
  Future<void> setTeamMembers({
    required AuthUser actor,
    required TeamModel team,
    required List<StudentModel> students,
  }) async {
    emit(const TeamLoading());
    try {
      await _adminTeamService.setStudentsForTeam(
        actor: actor,
        team: team,
        selectedStudents: students,
      );
      emit(const TeamOperationSuccess('Team members updated successfully'));
    } catch (e) {
      _emitUserFacingError(
        'Failed to set team members',
        e,
        'Could not update team members. Please try again.',
      );
    }
  }
}
