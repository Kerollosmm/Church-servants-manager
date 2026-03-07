import 'package:church_managment_system/core/utils/exception_matchers.dart';
import 'package:equatable/equatable.dart';

/// Base class for all team-related failures.
abstract class TeamFailure extends Equatable {
  final String message;
  const TeamFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Thrown when a team document is not found.
class TeamNotFoundFailure extends TeamFailure {
  const TeamNotFoundFailure([super.message = 'Team not found']);
}

/// Thrown when the user does not have permission.
class TeamPermissionDeniedFailure extends TeamFailure {
  const TeamPermissionDeniedFailure([super.message = 'Permission denied']);
}

/// Thrown when a Firestore/Network error occurs.
class TeamServerFailure extends TeamFailure {
  const TeamServerFailure([super.message = 'Server error occurred']);
}

/// Thrown when an unexpected error occurs.
class GenericTeamFailure extends TeamFailure {
  const GenericTeamFailure(super.message);
}

/// Helper to map exceptions to team failures.
TeamFailure mapExceptionToTeamFailure(Object e) {
  if (isPermissionDeniedException(e)) {
    return const TeamPermissionDeniedFailure();
  }

  if (isNotFoundException(e)) {
    return const TeamNotFoundFailure();
  }

  return GenericTeamFailure(e.toString());
}
