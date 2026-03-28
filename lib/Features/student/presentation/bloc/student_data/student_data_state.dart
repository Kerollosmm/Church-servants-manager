part of 'student_data_bloc.dart';

/// Sealed states for StudentDataBloc with exhaustive switch support.
sealed class StudentDataState {
  const StudentDataState();
}

enum StudentMutationStatus { idle, success }

/// Initial state - no data loaded yet.
final class StudentDataInitial extends StudentDataState {
  const StudentDataInitial();
}

/// Loading state - fetching data.
final class StudentDataLoading extends StudentDataState {
  final List<StudentModel> previousStudents;
  final bool isRefresh;
  final bool includeArchived;

  const StudentDataLoading({
    this.previousStudents = const <StudentModel>[],
    this.isRefresh = false,
    this.includeArchived = false,
  });

  bool get hasPreviousStudents => previousStudents.isNotEmpty;
}

/// Loaded state - students fetched successfully.
// FIX [008]: Added isLoadingMore and hasReachedMax for cursor-based pagination (T007).
final class StudentDataLoaded extends StudentDataState {
  final List<StudentModel> students;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final String? currentFilterGroupId;
  final String? currentFilterTeamId;
  final String? currentQuery;
  final bool includeArchived;
  final StudentMutationStatus mutationStatus;
  final bool isLoadingMore; // FIX [008]: true while fetching the next page
  final bool hasReachedMax; // FIX [008]: true when no more pages exist

  /// Optional one-shot message signaling a successful CRUD operation.
  final String? successMessage;

  const StudentDataLoaded({
    required this.students,
    this.lastDocument,
    this.currentFilterGroupId,
    this.currentFilterTeamId,
    this.currentQuery,
    this.includeArchived = false,
    this.mutationStatus = StudentMutationStatus.idle,
    this.successMessage,
    this.isLoadingMore = false, // FIX [008]: pagination default
    this.hasReachedMax = false, // FIX [008]: pagination default
  });

  /// Get student count.
  int get count => students.length;

  /// Check if empty.
  bool get isEmpty => students.isEmpty;

  StudentDataLoaded copyWith({
    List<StudentModel>? students,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool clearLastDocument = false,
    String? currentFilterGroupId,
    String? currentFilterTeamId,
    String? currentQuery,
    bool? includeArchived,
    StudentMutationStatus? mutationStatus,
    String? successMessage,
    bool clearSuccessMessage = false,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return StudentDataLoaded(
      students: students ?? this.students,
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      currentFilterGroupId: currentFilterGroupId ?? this.currentFilterGroupId,
      currentFilterTeamId: currentFilterTeamId ?? this.currentFilterTeamId,
      currentQuery: currentQuery ?? this.currentQuery,
      includeArchived: includeArchived ?? this.includeArchived,
      mutationStatus: mutationStatus ?? this.mutationStatus,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentDataLoaded &&
          runtimeType == other.runtimeType &&
          lastDocument == other.lastDocument &&
          currentFilterGroupId == other.currentFilterGroupId &&
          currentFilterTeamId == other.currentFilterTeamId &&
          currentQuery == other.currentQuery &&
          includeArchived == other.includeArchived &&
          mutationStatus == other.mutationStatus &&
          successMessage == other.successMessage &&
          isLoadingMore == other.isLoadingMore &&
          hasReachedMax == other.hasReachedMax &&
          const ListEquality<StudentModel>().equals(students, other.students);

  @override
  int get hashCode => Object.hash(
    const ListEquality<StudentModel>().hash(students),
    lastDocument,
    currentFilterGroupId,
    currentFilterTeamId,
    currentQuery,
    includeArchived,
    mutationStatus,
    successMessage,
    isLoadingMore,
    hasReachedMax,
  );
}

/// Error state - operation failed.
final class StudentDataError extends StudentDataState {
  final String message;

  const StudentDataError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentDataError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
