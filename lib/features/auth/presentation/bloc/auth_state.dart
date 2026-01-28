part of 'auth_bloc.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthNeedsVerification extends AuthState {
  const AuthNeedsVerification();
}

class AuthVerificationSent extends AuthState {
  const AuthVerificationSent();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
