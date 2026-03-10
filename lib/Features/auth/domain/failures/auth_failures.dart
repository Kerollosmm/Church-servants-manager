abstract class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

// Login Failures
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    super.message = 'User not found. Please register first.',
  ]);
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure([
    super.message = 'Incorrect Credential. Please try again.',
  ]);
}

// Register Failures
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message = 'The password provided is too weak.',
  ]);
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([
    super.message = 'The account already exists for that email.',
  ]);
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure([
    super.message = 'The email address is improperly formatted.',
  ]);
}

// Generic/Other Failures
class GenericAuthFailure extends AuthFailure {
  const GenericAuthFailure([
    super.message = 'An authentication error occurred. Please try again.',
  ]);
}

class UserNotLoggedInFailure extends AuthFailure {
  const UserNotLoggedInFailure([
    super.message = 'User is not currently signed in.',
  ]);
}

class EmailNotVerifiedFailure extends AuthFailure {
  const EmailNotVerifiedFailure([
    super.message = 'Email not verified. Please check your inbox.',
  ]);
}

class ArchivedAccountFailure extends AuthFailure {
  const ArchivedAccountFailure([
    super.message = 'This account has been archived. Please contact an admin.',
  ]);
}

class PasswordResetFailure extends AuthFailure {
  const PasswordResetFailure([
    super.message = 'Failed to send password reset email. Please try again.',
  ]);
}
