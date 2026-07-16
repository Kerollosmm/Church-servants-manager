import 'package:church_management_system/core/utils/exception_matchers.dart';
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

/// Thrown when creating a student fails (e.g. duplicate).
class StudentCreateFailure extends StudentFailure {
  const StudentCreateFailure([super.message = 'Failed to create student']);
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

/// Thrown when an invalid argument is provided to a method.
class ArgumentFailure extends StudentFailure {
  const ArgumentFailure([super.message = 'Invalid argument']);
}

/// Helper to map exceptions to failures
StudentFailure mapExceptionToStudentFailure(Object e) {
  if (isPermissionDeniedException(e)) {
    return const PermissionDeniedFailure();
  }

  if (isNotFoundException(e)) {
    return const StudentNotFoundFailure();
  }

  return GenericStudentFailure(e.toString());
}
