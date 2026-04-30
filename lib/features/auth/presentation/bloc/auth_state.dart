part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthDegraded extends AuthState {
  final AuthUser user;
  final String message;

  const AuthDegraded({required this.user, required this.message});

  @override
  List<Object?> get props => [user, message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthArchived extends AuthState {
  final String message;
  final String? email;

  const AuthArchived({required this.message, this.email});

  @override
  List<Object?> get props => [message, email];
}

class AuthNeedsVerification extends AuthState {
  const AuthNeedsVerification();
}

class AuthNeedsPasswordReset extends AuthState {
  const AuthNeedsPasswordReset();
}

class AuthVerificationSent extends AuthState {
  const AuthVerificationSent();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

class AuthSigningOut extends AuthState {
  const AuthSigningOut();
}
