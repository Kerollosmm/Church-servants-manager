import 'dart:developer' as developer;

import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/entities/team.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'team_event.dart';
part 'team_state.dart';

/// Bloc for managing team/class data.
/// - Admin: full CRUD across all groups
/// - Servant: load teams for their group
class TeamBloc extends Bloc<TeamEvent, TeamState> {
  final TeamRepository _teamRepository;
  final AdminTeamService _adminTeamService;
  List<Team> _currentTeams = const [];
  String? _selectedTeamId;
  bool _includeArchived = false;
  String? _currentLoadGroupId;

  TeamBloc({
    required TeamRepository teamRepository,
    required AdminTeamService adminTeamService,
  }) : _teamRepository = teamRepository,
       _adminTeamService = adminTeamService,
       super(const TeamInitial()) {
    on<TeamLoadRequested>(_onTeamLoadRequested);
    on<TeamLoadAllRequested>(_onTeamLoadAllRequested);
    on<TeamLoadByIdsRequested>(_onTeamLoadByIdsRequested);
    on<TeamCreateRequested>(_onTeamCreateRequested);
    on<TeamUpdateRequested>(_onTeamUpdateRequested);
    on<TeamDeleteRequested>(_onTeamDeleteRequested);
    on<TeamRestoreRequested>(_onTeamRestoreRequested);
    on<TeamSelected>(_onTeamSelected);
    on<ServantAssignedToTeam>(_onServantAssignedToTeam);
    on<ServantUnassignedFromTeam>(_onServantUnassignedFromTeam);
    on<TeamMembersSet>(_onTeamMembersSet);
  }

  void _emitUserFacingError(
    Emitter<TeamState> emit,
    String contextLabel,
    Object error,
    String userMessage,
  ) {
    developer.log(contextLabel, error: error, name: 'TeamBloc');
    if (_currentTeams.isNotEmpty) {
      emit(
        TeamLoaded(
          teams: _currentTeams,
          selectedTeamId: _selectedTeamId,
          mutationStatus: TeamMutationStatus.failure,
          feedbackMessage: userMessage,
        ),
      );
      return;
    }
    emit(TeamError(userMessage));
  }

  Future<void> _runTeamLoad(
    Emitter<TeamState> emit, {
    required Future<({List<Team> teams, bool isFromCache})> Function() action,
    String? selectedTeamId,
    bool includeArchived = false,
    String? loadGroupId,
    required String errorContext,
    required String errorMessage,
  }) async {
    emit(const TeamLoading());
    try {
      final result = await action();
      _currentTeams = result.teams;
      _selectedTeamId = selectedTeamId;
      _includeArchived = includeArchived;
      _currentLoadGroupId = loadGroupId;
      emit(
        TeamLoaded(
          teams: result.teams,
          selectedTeamId: selectedTeamId,
          isFromCache: result.isFromCache,
        ),
      );
    } catch (e) {
      developer.log(errorContext, error: e, name: 'TeamBloc');
      emit(TeamError(errorMessage));
    }
  }

  Future<void> _runTeamMutation(
    Emitter<TeamState> emit, {
    required Future<void> Function() action,
    required String successMessage,
    required String errorContext,
    required String errorMessage,
    String? reloadGroupId,
  }) async {
    if (_currentTeams.isNotEmpty) {
      emit(
        TeamLoaded(
          teams: _currentTeams,
          selectedTeamId: _selectedTeamId,
          mutationStatus: TeamMutationStatus.inProgress,
        ),
      );
    } else {
      emit(const TeamLoading());
    }
    try {
      await action();
      if (reloadGroupId != null) {
        final teams = await _teamRepository.getTeamsByGroup(
          reloadGroupId,
          includeArchived: _includeArchived,
        );
        _currentTeams = teams;
        _currentLoadGroupId = reloadGroupId;
      } else if (_currentLoadGroupId != null) {
        final teams = await _teamRepository.getTeamsByGroup(
          _currentLoadGroupId!,
          includeArchived: _includeArchived,
        );
        _currentTeams = teams;
      }
      emit(
        TeamLoaded(
          teams: _currentTeams,
          selectedTeamId: _selectedTeamId,
          mutationStatus: TeamMutationStatus.success,
          feedbackMessage: successMessage,
        ),
      );
    } catch (e) {
      _emitUserFacingError(emit, errorContext, e, errorMessage);
    }
  }

