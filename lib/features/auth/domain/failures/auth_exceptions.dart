// Login Auth Exceptions
class UserNotFoundAuthException implements Exception {}

class WrongPasswordAuthException implements Exception {}

// Register Auth Exceptions
class WeakPasswordAuthException implements Exception {}

class EmailAlreadyInUseAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

// Email Verification Exceptions
class EmailNotVerifiedAuthException implements Exception {}

class ArchivedAccountAuthException implements Exception {
  final String? message;
  const ArchivedAccountAuthException([this.message]);

  @override
  String toString() => message ?? 'This account has been archived';
}

// Generic Exceptions
class GenericAuthException implements Exception {
  final String? message;
  final Object? innerException;
  final StackTrace? stackTrace;
  const GenericAuthException(
    [this.message,
    this.innerException,
    this.stackTrace,
  ]);

  @override
  String toString() => message ?? 'An authentication error occurred';
}

class RequiresRecentLoginAuthException implements Exception {}

class UserNotLoggedInAuthException implements Exception {}

// Password Reset Exceptions
class PasswordResetAuthException implements Exception {
  final String? message;
  const PasswordResetAuthException([this.message]);

  @override
  String toString() => message ?? 'Password reset failed';
}
