import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'team_state.dart';

/// Cubit for managing team/class data.
/// - Admin: full CRUD across all groups
/// - Servant: load teams for their group
class TeamCubit extends Cubit<TeamState> {
  final TeamRepository _teamRepository;
  final AdminTeamService _adminTeamService;
  List<TeamModel> _currentTeams = const [];
  String? _selectedTeamId;
  bool _includeArchived = false;
  String? _currentLoadGroupId;

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
    if (kDebugMode) {
      debugPrint('TeamCubit: $contextLabel (${error.runtimeType})');
    }
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

  Future<void> _runTeamLoad({
    required Future<List<TeamModel>> Function() action,
    String? selectedTeamId,
    bool includeArchived = false,
    String? loadGroupId,
    required String errorContext,
    required String errorMessage,
  }) async {
    emit(const TeamLoading());
    try {
      final teams = await action();
      _currentTeams = teams;
      _selectedTeamId = selectedTeamId;
      _includeArchived = includeArchived;
      _currentLoadGroupId = loadGroupId;
      emit(TeamLoaded(teams: teams, selectedTeamId: selectedTeamId));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TeamCubit: $errorContext (${e.runtimeType})');
      }
      emit(TeamError(errorMessage));
    }
  }

  Future<void> _runTeamMutation({
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
      _emitUserFacingError(errorContext, e, errorMessage);
    }
  }

  /// Load teams for a specific group/year.
  Future<void> loadTeamsByGroup(
    String groupId, {
    String? defaultTeamId,
    bool includeArchived = false,
  }) async {
    await _runTeamLoad(
      action: () => _teamRepository.getTeamsByGroup(
        groupId,
        includeArchived: includeArchived,
      ),
      selectedTeamId: defaultTeamId,
      includeArchived: includeArchived,
      loadGroupId: groupId,
      errorContext: 'Failed to load teams',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  /// Load all teams across all groups (admin use).
  Future<void> loadAllTeams({bool includeArchived = false}) async {
    await _runTeamLoad(
      action: () =>
          _teamRepository.getAllTeams(includeArchived: includeArchived),
      includeArchived: includeArchived,
      loadGroupId: null,
      errorContext: 'Failed to load all teams',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  /// Load teams by specific IDs (for servants with assignedTeamIds but no groupId).
  Future<void> loadTeamsByIds(
    List<String> ids, {
    String? defaultTeamId,
    bool includeArchived = false,
  }) async {
    await _runTeamLoad(
      action: () async {
        final allTeams = await _teamRepository.getAllTeams(
          includeArchived: includeArchived,
        );
        final idSet = ids.toSet();
        return allTeams.where((t) => idSet.contains(t.id)).toList();
      },
      selectedTeamId: defaultTeamId,
      includeArchived: includeArchived,
      loadGroupId: null,
      errorContext: 'Failed to load teams by IDs',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  /// Create a new team (admin only).
  Future<void> createTeam(TeamModel team) async {
    await _runTeamMutation(
      action: () => _teamRepository.createTeam(team),
      successMessage: 'تم إنشاء الفريق بنجاح',
      errorContext: 'Failed to create team',
      errorMessage: 'تعذر إنشاء الفريق. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }

  /// Update an existing team (admin only).
  Future<void> updateTeam(TeamModel team) async {
    await _runTeamMutation(
      action: () => _teamRepository.updateTeam(team),
      successMessage: 'تم تحديث الفريق بنجاح',
      errorContext: 'Failed to update team',
      errorMessage: 'تعذر تحديث الفريق. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }

  /// Delete a team (admin only).
  Future<void> deleteTeam(String teamId, String groupId) async {
    await _runTeamMutation(
      action: () => _teamRepository.deleteTeam(teamId),
      successMessage: 'تمت أرشفة الفريق بنجاح',
      errorContext: 'Failed to archive team',
      errorMessage: 'تعذر أرشفة الفريق. حاول مرة أخرى.',
      reloadGroupId: groupId,
    );
  }

  Future<void> restoreTeam(String teamId, String groupId) async {
    await _runTeamMutation(
      action: () => _teamRepository.restoreTeam(teamId),
      successMessage: 'تمت استعادة الفريق بنجاح',
      errorContext: 'Failed to restore team',
      errorMessage: 'تعذر استعادة الفريق. حاول مرة أخرى.',
      reloadGroupId: groupId,
    );
  }

  /// Select a team (for dropdown usage).
  void selectTeam(String? teamId) {
    _selectedTeamId = teamId;
    final currentState = state;
    if (currentState is TeamLoaded) {
      emit(
        currentState.copyWith(
          selectedTeamId: teamId,
          mutationStatus: TeamMutationStatus.idle,
          clearFeedbackMessage: true,
        ),
      );
    }
  }

  /// Admin: assign a responsible servant to a team.
  Future<void> assignServant({
    required AuthUser actor,
    required TeamModel team,
    required ServantModel servant,
  }) async {
    await _runTeamMutation(
      action: () => _adminTeamService.assignServantToTeam(
        actor: actor,
        team: team,
        servant: servant,
      ),
      successMessage: 'تم تعيين الخادم بنجاح',
      errorContext: 'Failed to assign servant',
      errorMessage: 'تعذر تعيين الخادم. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }

  /// Admin: unassign the responsible servant from a team.
  Future<void> unassignServant({
    required AuthUser actor,
    required TeamModel team,
  }) async {
    await _runTeamMutation(
      action: () =>
          _adminTeamService.unassignServantFromTeam(actor: actor, team: team),
      successMessage: 'تم إلغاء تعيين الخادم بنجاح',
      errorContext: 'Failed to unassign servant',
      errorMessage: 'تعذر إلغاء تعيين الخادم. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }

  /// Admin: set the members of a team (students).
  Future<void> setTeamMembers({
    required AuthUser actor,
    required TeamModel team,
    required List<StudentModel> students,
  }) async {
    await _runTeamMutation(
      action: () => _adminTeamService.setStudentsForTeam(
        actor: actor,
        team: team,
        selectedStudents: students,
      ),
      successMessage: 'تم تحديث أعضاء الفريق بنجاح',
      errorContext: 'Failed to set team members',
      errorMessage: 'تعذر تحديث أعضاء الفريق. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }
}
