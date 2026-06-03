import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/entities/team.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentFormTeamsState {
  final bool isLoading;
  final List<Team> teams;
  final String? selectedTeamId;
  final String? errorMessage;

  const StudentFormTeamsState({
    this.isLoading = false,
    this.teams = const <Team>[],
    this.selectedTeamId,
    this.errorMessage,
  });

  StudentFormTeamsState copyWith({
    bool? isLoading,
    List<Team>? teams,
    String? selectedTeamId,
    bool clearSelectedTeamId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return StudentFormTeamsState(
      isLoading: isLoading ?? this.isLoading,
      teams: teams ?? this.teams,
      selectedTeamId: clearSelectedTeamId
          ? null
          : (selectedTeamId ?? this.selectedTeamId),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

class StudentFormTeamsCubit extends Cubit<StudentFormTeamsState> {
  StudentFormTeamsCubit({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const StudentFormTeamsState());

  final TeamRepository _teamRepository;

  Future<void> loadTeamsForGroup({
    required AuthUser actor,
    required String groupId,
    String? preferredTeamId,
    String? preferredTeamName,
    String? currentSelection,
  }) async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final assignedTeamIds = actor.effectiveAssignedTeamIds.toSet();
      final teamsFromRepo = await _teamRepository.getTeamsByGroup(groupId);
      var visibleTeams = teamsFromRepo;

      if (actor.role == UserRole.servant && assignedTeamIds.isNotEmpty) {
        visibleTeams = teamsFromRepo
            .where((team) => assignedTeamIds.contains(team.id))
            .toList(growable: false);
      }

      final validTeamIds = visibleTeams.map((team) => team.id).toSet();
      String? resolvedTeamId;

      if (preferredTeamId != null && validTeamIds.contains(preferredTeamId)) {
        resolvedTeamId = preferredTeamId;
      }
      if (resolvedTeamId == null &&
          preferredTeamName != null &&
          preferredTeamName.isNotEmpty) {
        for (final team in visibleTeams) {
          if (team.name.trim() == preferredTeamName.trim()) {
            resolvedTeamId = team.id;
            break;
          }
        }
      }
      if (resolvedTeamId == null &&
          currentSelection != null &&
          validTeamIds.contains(currentSelection)) {
        resolvedTeamId = currentSelection;
      }
      if (resolvedTeamId == null &&
          actor.role == UserRole.servant &&
          assignedTeamIds.length == 1 &&
          validTeamIds.contains(actor.effectiveAssignedTeamIds.first)) {
        resolvedTeamId = actor.effectiveAssignedTeamIds.first;
      }

      emit(
        StudentFormTeamsState(
          teams: visibleTeams,
          selectedTeamId: resolvedTeamId,
        ),
      );
    } catch (error) {
      developer.log(
        'failed to load teams',
        error: error,
        name: 'StudentFormTeamsCubit',
      );
      emit(
        const StudentFormTeamsState(
          errorMessage: 'تعذر تحميل الفرق. حاول مرة أخرى.',
        ),
      );
    }
  }

  void selectTeam(String? teamId) {
    emit(state.copyWith(selectedTeamId: teamId, clearErrorMessage: true));
  }
}
