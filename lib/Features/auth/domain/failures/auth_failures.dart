/// Sealed class for typed auth failure handling.
sealed class AuthFailure {
  const AuthFailure();

  String get message;
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();

  @override
  String get message => 'Invalid email or password';
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure();

  @override
  String get message => 'Email is already in use';
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure();

  @override
  String get message => 'Password is too weak';
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure();

  @override
  String get message => 'User not found';
}

class ServerFailure extends AuthFailure {
  final String? details;
  const ServerFailure([this.details]);

  @override
  String get message => details ?? 'Server error occurred';
}
