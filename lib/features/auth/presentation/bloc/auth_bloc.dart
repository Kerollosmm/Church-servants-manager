import 'dart:async';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  static const _degradedPermissionsMessage =
      'Unable to refresh account data. Showing last synced permissions.';
  static const _archivedMessage =
      'تم إيقاف هذا الحساب. تواصل مع الإدارة لاستعادته.';
  late final StreamSubscription<AuthUser?> _authStateSubscription;

  AuthBloc({required AuthService authService})
    : _authService = authService,
      super(const AuthInitial()) {
    on<AuthEventCheckStatus>(_onCheckStatus);
    on<AuthEventSignIn>(_onSignIn);
    on<AuthEventSignUp>(_onSignUp);
    on<AuthEventSignOut>(_onSignOut);
    on<AuthEventSendVerification>(_onSendVerification);
    on<AuthEventForgotPassword>(_onForgotPassword);
    on<AuthEventForcePasswordReset>(_onForcePasswordReset);
    on<AuthEventRefreshUser>(_onRefreshUser);
    on<_AuthEventSessionChanged>(_onSessionChanged);
    on<_AuthEventSessionError>(_onSessionError);

    _authStateSubscription = _authService.authStateChanges.listen(
      (user) {
        // Only react to session changes after initial status check completes.
        // AuthEventCheckStatus handles the cold-start case; the stream
        // handles subsequent tab-switches, token refreshes, and remote sign-outs.
        if (state is! AuthLoading && state is! AuthInitial) {
          add(_AuthEventSessionChanged(user));
        }
      },
      onError: (error, stackTrace) => add(const _AuthEventSessionError()),
    );
  }

  Future<void> _emitResolvedState(
    Emitter<AuthState> emit,
    AuthUser? user,
  ) async {
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    if (user.isArchived) {
      emit(AuthArchived(message: _archivedMessage, email: user.email));
      return;
    }

    if (user.restorePendingPasswordReset) {
      emit(const AuthNeedsPasswordReset());
      return;
    }

    if (!user.isEmailVerified) {
      emit(const AuthNeedsVerification());
      return;
    }

    emit(AuthAuthenticated(user));
  }

  Future<void> _runAuthAction(
    Emitter<AuthState> emit,
    Future<void> Function() action, {
    bool emitLoading = false,
    void Function()? onEmailNotVerified,
  }) async {
    if (emitLoading) {
      emit(const AuthLoading());
    }
    try {
      await action();
    } on EmailNotVerifiedFailure catch (e) {
      if (onEmailNotVerified != null) {
        onEmailNotVerified();
      } else {
        emit(AuthError(e.message));
      }
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onCheckStatus(
    AuthEventCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final initialUser =
          _authService.currentUser ??
          await _authService.authStateChanges.first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );

      if (initialUser != null) {
        await _authService.reloadUser();
      }

      final firebaseUser = _authService.currentUser;
      if (_emitUnauthenticatedIfNoFirebaseUser(emit, firebaseUser)) {
        return;
      }

      final user = await _authService.getCurrentAppUser(
        forceRefresh: initialUser != null,
      );
      await _emitResolvedState(emit, user);
    } catch (_) {
      _emitDegradedOrError(
        emit,
        fallbackErrorMessage: 'Unable to load account data. Please try again.',
      );
    }
  }

  Future<void> _onSignIn(AuthEventSignIn event, Emitter<AuthState> emit) async {
    await _runAuthAction(
      emit,
      () async {
        final user = await _authService.signIn(
          email: event.email,
          password: event.password,
        );

        await _emitResolvedState(emit, user);
      },
      emitLoading: true,
      onEmailNotVerified: () => emit(const AuthNeedsVerification()),
    );
  }

  Future<void> _onSignUp(AuthEventSignUp event, Emitter<AuthState> emit) async {
    await _runAuthAction(emit, () async {
      await _authService.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
        grade: event.grade,
      );

      // After registration, user needs to verify email
      emit(const AuthNeedsVerification());
    }, emitLoading: true);
  }

  Future<void> _onSignOut(
    AuthEventSignOut event,
    Emitter<AuthState> emit,
  ) async {
    await _runAuthAction(emit, () async {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    }, emitLoading: true);
  }

  Future<void> _onSendVerification(
    AuthEventSendVerification event,
    Emitter<AuthState> emit,
  ) async {
    await _runAuthAction(emit, () async {
      await _authService.sendEmailVerification();
      emit(const AuthVerificationSent());
    });
  }

  Future<void> _onForgotPassword(
    AuthEventForgotPassword event,
    Emitter<AuthState> emit,
  ) async {
    await _runAuthAction(emit, () async {
      await _authService.sendPasswordResetEmail(event.email);
      emit(const AuthPasswordResetSent());
    }, emitLoading: true);
  }

  Future<void> _onRefreshUser(
    AuthEventRefreshUser event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authService.refreshCurrentAppUser();
      await _emitResolvedState(emit, user);
    } catch (e) {
      _emitDegradedOrError(
        emit,
        fallbackErrorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _onSessionChanged(
    _AuthEventSessionChanged event,
    Emitter<AuthState> emit,
  ) async {
    await _emitResolvedState(emit, event.user);
  }

  void _onSessionError(_AuthEventSessionError event, Emitter<AuthState> emit) {
    _emitDegradedOrError(
      emit,
      fallbackErrorMessage: 'Unable to refresh account data. Please try again.',
    );
  }

  Future<void> _onForcePasswordReset(
    AuthEventForcePasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = _authService.currentUser;
      if (user == null) {
        emit(const AuthError('لم يتم العثور على المستخدم.'));
        return;
      }
      await _authService.updatePassword(event.newPassword);

      // Clear flag as non-fatal while still authenticated
      try {
        await _authService.clearRestorePendingPasswordReset(user.uid);
      } catch (e) {
        // Log error but don't fail the password reset success
      }

      // Finalize session
      try {
        await _authService.signOut();
      } catch (_) {
        // Sign out failure should not block the success emission
      }

      emit(const AuthPasswordResetSuccess());
    } catch (e) {
      emit(AuthError('فشل في تغيير كلمة المرور. حاول مرة أخرى.'));
    }
  }

  bool _emitUnauthenticatedIfNoFirebaseUser(
    Emitter<AuthState> emit,
    AuthUser? firebaseUser,
  ) {
    if (firebaseUser != null) {
      return false;
    }
    emit(const AuthUnauthenticated());
    return true;
  }

  void _emitDegradedOrError(
    Emitter<AuthState> emit, {
    required String fallbackErrorMessage,
  }) {
    final firebaseUser = _authService.currentUser;
    final cached = _authService.lastKnownAppUser;

    if (firebaseUser != null &&
        cached != null &&
        cached.uid == firebaseUser.uid) {
      if (cached.isArchived) {
        emit(AuthArchived(message: _archivedMessage, email: cached.email));
        return;
      }
      emit(_buildDegradedState(cached));
      return;
    }

    emit(AuthError(fallbackErrorMessage));
  }

  AuthDegraded _buildDegradedState(AuthUser cachedUser) {
    return AuthDegraded(user: cachedUser, message: _degradedPermissionsMessage);
  }

  @override
  Future<void> close() async {
    await _authStateSubscription.cancel();
    return super.close();
  }
}
