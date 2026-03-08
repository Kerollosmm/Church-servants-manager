import 'package:church_management_system/core/utils/exception_matchers.dart';
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
  if (isPermissionDeniedException(e)) {
    // Reusing generic or specific if needed
    return GenericServantFailure('Permission denied');
  }

  if (isNotFoundException(e)) {
    return const ServantNotFoundFailure();
  }

  return GenericServantFailure(e.toString());
}
