import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_form_teams_event.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_form_teams_state.dart'; // import state
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'student_form_teams_state.dart' show StudentFormTeamsState;

class StudentFormTeamsBloc
    extends Bloc<StudentFormTeamsEvent, StudentFormTeamsState> {
  final TeamRepository _teamRepository;

  StudentFormTeamsBloc({required TeamRepository teamRepository})
    : _teamRepository = teamRepository,
      super(const StudentFormTeamsState()) {
    on<LoadTeamsForGroupEvent>(_onLoadTeamsForGroup);
    on<SelectTeamEvent>(_onSelectTeam);
  }

  Future<void> _onLoadTeamsForGroup(
    LoadTeamsForGroupEvent event,
    Emitter<StudentFormTeamsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final assignedTeamIds = event.actor.effectiveAssignedTeamIds.toSet();
      final teamsFromRepo = await _teamRepository.getTeamsByGroup(
        event.groupId,
      );
      var visibleTeams = teamsFromRepo;

      if (event.actor.role == UserRole.servant && assignedTeamIds.isNotEmpty) {
        visibleTeams = teamsFromRepo
            .where((team) => assignedTeamIds.contains(team.id))
            .toList(growable: false);
      }

      final validTeamIds = visibleTeams.map((team) => team.id).toSet();
      String? resolvedTeamId;

      if (event.preferredTeamId != null &&
          validTeamIds.contains(event.preferredTeamId)) {
        resolvedTeamId = event.preferredTeamId;
      }
      if (resolvedTeamId == null &&
          event.preferredTeamName != null &&
          event.preferredTeamName!.isNotEmpty) {
        for (final team in visibleTeams) {
          if (team.name.trim() == event.preferredTeamName!.trim()) {
            resolvedTeamId = team.id;
            break;
          }
        }
      }
      if (resolvedTeamId == null &&
          event.currentSelection != null &&
          validTeamIds.contains(event.currentSelection)) {
        resolvedTeamId = event.currentSelection;
      }
      if (resolvedTeamId == null &&
          event.actor.role == UserRole.servant &&
          assignedTeamIds.length == 1 &&
          validTeamIds.contains(event.actor.effectiveAssignedTeamIds.first)) {
        resolvedTeamId = event.actor.effectiveAssignedTeamIds.first;
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
        name: 'StudentFormTeamsBloc',
      );
      emit(
        const StudentFormTeamsState(
          errorMessage: 'تعذر تحميل الفرق. حاول مرة أخرى.',
        ),
      );
    }
  }

  void _onSelectTeam(
    SelectTeamEvent event,
    Emitter<StudentFormTeamsState> emit,
  ) {
    emit(state.copyWith(selectedTeamId: event.teamId, clearErrorMessage: true));
  }
}
