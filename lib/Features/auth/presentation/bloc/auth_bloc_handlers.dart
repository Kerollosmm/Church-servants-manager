part of 'auth_bloc.dart';

Future<void> _runAuthAction(
  AuthBloc bloc,
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
  } on EmailNotVerifiedFailure catch (error) {
    if (onEmailNotVerified != null) {
      onEmailNotVerified();
      return;
    }
    emit(AuthError(error.message));
  } on AuthFailure catch (error) {
    emit(AuthError(error.message));
  } catch (_) {
    emit(const AuthError('Something went wrong. Please try again.'));
  }
}

Future<void> _handleCheckStatus(
  AuthBloc bloc,
  AuthEventCheckStatus event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());
  final resolution = await bloc._observeAuthStateUseCase.checkStatus();
  bloc._emitResolution(emit, resolution);
}

Future<void> _handleSignIn(
  AuthBloc bloc,
  AuthEventSignIn event,
  Emitter<AuthState> emit,
) async {
  await _runAuthAction(
    bloc,
    emit,
    () async {
      final user = await bloc._signInUseCase(
        email: event.email,
        password: event.password,
      );
      bloc._emitResolution(emit, bloc._observeAuthStateUseCase.resolve(user));
    },
    emitLoading: true,
    onEmailNotVerified: () => emit(const AuthNeedsVerification()),
  );
}

Future<void> _handleSignUp(
  AuthBloc bloc,
  AuthEventSignUp event,
  Emitter<AuthState> emit,
) async {
  await _runAuthAction(bloc, emit, () async {
    await bloc._authService.signUp(
      email: event.email,
      password: event.password,
      name: event.name,
      role: event.role,
      grade: event.grade,
    );
    emit(const AuthNeedsVerification());
  }, emitLoading: true);
}

Future<void> _handleSignOut(
  AuthBloc bloc,
  AuthEventSignOut event,
  Emitter<AuthState> emit,
) async {
  await _runAuthAction(bloc, emit, () async {
    await bloc._signOutUseCase();
    emit(const AuthUnauthenticated());
  }, emitLoading: true);
}

Future<void> _handleSendVerification(
  AuthBloc bloc,
  AuthEventSendVerification event,
  Emitter<AuthState> emit,
) async {
  await _runAuthAction(bloc, emit, () async {
    await bloc._authService.sendEmailVerification();
    emit(const AuthVerificationSent());
  });
}

Future<void> _handleForgotPassword(
  AuthBloc bloc,
  AuthEventForgotPassword event,
  Emitter<AuthState> emit,
) async {
  await _runAuthAction(bloc, emit, () async {
    await bloc._authService.sendPasswordResetEmail(event.email);
    emit(const AuthPasswordResetSent());
  }, emitLoading: true);
}

Future<void> _handleRefreshUser(
  AuthBloc bloc,
  AuthEventRefreshUser event,
  Emitter<AuthState> emit,
) async {
  final resolution = await bloc._observeAuthStateUseCase.refreshCurrentUser(
    fallbackErrorMessage: 'Something went wrong. Please try again.',
  );
  bloc._emitResolution(emit, resolution);
}

Future<void> _handleSessionChanged(
  AuthBloc bloc,
  _AuthEventSessionChanged event,
  Emitter<AuthState> emit,
) async {
  bloc._emitResolution(emit, bloc._observeAuthStateUseCase.resolve(event.user));
}

void _handleSessionError(
  AuthBloc bloc,
  _AuthEventSessionError event,
  Emitter<AuthState> emit,
) {
  bloc._emitResolution(
    emit,
    bloc._observeAuthStateUseCase.resolveError(
      fallbackErrorMessage: 'Unable to refresh account data. Please try again.',
    ),
  );
}
