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
final class StudentDataLoaded extends StudentDataState {
  final List<StudentModel> students;
  final String? currentFilterGroupId;
  final String? currentFilterTeamId;
  final String? currentQuery;
  final bool includeArchived;
  final StudentMutationStatus mutationStatus;

  /// Optional one-shot message signaling a successful CRUD operation.
  final String? successMessage;

  const StudentDataLoaded({
    required this.students,
    this.currentFilterGroupId,
    this.currentFilterTeamId,
    this.currentQuery,
    this.includeArchived = false,
    this.mutationStatus = StudentMutationStatus.idle,
    this.successMessage,
  });

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
