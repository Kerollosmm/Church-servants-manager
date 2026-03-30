import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:church_management_system/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:church_management_system/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:church_management_system/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';
part 'auth_bloc_handlers.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // FIX [P1]: delegate auth orchestration to dedicated use cases.
  final AuthService _authService;
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final ObserveAuthStateUseCase _observeAuthStateUseCase;
  late final StreamSubscription<AuthUser?> _authStateSubscription;
  bool _isCheckingStatus = false;

  AuthBloc({
    required AuthService authService,
    SignInUseCase? signInUseCase,
    SignOutUseCase? signOutUseCase,
    ObserveAuthStateUseCase? observeAuthStateUseCase,
  }) : _authService = authService,
       _signInUseCase = signInUseCase ?? SignInUseCase(authService),
       _signOutUseCase = signOutUseCase ?? SignOutUseCase(authService),
       _observeAuthStateUseCase =
           observeAuthStateUseCase ?? ObserveAuthStateUseCase(authService),
       super(const AuthInitial()) {
    on<AuthEventCheckStatus>(_onCheckStatus);
    on<AuthEventSignIn>(_onSignIn);
    on<AuthEventSignUp>(_onSignUp);
    on<AuthEventSignOut>(_onSignOut);
    on<AuthEventSendVerification>(_onSendVerification);
    on<AuthEventForgotPassword>(_onForgotPassword);
    on<AuthEventRefreshUser>(_onRefreshUser);
    // FIX [015] Force token refresh when a permission error is detected so
    // stale custom claims (e.g. after archive/restore) are immediately cleared.
    on<AuthEventForceTokenRefresh>(_onForceTokenRefresh);
    on<_AuthEventSessionChanged>(_onSessionChanged);
    on<_AuthEventSessionError>(_onSessionError);

    _authStateSubscription = _observeAuthStateUseCase.authStateChanges
        .skip(1)
        .listen(
          (user) => add(_AuthEventSessionChanged(user)),
          onError: (error, stackTrace) => add(const _AuthEventSessionError()),
        );
  }

  void _emitResolution(
    Emitter<AuthState> emit,
    AuthSessionResolution resolution,
  ) {
    switch (resolution.status) {
      case AuthSessionStatus.authenticated:
        final user = resolution.user!;
        // FIX [015] Gate restored accounts that have a pending forced password
        // reset to the AuthPendingPasswordReset state so the router can redirect
        // them to the change-password screen before granting full access.
        if (user.restorePendingPasswordReset) {
          emit(AuthPendingPasswordReset(user));
          return;
        }
        emit(AuthAuthenticated(user));
      case AuthSessionStatus.unauthenticated:
        emit(const AuthUnauthenticated());
      case AuthSessionStatus.needsVerification:
        emit(const AuthNeedsVerification());
      case AuthSessionStatus.archived:
        emit(
          AuthArchived(message: resolution.message!, email: resolution.email),
        );
      case AuthSessionStatus.degraded:
        emit(
          AuthDegraded(user: resolution.user!, message: resolution.message!),
        );
      case AuthSessionStatus.error:
        emit(AuthError(resolution.message!));
    }
  }

  Future<void> _onCheckStatus(
    AuthEventCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    if (_isCheckingStatus) {
      return;
    }

    _isCheckingStatus = true;
    try {
      await _handleCheckStatus(this, event, emit);
    } finally {
      _isCheckingStatus = false;
    }
  }

  Future<void> _onSignIn(AuthEventSignIn event, Emitter<AuthState> emit) =>
      _handleSignIn(this, event, emit);

  Future<void> _onSignUp(AuthEventSignUp event, Emitter<AuthState> emit) =>
      _handleSignUp(this, event, emit);

  Future<void> _onSignOut(AuthEventSignOut event, Emitter<AuthState> emit) =>
      _handleSignOut(this, event, emit);

  Future<void> _onSendVerification(
    AuthEventSendVerification event,
    Emitter<AuthState> emit,
  ) => _handleSendVerification(this, event, emit);

  Future<void> _onForgotPassword(
    AuthEventForgotPassword event,
    Emitter<AuthState> emit,
  ) => _handleForgotPassword(this, event, emit);

  Future<void> _onRefreshUser(
    AuthEventRefreshUser event,
    Emitter<AuthState> emit,
  ) => _handleRefreshUser(this, event, emit);

  // FIX [015] Dispatches a forced token refresh to clear stale custom claims.
  Future<void> _onForceTokenRefresh(
    AuthEventForceTokenRefresh event,
    Emitter<AuthState> emit,
  ) => _handleForceTokenRefresh(this, event, emit);

  Future<void> _onSessionChanged(
    _AuthEventSessionChanged event,
    Emitter<AuthState> emit,
  ) => _handleSessionChanged(this, event, emit);

  void _onSessionError(_AuthEventSessionError event, Emitter<AuthState> emit) =>
      _handleSessionError(this, event, emit);

  @override
  Future<void> close() async {
    await _authStateSubscription.cancel();
    return super.close();
  }
}
