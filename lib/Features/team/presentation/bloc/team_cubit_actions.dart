// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

part of 'team_cubit.dart';

extension TeamCubitActions on TeamCubit {
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
    required String errorContext,
    required String errorMessage,
  }) async {
    emit(const TeamLoading());
    try {
      final teams = await action();
      _currentTeams = teams;
      _selectedTeamId = selectedTeamId;
      _includeArchived = includeArchived;
      emit(TeamLoaded(teams: teams, selectedTeamId: selectedTeamId));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('TeamCubit: $errorContext (${error.runtimeType})');
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
        _currentTeams = await _getTeamsUseCase.byGroup(
          reloadGroupId,
          includeArchived: _includeArchived,
        );
      }
      emit(
        TeamLoaded(
          teams: _currentTeams,
          selectedTeamId: _selectedTeamId,
          mutationStatus: TeamMutationStatus.success,
          feedbackMessage: successMessage,
        ),
      );
      if (reloadGroupId == null && _currentTeams.isEmpty) {
        emit(TeamLoaded(teams: _currentTeams, selectedTeamId: _selectedTeamId));
      }
    } catch (error) {
      _emitUserFacingError(errorContext, error, errorMessage);
    }
  }

  Future<void> loadTeamsByGroup(
    String groupId, {
    String? defaultTeamId,
    bool includeArchived = false,
  }) async {
    await _runTeamLoad(
      action: () =>
          _getTeamsUseCase.byGroup(groupId, includeArchived: includeArchived),
      selectedTeamId: defaultTeamId,
      includeArchived: includeArchived,
      errorContext: 'Failed to load teams',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  Future<void> loadAllTeams({bool includeArchived = false}) async {
    await _runTeamLoad(
      action: () => _getTeamsUseCase.all(includeArchived: includeArchived),
      includeArchived: includeArchived,
      errorContext: 'Failed to load all teams',
      errorMessage: 'تعذر تحميل الفرق. تحقق من الاتصال وحاول مرة أخرى.',
    );
  }

  Future<void> createTeam(TeamModel team) async {
    await _runTeamMutation(
      action: () => _createTeamUseCase(team),
      successMessage: 'تم إنشاء الفريق بنجاح',
      errorContext: 'Failed to create team',
      errorMessage: 'تعذر إنشاء الفريق. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }

  Future<void> updateTeam(TeamModel team) async {
    await _runTeamMutation(
      action: () => _teamRepository.updateTeam(team),
      successMessage: 'تم تحديث الفريق بنجاح',
      errorContext: 'Failed to update team',
      errorMessage: 'تعذر تحديث الفريق. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }

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

  Future<void> assignServant({
    required AuthUser actor,
    required TeamModel team,
    required ServantModel servant,
  }) async {
    await _runTeamMutation(
      action: () => _assignServantToTeamUseCase.assign(
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

  Future<void> unassignServant({
    required AuthUser actor,
    required TeamModel team,
  }) async {
    await _runTeamMutation(
      action: () =>
          _assignServantToTeamUseCase.unassign(actor: actor, team: team),
      successMessage: 'تم إلغاء تعيين الخادم بنجاح',
      errorContext: 'Failed to unassign servant',
      errorMessage: 'تعذر إلغاء تعيين الخادم. حاول مرة أخرى.',
      reloadGroupId: team.groupId,
    );
  }

  Future<void> setTeamMembers({
    required AuthUser actor,
    required TeamModel team,
    required List<StudentModel> students,
  }) async {
    await _runTeamMutation(
      action: () => _assignServantToTeamUseCase.setMembers(
        actor: actor,
        team: team,
        students: students,
      ),
      successMessage: 'تم تحديث أعضاء الفريق بنجاح',
      errorContext: 'Failed to set team members',
      errorMessage: 'تعذر تحديث أعضاء الفريق. حاول مرة أخرى.',
    );
  }
}
