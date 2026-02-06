import 'package:equatable/equatable.dart';

/// Base class for all student-related failures.
abstract class StudentFailure extends Equatable {
  final String message;
  const StudentFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Thrown when a student document is not found.
class StudentNotFoundFailure extends StudentFailure {
  const StudentNotFoundFailure([super.message = 'Student not found']);
}

/// Thrown when the user does not have permission to perform an action.
class PermissionDeniedFailure extends StudentFailure {
  const PermissionDeniedFailure([super.message = 'Permission denied']);
}

/// Thrown when a Firestore/Network error occurs.
class ServerFailure extends StudentFailure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Thrown when an unexpected error occurs.
class GenericStudentFailure extends StudentFailure {
  const GenericStudentFailure(super.message);
}

/// Helper to map exceptions to failures
StudentFailure mapExceptionToStudentFailure(Object e) {
  final entry = e.toString().toLowerCase();

  if (entry.contains('permission-denied') ||
      entry.contains('permission denied')) {
    return const PermissionDeniedFailure();
  }

  if (entry.contains('not-found') || entry.contains('not found')) {
    return const StudentNotFoundFailure();
  }

  return GenericStudentFailure(e.toString());
}
