import 'package:csms/core/constants/enums.dart';
import 'package:csms/core/models/user.dart';
import 'package:csms/core/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthEventCheckStatus>(_onCheckStatus);
    on<AuthEventSignIn>(_onSignIn);
    on<AuthEventSignUp>(_onSignUp);
    on<AuthEventSignOut>(_onSignOut);
    on<AuthEventSendVerification>(_onSendVerification);
  }

  Future<void> _onCheckStatus(
    AuthEventCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await AuthService.firebase().getCurrentAppUser();
      final firebaseUser = AuthService.firebase().currentUser;

      if (user != null && firebaseUser != null && firebaseUser.emailVerified) {
        emit(AuthAuthenticated(user));
      } else if (firebaseUser != null && !firebaseUser.emailVerified) {
        emit(const AuthNeedsVerification());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignIn(AuthEventSignIn event, Emitter<AuthState> emit) async {
    print('[AuthBloc] _onSignIn called');
    emit(const AuthLoading());
    try {
      final user = await AuthService.firebase().login(
        email: event.email,
        password: event.password,
      );
      print('[AuthBloc] Login succeeded, emitting AuthAuthenticated');
      emit(AuthAuthenticated(user));
    } on EmailNotVerifiedException {
      print('[AuthBloc] EmailNotVerified, emitting AuthNeedsVerification');
      emit(const AuthNeedsVerification());
    } catch (e) {
      print('[AuthBloc] Error: $e, emitting AuthError');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUp(AuthEventSignUp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final role = UserRole.values.firstWhere(
        (r) => r.name == event.role,
        orElse: () => UserRole.student,
      );

      await AuthService.firebase().register(
        email: event.email,
        password: event.password,
        name: event.name,
        role: role,
        grade: event.grade,
      );

      // After registration, user needs to verify email
      emit(const AuthNeedsVerification());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(
    AuthEventSignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await AuthService.firebase().logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSendVerification(
    AuthEventSendVerification event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await AuthService.firebase().sendEmailVerification();
      emit(const AuthVerificationSent());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
