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
  final entry = e.toString().toLowerCase();

  if (entry.contains('permission-denied') ||
      entry.contains('permission denied')) {
    return const TeamPermissionDeniedFailure();
  }

  if (entry.contains('not-found') || entry.contains('not found')) {
    return const TeamNotFoundFailure();
  }

  return GenericTeamFailure(e.toString());
}
