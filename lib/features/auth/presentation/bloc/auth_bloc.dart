import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authService;
  final SyncService _syncService;
  final Connectivity _connectivity;
  static const _degradedPermissionsMessage =
      'جاري تحديث صلاحيات الحساب... (استخدام البيانات المحفوظة حالياً)';
  static const _inactiveMessage =
      'هذا الحساب غير نشط حالياً. يرجى التواصل مع مسؤول النظام لتنشيطه.';
  late final StreamSubscription<AuthUser?> _authStateSubscription;
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  AuthBloc({
    required AuthRepository authService,
    required SyncService syncService,
    Connectivity? connectivity,
  }) : _authService = authService,
       _syncService = syncService,
       _connectivity = connectivity ?? Connectivity(),
       super(const AuthInitial()) {
    on<AuthEventCheckStatus>(_onCheckStatus);
    on<AuthEventSignIn>(_onSignIn);
    on<AuthEventSignUp>(_onSignUp);
    on<AuthEventSignOut>(_onSignOut);
    on<AuthEventSendVerification>(_onSendVerification);
    on<AuthEventForgotPassword>(_onForgotPassword);
    on<AuthEventForcePasswordReset>(_onForcePasswordReset);
    on<AuthEventRefreshUser>(_onRefreshUser);
    on<AuthEventForceRefresh>(_onForceRefresh);
    on<_AuthEventSessionChanged>(_onSessionChanged);
    on<_AuthEventSessionError>(_onSessionError);

    _authStateSubscription = _authService.userStream.listen(
      (user) {
        if (state is AuthAuthenticated ||
            state is AuthRoleUpdated ||
            state is AuthDegraded ||
            state is AuthRoleRefreshing) {
          add(_AuthEventSessionChanged(user));
        }
      },
      onError: (error, stackTrace) {
        developer.log(
          'AuthBloc: Session stream error',
          error: error,
          stackTrace: stackTrace,
          name: 'AuthBloc',
        );
        add(const _AuthEventSessionError());
      },
    );

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && (state is AuthDegraded || state is AuthAuthenticated)) {
        add(const AuthEventRefreshUser());
      }
    });
  }

  Future<void> _onCheckStatus(
    AuthEventCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      final user = await _authService.getCurrentAppUser(forceRefresh: true);

      if (user == null) {
        emit(const AuthUnauthenticated());
      } else if (user.isArchived) {
        emit(AuthArchived(message: _inactiveMessage, email: user.email));
      } else if (user.restorePendingPasswordReset) {
        emit(const AuthNeedsPasswordReset());
      } else if (!user.isEmailVerified) {
        emit(const AuthNeedsVerification());
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Auth check failed, using cached state',
        name: 'AuthBloc',
        error: e,
        stackTrace: stackTrace,
      );
      final cached = _authService.lastKnownAppUser;
      if (cached != null) {
        if (cached.isArchived) {
          emit(AuthArchived(message: _inactiveMessage, email: cached.email));
        } else {
          emit(
            AuthDegraded(user: cached, message: _degradedPermissionsMessage),
          );
        }
      } else {
        emit(
          const AuthError(
            'Unable to load account data. Please check your connection.',
          ),
        );
      }
    }
  }

  Future<void> _onSessionChanged(
    _AuthEventSessionChanged event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (state is AuthSigningOut) return;

      final newUser = event.user;
      final currentState = state;

      if (currentState is AuthAuthenticated && newUser != null) {
        if (newUser.requiresTokenRefresh) {
          emit(const AuthRoleRefreshing());
          return;
        }
        if (currentState.user.role != newUser.role) {
          emit(AuthRoleUpdated(newUser));
          emit(AuthAuthenticated(newUser));
          return;
        }
      }

      if (newUser == null) {
        emit(const AuthUnauthenticated());
      } else if (newUser.isArchived) {
        emit(AuthArchived(message: _inactiveMessage, email: newUser.email));
      } else if (newUser.restorePendingPasswordReset) {
        emit(const AuthNeedsPasswordReset());
      } else if (!newUser.isEmailVerified) {
        emit(const AuthNeedsVerification());
      } else {
        emit(AuthAuthenticated(newUser));
      }
    } catch (e, stackTrace) {
      developer.log(
        'AuthBloc: Error in session change logic',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthBloc',
      );
      final cached = _authService.lastKnownAppUser;
      if (cached != null) {
        if (cached.isArchived) {
          emit(AuthArchived(message: _inactiveMessage, email: cached.email));
        } else {
          emit(
            AuthDegraded(user: cached, message: _degradedPermissionsMessage),
          );
        }
      } else {
        emit(const AuthError('An error occurred during session sync.'));
      }
    }
  }

  void _onSessionError(_AuthEventSessionError event, Emitter<AuthState> emit) {
    final cached = _authService.lastKnownAppUser;
    if (cached != null) {
      if (cached.isArchived) {
        emit(AuthArchived(message: _inactiveMessage, email: cached.email));
      } else {
        emit(AuthDegraded(user: cached, message: _degradedPermissionsMessage));
      }
    } else {
      emit(
        const AuthError('Unable to refresh account data. Please try again.'),
      );
    }
  }

  Future<void> _onSignIn(AuthEventSignIn event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _authService.signIn(
        email: event.email,
        password: event.password,
      );

      if (user.isArchived) {
        emit(AuthArchived(message: _inactiveMessage, email: user.email));
      } else if (user.restorePendingPasswordReset) {
        emit(const AuthNeedsPasswordReset());
      } else if (!user.isEmailVerified) {
        emit(const AuthNeedsVerification());
      } else {
        emit(AuthAuthenticated(user));
      }
    } on EmailNotVerifiedFailure catch (_) {
      emit(const AuthNeedsVerification());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e, stackTrace) {
      developer.log(
        'AuthBloc: Unexpected error',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthBloc',
      );
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
        grade: event.grade,
      );
      emit(const AuthNeedsVerification());
    } on EmailNotVerifiedFailure catch (_) {
      emit(const AuthNeedsVerification());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e, stackTrace) {
      developer.log(
        'AuthBloc: Unexpected error',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthBloc',
      );
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onSignOut(
    AuthEventSignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSigningOut());
    try {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e, stackTrace) {
      developer.log(
        'Sign out failed',
        name: 'AuthBloc',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const AuthError('Sign out failed. Please try again.'));
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
    } catch (e, stackTrace) {
      developer.log(
        'AuthBloc: Unexpected error',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthBloc',
      );
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
    } catch (e, stackTrace) {
      developer.log(
        'AuthBloc: Unexpected error',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthBloc',
      );
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onRefreshUser(
    AuthEventRefreshUser event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authService.refreshCurrentAppUser();
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else if (user.isArchived) {
        emit(AuthArchived(message: _inactiveMessage, email: user.email));
      } else if (user.restorePendingPasswordReset) {
        emit(const AuthNeedsPasswordReset());
      } else if (!user.isEmailVerified) {
        emit(const AuthNeedsVerification());
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Auth check on session change failed',
        name: 'AuthBloc',
        error: e,
        stackTrace: stackTrace,
      );
      final cached = _authService.lastKnownAppUser;
      if (cached != null) {
        if (cached.isArchived) {
          emit(AuthArchived(message: _inactiveMessage, email: cached.email));
        } else {
          emit(
            AuthDegraded(user: cached, message: _degradedPermissionsMessage),
          );
        }
      } else {
        emit(const AuthError('Something went wrong. Please try again.'));
      }
    }
  }

  Future<void> _onForceRefresh(
    AuthEventForceRefresh event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthRoleRefreshing());
      await _authService.refreshCurrentAppUser();
      // The idTokenChanges stream will emit _AuthEventSessionChanged
      // which handles the actual state transition to AuthAuthenticated.
      // If the stream doesn't fire (edge case), fall back manually.
      final user = _authService.lastKnownAppUser;
      if (user != null && state is! AuthAuthenticated) {
        emit(AuthAuthenticated(user));
      }
    } catch (e, stackTrace) {
      developer.log(
        'AuthBloc: Error during forced token refresh',
        error: e,
        stackTrace: stackTrace,
        name: 'AuthBloc',
      );
      final cached = _authService.lastKnownAppUser;
      if (cached != null) {
        emit(AuthDegraded(user: cached, message: _degradedPermissionsMessage));
      } else {
        emit(
          const AuthError(
            'فشل تحديث البيانات. يرجى التأكد من الاتصال بالإنترنت والمحاولة مجدداً.',
          ),
        );
      }
    }
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

      try {
        await _authService.clearRestorePendingPasswordReset(user.uid);
      } catch (e, stackTrace) {
        developer.log(
          'AuthBloc: Failed to clear restorePendingPasswordReset',
          error: e,
          stackTrace: stackTrace,
          name: 'AuthBloc',
        );
      }

      try {
        await _authService.signOut();
      } catch (e, stackTrace) {
        developer.log(
          'AuthBloc: Failed to sign out',
          error: e,
          stackTrace: stackTrace,
          name: 'AuthBloc',
        );
      }

      emit(const AuthPasswordResetSuccess());
    } catch (e, stackTrace) {
      developer.log(
        'Failed to force password reset',
        name: 'AuthBloc',
        error: e,
        stackTrace: stackTrace,
      );
      emit(const AuthError('فشل في تغيير كلمة المرور. حاول مرة أخرى.'));
    }
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);
    final nextState = transition.nextState;
    String? uid;
    if (nextState is AuthAuthenticated) {
      uid = nextState.user.uid;
    } else if (nextState is AuthDegraded) {
      uid = nextState.user.uid;
    } else if (nextState is AuthRoleUpdated) {
      uid = nextState.user.uid;
    }
    unawaited(_syncService.setAuthenticatedUser(uid));
  }

  @override
  Future<void> close() async {
    await _authStateSubscription.cancel();
    await _connectivitySubscription.cancel();
    return super.close();
  }
}
