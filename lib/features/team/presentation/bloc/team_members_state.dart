import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:equatable/equatable.dart';

enum TeamMembersMutationStatus { idle, success, failure }

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

  List<StudentModel> get visibleStudents {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return students;
    }
    return students
        .where((student) {
          return student.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  int get selectedCount => selectedStudentIds.length;

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
