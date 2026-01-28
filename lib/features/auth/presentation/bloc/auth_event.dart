part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

class AuthEventCheckStatus extends AuthEvent {
  const AuthEventCheckStatus();
}

class AuthEventSignIn extends AuthEvent {
  final String email;
  final String password;

  const AuthEventSignIn({required this.email, required this.password});
}

class AuthEventSignUp extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role;
  final String? grade;

  const AuthEventSignUp({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.grade,
  });
}

class AuthEventSignOut extends AuthEvent {
  const AuthEventSignOut();
}

class AuthEventSendVerification extends AuthEvent {
  const AuthEventSendVerification();
}
