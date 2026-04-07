part of 'student_data_bloc.dart';

/// Sealed states for StudentDataBloc with exhaustive switch support.
sealed class StudentDataState {
  const StudentDataState();
}

enum StudentMutationStatus { idle, success }

enum StudentMutationOperation { archive, restore }

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
final class StudentDataLoaded extends StudentDataState {
  final List<StudentModel> students;
  final String? currentFilterGroupId;
  final String? currentFilterTeamId;
  final String? currentQuery;
  final bool includeArchived;
  final StudentMutationStatus mutationStatus;
  final StudentMutationOperation? mutationOperation;

  /// Optional one-shot message signaling a successful CRUD operation.
  final String? successMessage;

  const StudentDataLoaded({
    required this.students,
    this.currentFilterGroupId,
    this.currentFilterTeamId,
    this.currentQuery,
    this.includeArchived = false,
    this.mutationStatus = StudentMutationStatus.idle,
    this.mutationOperation,
    this.successMessage,
  });

  StudentDataLoaded copyWith({
    List<StudentModel>? students,
    String? currentFilterGroupId,
    String? currentFilterTeamId,
    String? currentQuery,
    bool? includeArchived,
    StudentMutationStatus? mutationStatus,
    StudentMutationOperation? mutationOperation,
    String? successMessage,
    bool clearMutation = false,
  }) {
    return StudentDataLoaded(
      students: students ?? this.students,
      currentFilterGroupId: currentFilterGroupId ?? this.currentFilterGroupId,
      currentFilterTeamId: currentFilterTeamId ?? this.currentFilterTeamId,
      currentQuery: currentQuery ?? this.currentQuery,
      includeArchived: includeArchived ?? this.includeArchived,
      mutationStatus: clearMutation
          ? StudentMutationStatus.idle
          : (mutationStatus ?? this.mutationStatus),
      mutationOperation: clearMutation
          ? null
          : (mutationOperation ?? this.mutationOperation),
      successMessage: clearMutation
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  /// Get student count.
  int get count => students.length;

  /// Check if empty.
  bool get isEmpty => students.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentDataLoaded &&
          runtimeType == other.runtimeType &&
          currentFilterGroupId == other.currentFilterGroupId &&
          currentFilterTeamId == other.currentFilterTeamId &&
          currentQuery == other.currentQuery &&
          includeArchived == other.includeArchived &&
          mutationStatus == other.mutationStatus &&
          mutationOperation == other.mutationOperation &&
          successMessage == other.successMessage &&
          const ListEquality<StudentModel>().equals(students, other.students);

  @override
  int get hashCode => Object.hash(
    const ListEquality<StudentModel>().hash(students),
    currentFilterGroupId,
    currentFilterTeamId,
    currentQuery,
    includeArchived,
    mutationStatus,
    mutationOperation,
    successMessage,
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
