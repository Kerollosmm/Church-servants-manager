import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum TeamMembersMutationStatus { idle, success, failure }

// FIX [007]: Extend Equatable so identical state emissions are skipped by
// flutter_bloc, preventing redundant UI rebuilds in TeamMembersScreen.
class TeamMembersState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<StudentModel> students;
  final String searchQuery;
  final Set<String> selectedStudentIds;
  final bool loadedFromCache;
  final String? errorMessage;
  final TeamMembersMutationStatus mutationStatus;
  final String? feedbackMessage;

  const TeamMembersState({
    this.isLoading = false,
    this.isSaving = false,
    this.students = const <StudentModel>[],
    this.searchQuery = '',
    this.selectedStudentIds = const <String>{},
    this.loadedFromCache = false,
    this.errorMessage,
    this.mutationStatus = TeamMembersMutationStatus.idle,
    this.feedbackMessage,
  });

  List<StudentModel> get visibleStudents {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students
        .where((student) => student.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  int get selectedCount => selectedStudentIds.length;

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    students,
    searchQuery,
    selectedStudentIds,
    loadedFromCache,
    errorMessage,
    mutationStatus,
    feedbackMessage,
  ];

  TeamMembersState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<StudentModel>? students,
    String? searchQuery,
    Set<String>? selectedStudentIds,
    bool? loadedFromCache,
    String? errorMessage,
    TeamMembersMutationStatus? mutationStatus,
    String? feedbackMessage,
    bool clearErrorMessage = false,
    bool clearFeedbackMessage = false,
  }) {
    return TeamMembersState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      students: students ?? this.students,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      loadedFromCache: loadedFromCache ?? this.loadedFromCache,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      mutationStatus: mutationStatus ?? this.mutationStatus,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}

class TeamMembersCubit extends Cubit<TeamMembersState> {
  TeamMembersCubit({
    required StudentDataRepository studentRepository,
    required AdminTeamService adminTeamService,
  }) : _studentRepository = studentRepository,
       _adminTeamService = adminTeamService,
       super(const TeamMembersState(isLoading: true));

  final StudentDataRepository _studentRepository;
  final AdminTeamService _adminTeamService;

  TeamMembersState _clearMutationFeedback(TeamMembersState value) {
    return value.copyWith(
      mutationStatus: TeamMembersMutationStatus.idle,
      clearErrorMessage: true,
      clearFeedbackMessage: true,
    );
  }

  Future<void> load({required String groupId, required String teamId}) async {
    emit(const TeamMembersState(isLoading: true));

    try {
      final result = await _studentRepository.getStudentsByGroupWithFallback(
        groupId,
      );
      final students = [...result.students]
        ..sort((a, b) => a.name.compareTo(b.name));
      final selectedStudentIds = students
          .where((student) => student.classId == teamId)
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
      if (kDebugMode) {
        debugPrint(
          'TeamMembersCubit: failed to load students '
          '(${error.runtimeType})',
        );
      }
      emit(
        const TeamMembersState(
          errorMessage: 'فشل تحميل المخدومين. حاول مرة أخرى.',
        ),
      );
    }
  }

  void search(String query) {
    emit(_clearMutationFeedback(state).copyWith(searchQuery: query));
  }

  void toggleSelection(String studentId, bool isSelected) {
    final selected = Set<String>.from(state.selectedStudentIds);
    isSelected ? selected.add(studentId) : selected.remove(studentId);
    emit(_clearMutationFeedback(state).copyWith(selectedStudentIds: selected));
  }

  List<StudentModel> selectedStudents() {
    final selectedIds = state.selectedStudentIds;
    return state.students
        .where((student) => selectedIds.contains(student.docID))
        .toList(growable: false);
  }

  Future<void> saveMembers({
    required AuthUser actor,
    required TeamModel team,
  }) async {
    if (state.isSaving) return;

    emit(
      _clearMutationFeedback(
        state,
      ).copyWith(isSaving: true, clearErrorMessage: true),
    );

    try {
      await _adminTeamService.setStudentsForTeam(
        actor: actor,
        team: team,
        selectedStudents: selectedStudents(),
      );
      emit(
        state.copyWith(
          isSaving: false,
          mutationStatus: TeamMembersMutationStatus.success,
          feedbackMessage: 'تم تحديث أعضاء الفريق بنجاح',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'TeamMembersCubit: failed to save team members '
          '(${error.runtimeType})',
        );
      }
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
