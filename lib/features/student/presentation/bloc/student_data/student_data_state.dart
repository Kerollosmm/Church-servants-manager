part of 'student_data_bloc.dart';

/// Sealed states for StudentDataBloc with exhaustive switch support.
sealed class StudentDataState {
  const StudentDataState();
}

/// Initial state - no data loaded yet.
final class StudentDataInitial extends StudentDataState {
  const StudentDataInitial();
}

/// Loading state - fetching data.
final class StudentDataLoading extends StudentDataState {
  const StudentDataLoading();
}

/// Loaded state - students fetched successfully.
final class StudentDataLoaded extends StudentDataState {
  final List<StudentModel> students;
  final String? currentFilterGroupId;

  const StudentDataLoaded({required this.students, this.currentFilterGroupId});

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
          students.length == other.students.length;

  @override
  int get hashCode => Object.hash(students.length, currentFilterGroupId);
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

/// Success state for CRUD operations.
final class StudentDataOperationSuccess extends StudentDataState {
  final String message;

  const StudentDataOperationSuccess(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentDataOperationSuccess &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