  Future<void> _onTeamLoadRequested(
    TeamLoadRequested event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamLoad(
      emit,
      action: () => _teamRepository.getTeamsByGroupWithFallback(
        event.groupId,
        includeArchived: event.includeArchived,
      ),
      selectedTeamId: event.defaultTeamId,
      includeArchived: event.includeArchived,
      loadGroupId: event.groupId,
      errorContext: 'Failed to load teams',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  Future<void> _onTeamLoadAllRequested(
    TeamLoadAllRequested event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamLoad(
      emit,
      action: () async {
        final teams = await _teamRepository.getAllTeams(
          includeArchived: event.includeArchived,
        );
        return (teams: teams, isFromCache: false);
      },
      includeArchived: event.includeArchived,
      errorContext: 'Failed to load all teams',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  Future<void> _onTeamLoadByIdsRequested(
    TeamLoadByIdsRequested event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamLoad(
      emit,
      action: () async {
        final teams = await _teamRepository.getTeamsByIds(
          event.ids,
          includeArchived: event.includeArchived,
        );
        return (teams: teams, isFromCache: false);
      },
      selectedTeamId: event.defaultTeamId,
      includeArchived: event.includeArchived,
      errorContext: 'Failed to load teams by IDs',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  Future<void> _onTeamCreateRequested(
    TeamCreateRequested event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamMutation(
      emit,
      action: () => _teamRepository.createTeam(event.team),
      successMessage: 'تم إنشاء الفريق بنجاح',
      errorContext: 'Failed to create team',
      errorMessage: 'تعذر إنشاء الفريق. حاول مرة أخرى.',
      reloadGroupId: event.team.groupId,
    );
  }

  Future<void> _onTeamUpdateRequested(
    TeamUpdateRequested event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamMutation(
      emit,
      action: () => _teamRepository.updateTeam(event.team),
      successMessage: 'تم تحديث الفريق بنجاح',
      errorContext: 'Failed to update team',
      errorMessage: 'تعذر تحديث الفريق. حاول مرة أخرى.',
      reloadGroupId: event.team.groupId,
    );
  }

  Future<void> _onTeamDeleteRequested(
    TeamDeleteRequested event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamMutation(
      emit,
      action: () => _teamRepository.deleteTeam(event.teamId),
      successMessage: 'تمت أرشفة الفريق بنجاح',
      errorContext: 'Failed to archive team',
      errorMessage: 'تعذر أرشفة الفريق. حاول مرة أخرى.',
      reloadGroupId: event.groupId,
    );
  }

  Future<void> _onTeamRestoreRequested(
    TeamRestoreRequested event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamMutation(
      emit,
      action: () => _teamRepository.restoreTeam(event.teamId),
      successMessage: 'تمت استعادة الفريق بنجاح',
      errorContext: 'Failed to restore team',
      errorMessage: 'تعذر استعادة الفريق. حاول مرة أخرى.',
      reloadGroupId: event.groupId,
    );
  }

  void _onTeamSelected(TeamSelected event, Emitter<TeamState> emit) {
    _selectedTeamId = event.teamId;
    final currentState = state;
    if (currentState is TeamLoaded) {
      emit(
        currentState.copyWith(
          selectedTeamId: event.teamId,
          mutationStatus: TeamMutationStatus.idle,
          clearFeedbackMessage: true,
        ),
      );
    }
  }

  Future<void> _onServantAssignedToTeam(
    ServantAssignedToTeam event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamMutation(
      emit,
      action: () => _adminTeamService.assignServantToTeam(
        actor: event.actor,
        team: event.team,
        servant: event.servant,
      ),
      successMessage: 'تم تعيين الخادم بنجاح',
      errorContext: 'Failed to assign servant',
      errorMessage: 'تعذر تعيين الخادم. حاول مرة أخرى.',
      reloadGroupId: event.team.groupId,
    );
  }

  Future<void> _onServantUnassignedFromTeam(
    ServantUnassignedFromTeam event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamMutation(
      emit,
      action: () => _adminTeamService.unassignServantFromTeam(
        actor: event.actor,
        team: event.team,
      ),
      successMessage: 'تم إلغاء تعيين الخادم بنجاح',
      errorContext: 'Failed to unassign servant',
      errorMessage: 'تعذر إلغاء تعيين الخادم. حاول مرة أخرى.',
      reloadGroupId: event.team.groupId,
    );
  }

  Future<void> _onTeamMembersSet(
    TeamMembersSet event,
    Emitter<TeamState> emit,
  ) async {
    await _runTeamMutation(
      emit,
      action: () => _adminTeamService.setStudentsForTeam(
        actor: event.actor,
        team: event.team,
        selectedStudents: event.students,
      ),
      successMessage: 'تم تحديث أعضاء الفريق بنجاح',
      errorContext: 'Failed to set team members',
      errorMessage: 'تعذر تحديث أعضاء الفريق. حاول مرة أخرى.',
      reloadGroupId: event.team.groupId,
    );
  }
}
