import 'dart:async';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
    : _authService = authService,
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
      // Wait for the first auth state change to ensure session is restored.
      final initialUser = await _authService.authStateChanges.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      // Reload user to get latest email verification status if we have a user.
      if (initialUser != null) {
        await _authService.reloadUser();
      }

      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      if (!firebaseUser.isEmailVerified) {
        emit(const AuthNeedsVerification());
        return;
      }

      final user = await _authService.getCurrentAppUser();
      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }
      emit(AuthAuthenticated(user));
    } catch (e) {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        emit(const AuthUnauthenticated());
        return;
      }
      final cached = _authService.lastKnownAppUser;
      if (cached != null && cached.uid == firebaseUser.uid) {
        emit(
          AuthDegraded(
            user: cached,
            message:
                'Unable to refresh account data. Showing last synced permissions.',
          ),
        );
        return;
      }
      emit(AuthError('Unable to load account data. Please try again.'));
    }
  }

  Future<void> _onSignIn(AuthEventSignIn event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.signIn(
        email: event.email,
        password: event.password,
      );

      emit(AuthAuthenticated(user));
    } on EmailNotVerifiedFailure {
      emit(const AuthNeedsVerification());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onSignUp(AuthEventSignUp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authService.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
        grade: event.grade,
      );

      // After registration, user needs to verify email
      emit(const AuthNeedsVerification());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onSignOut(
    AuthEventSignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(const AuthError('Something went wrong. Please try again.'));
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
      emit(const AuthError('Something went wrong. Please try again.'));
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
      emit(const AuthError('Something went wrong. Please try again.'));
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
      final firebaseUser = _authService.currentUser;
      final cached = _authService.lastKnownAppUser;
      if (firebaseUser != null &&
          cached != null &&
          cached.uid == firebaseUser.uid) {
        emit(
          AuthDegraded(
            user: cached,
            message:
                'Unable to refresh account data. Showing last synced permissions.',
          ),
        );
      } else {
        emit(const AuthError('Something went wrong. Please try again.'));
      }
    }
  }
}
