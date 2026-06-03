import 'dart:developer' as developer;

import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_event.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_state.dart'; // import state
import 'package:flutter_bloc/flutter_bloc.dart';

export 'team_members_state.dart'
    show TeamMembersState, TeamMembersMutationStatus;

class TeamMembersBloc extends Bloc<TeamMembersEvent, TeamMembersState> {
  final StudentDataRepository _studentRepository;
  final AdminTeamService _adminTeamService;

  TeamMembersBloc({
    required StudentDataRepository studentRepository,
    required AdminTeamService adminTeamService,
  }) : _studentRepository = studentRepository,
       _adminTeamService = adminTeamService,
       super(const TeamMembersState(isLoading: true)) {
    on<LoadTeamMembersEvent>(_onLoad);
    on<SearchTeamMembersEvent>(_onSearch);
    on<ToggleSelectionEvent>(_onToggleSelection);
    on<SaveMembersEvent>(_onSaveMembers);
  }

  TeamMembersState _clearMutationFeedback(TeamMembersState value) {
    return value.copyWith(
      mutationStatus: TeamMembersMutationStatus.idle,
      clearErrorMessage: true,
      clearFeedbackMessage: true,
    );
  }

  Future<void> _onLoad(
    LoadTeamMembersEvent event,
    Emitter<TeamMembersState> emit,
  ) async {
    emit(const TeamMembersState(isLoading: true));

    try {
      final result = await _studentRepository.getStudentsByGroupWithFallback(
        event.groupId,
      );
      final students = [...result.students]
        ..sort((a, b) => a.name.compareTo(b.name));
      final selectedStudentIds = students
          .where((student) => student.classId == event.teamId)
          .map((student) => student.docID)
          .toSet();
      emit(
        TeamMembersState(
          students: students,
          selectedStudentIds: selectedStudentIds,
          loadedFromCache: result.isFromCache,
        ),
      );
    } catch (error) {
      developer.log(
        'failed to load students',
        error: error,
        name: 'TeamMembersBloc',
      );
      emit(
        const TeamMembersState(
          errorMessage: 'فشل تحميل المخدومين. حاول مرة أخرى.',
        ),
      );
    }
  }

  void _onSearch(SearchTeamMembersEvent event, Emitter<TeamMembersState> emit) {
    emit(_clearMutationFeedback(state).copyWith(searchQuery: event.query));
  }

  void _onToggleSelection(
    ToggleSelectionEvent event,
    Emitter<TeamMembersState> emit,
  ) {
    final selected = Set<String>.from(state.selectedStudentIds);
    if (event.isSelected) {
      selected.add(event.studentId);
    } else {
      selected.remove(event.studentId);
    }
    emit(_clearMutationFeedback(state).copyWith(selectedStudentIds: selected));
  }

  Future<void> _onSaveMembers(
    SaveMembersEvent event,
    Emitter<TeamMembersState> emit,
  ) async {
    if (state.isSaving) return;

    emit(
      _clearMutationFeedback(
        state,
      ).copyWith(isSaving: true, clearErrorMessage: true),
    );

    try {
      await _adminTeamService.setStudentsForTeam(
        actor: event.actor,
        team: event.team,
        selectedStudents: event.selectedStudents,
      );
      emit(
        state.copyWith(
          isSaving: false,
          mutationStatus: TeamMembersMutationStatus.success,
          feedbackMessage: 'تم تحديث أعضاء الفريق بنجاح',
        ),
      );
    } catch (error) {
      developer.log(
        'failed to save team members',
        error: error,
        name: 'TeamMembersBloc',
      );
      emit(
        state.copyWith(
          isSaving: false,
          mutationStatus: TeamMembersMutationStatus.failure,
          feedbackMessage: 'تعذر تحديث أعضاء الفريق. حاول مرة أخرى.',
        ),
      );
    }
  }
}
