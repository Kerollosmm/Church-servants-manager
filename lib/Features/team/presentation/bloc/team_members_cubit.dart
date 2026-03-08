import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamMembersState {
  final bool isLoading;
  final bool isSaving;
  final List<StudentModel> students;
  final String searchQuery;
  final Set<String> selectedStudentIds;
  final bool loadedFromCache;
  final String? errorMessage;

  const TeamMembersState({
    this.isLoading = false,
    this.isSaving = false,
    this.students = const <StudentModel>[],
    this.searchQuery = '',
    this.selectedStudentIds = const <String>{},
    this.loadedFromCache = false,
    this.errorMessage,
  });

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
    bool clearErrorMessage = false,
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
    );
  }
}

class TeamMembersCubit extends Cubit<TeamMembersState> {
  TeamMembersCubit({required StudentDataRepository studentRepository})
    : _studentRepository = studentRepository,
      super(const TeamMembersState(isLoading: true));

  final StudentDataRepository _studentRepository;

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
    emit(state.copyWith(searchQuery: query, clearErrorMessage: true));
  }

  void toggleSelection(String studentId, bool isSelected) {
    final selected = Set<String>.from(state.selectedStudentIds);
    if (isSelected) {
      selected.add(studentId);
    } else {
      selected.remove(studentId);
    }
    emit(state.copyWith(selectedStudentIds: selected, clearErrorMessage: true));
  }

  List<StudentModel> selectedStudents() {
    final selectedIds = state.selectedStudentIds;
    return state.students
        .where((student) => selectedIds.contains(student.docID))
        .toList(growable: false);
  }

  void markSavingStarted() {
    emit(state.copyWith(isSaving: true, clearErrorMessage: true));
  }

  void markSavingFinished() {
    emit(state.copyWith(isSaving: false, clearErrorMessage: true));
  }
}
