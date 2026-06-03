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
  final String? grade;

  const AuthEventSignUp({
    required this.email,
    required this.password,
    required this.name,
    this.grade,
  });
}

class AuthEventSignOut extends AuthEvent {
  const AuthEventSignOut();
}

class AuthEventSendVerification extends AuthEvent {
  const AuthEventSendVerification();
}

class AuthEventForgotPassword extends AuthEvent {
  final String email;
  const AuthEventForgotPassword({required this.email});
}

class AuthEventForcePasswordReset extends AuthEvent {
  final String newPassword;
  const AuthEventForcePasswordReset({required this.newPassword});
}

class AuthEventRefreshUser extends AuthEvent {
  const AuthEventRefreshUser();
}

class AuthEventForceRefresh extends AuthEvent {
  const AuthEventForceRefresh();
}

class _AuthEventSessionChanged extends AuthEvent {
  final AuthUser? user;

  const _AuthEventSessionChanged(this.user);
}

class _AuthEventSessionError extends AuthEvent {
  const _AuthEventSessionError();
}
