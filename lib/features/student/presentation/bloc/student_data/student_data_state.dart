part of 'student_data_bloc.dart';

/// Sealed states for StudentDataBloc with exhaustive switch support.
sealed class StudentDataState extends Equatable {
  const StudentDataState();

  @override
  List<Object?> get props => [];
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
  final List<StudentModel> previousAllStudents;
  final bool isRefresh;
  final bool isSearch;
  final bool includeArchived;
  final String? currentFilterGroupId;
  final String? currentFilterTeamId;
  final String? currentQuery;

  const StudentDataLoading({
    this.previousStudents = const <StudentModel>[],
    this.previousAllStudents = const <StudentModel>[],
    this.isRefresh = false,
    this.isSearch = false,
    this.includeArchived = false,
    this.currentFilterGroupId,
    this.currentFilterTeamId,
    this.currentQuery,
  });

  bool get hasPreviousStudents => previousStudents.isNotEmpty;

  @override
  List<Object?> get props => [
    previousStudents,
    previousAllStudents,
    isRefresh,
    isSearch,
    includeArchived,
    currentFilterGroupId,
    currentFilterTeamId,
    currentQuery,
  ];
}

/// Loaded state - students fetched successfully.
final class StudentDataLoaded extends StudentDataState {
  final List<StudentModel> students;
  final List<StudentModel> allStudents;
  final Map<String, StudentModel> studentsByDocId;
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
    required this.allStudents,
    required this.studentsByDocId,
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
    List<StudentModel>? allStudents,
    Map<String, StudentModel>? studentsByDocId,
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
      allStudents: allStudents ?? this.allStudents,
      studentsByDocId: studentsByDocId ?? this.studentsByDocId,
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
  List<Object?> get props => [
    students,
    allStudents,
    studentsByDocId,
    currentFilterGroupId,
    currentFilterTeamId,
    currentQuery,
    includeArchived,
    mutationStatus,
    mutationOperation,
    successMessage,
  ];
}

/// Error state - operation failed.
final class StudentDataError extends StudentDataState {
  final String message;

  const StudentDataError(this.message);

  @override
  List<Object?> get props => [message];
}
