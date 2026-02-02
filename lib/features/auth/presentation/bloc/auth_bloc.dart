import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService.firebase(),
      super(const AuthInitial()) {
    on<AuthEventCheckStatus>(_onCheckStatus);
    on<AuthEventSignIn>(_onSignIn);
    on<AuthEventSignUp>(_onSignUp);
    on<AuthEventSignOut>(_onSignOut);
    on<AuthEventSendVerification>(_onSendVerification);
    on<AuthEventForgotPassword>(_onForgotPassword);
    on<AuthEventRefreshUser>(_onRefreshUser);
  }

  Future<void> _onCheckStatus(
    AuthEventCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.getCurrentAppUser();
      final firebaseUser = _authService.currentUser;

      if (user != null &&
          firebaseUser != null &&
          firebaseUser.isEmailVerified) {
        emit(AuthAuthenticated(user));
      } else if (firebaseUser != null && !firebaseUser.isEmailVerified) {
        emit(const AuthNeedsVerification());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignIn(AuthEventSignIn event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.login(
        email: event.email,
        password: event.password,
      );

      debugPrint(
        'AuthBloc: Login successful, emitting AuthAuthenticated for ${user.email}',
      );
      emit(AuthAuthenticated(user));
    } on EmailNotVerifiedFailure {
      emit(const AuthNeedsVerification());
    } on AuthFailure catch (e) {
      debugPrint('AuthBloc: AuthFailure caught - ${e.message}');
      emit(AuthError(e.message));
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('AuthBloc: Generic error caught - ${e.toString()}');
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

      await _authService.register(
        email: event.email,
        password: event.password,
        name: event.name,
        role: role,
        grade: event.grade,
      );

      // After registration, user needs to verify email
      emit(const AuthNeedsVerification());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
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
      await _authService.logout();
      emit(const AuthUnauthenticated());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSendVerification(
    AuthEventSendVerification event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.sendEmailVerification();
      emit(const AuthVerificationSent());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForgotPassword(
    AuthEventForgotPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.sendPasswordResetEmail(event.email);
      emit(const AuthPasswordResetSent());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRefreshUser(
    AuthEventRefreshUser event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authService.getCurrentAppUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
