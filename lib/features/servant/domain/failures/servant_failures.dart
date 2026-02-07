import 'package:equatable/equatable.dart';

/// Base class for all servant-related failures.
abstract class ServantFailure extends Equatable {
  final String message;
  const ServantFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Thrown when a servant document is not found.
class ServantNotFoundFailure extends ServantFailure {
  const ServantNotFoundFailure([super.message = 'Servant not found']);
}

/// Thrown when a Firestore/Network error occurs.
class ServerFailure extends ServantFailure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Thrown when an unexpected error occurs.
class GenericServantFailure extends ServantFailure {
  const GenericServantFailure(super.message);
}

/// Helper to map exceptions to failures
ServantFailure mapExceptionToServantFailure(Object e) {
  final entry = e.toString().toLowerCase();

  if (entry.contains('permission-denied') ||
      entry.contains('permission denied')) {
    // Reusing generic or specific if needed
    return GenericServantFailure('Permission denied');
  }

  if (entry.contains('not-found') || entry.contains('not found')) {
    return const ServantNotFoundFailure();
  }

  return GenericServantFailure(e.toString());
}
