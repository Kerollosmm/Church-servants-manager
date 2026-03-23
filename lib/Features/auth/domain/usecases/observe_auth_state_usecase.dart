import 'dart:async';

import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';

enum AuthSessionStatus {
  authenticated,
  unauthenticated,
  needsVerification,
  archived,
  degraded,
  error,
}

class AuthSessionResolution {
  const AuthSessionResolution._({
    required this.status,
    this.user,
    this.email,
    this.message,
  });

  const AuthSessionResolution.authenticated(AuthUser user)
    : this._(status: AuthSessionStatus.authenticated, user: user);

  const AuthSessionResolution.unauthenticated()
    : this._(status: AuthSessionStatus.unauthenticated);

  const AuthSessionResolution.needsVerification()
    : this._(status: AuthSessionStatus.needsVerification);

  const AuthSessionResolution.archived({required String message, String? email})
    : this._(
        status: AuthSessionStatus.archived,
        message: message,
        email: email,
      );

  const AuthSessionResolution.degraded({
    required AuthUser user,
    required String message,
  }) : this._(status: AuthSessionStatus.degraded, user: user, message: message);

  const AuthSessionResolution.error(String message)
    : this._(status: AuthSessionStatus.error, message: message);

  final AuthSessionStatus status;
  final AuthUser? user;
  final String? email;
  final String? message;
}

// FIX [P1]: extracted auth session/bootstrap logic from AuthBloc.
class ObserveAuthStateUseCase {
  const ObserveAuthStateUseCase(this._authService);

  static const degradedPermissionsMessage =
      'Unable to refresh account data. Showing last synced permissions.';
  static const archivedMessage =
      'تم إيقاف هذا الحساب. تواصل مع الإدارة لاستعادته.';

  final AuthService _authService;

  Stream<AuthUser?> get authStateChanges => _authService.authStateChanges;

  Future<AuthSessionResolution> checkStatus() async {
    try {
      final initialUser =
          _authService.currentUser ??
          await authStateChanges.first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );

      if (initialUser != null) {
        await _authService.reloadUser();
      }

      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        return const AuthSessionResolution.unauthenticated();
      }
      if (!firebaseUser.isEmailVerified) {
        return const AuthSessionResolution.needsVerification();
      }

      final user = await _authService.getCurrentAppUser(
        forceRefresh: initialUser != null,
      );
      return resolve(user);
    } catch (_) {
      return resolveError(
        fallbackErrorMessage: 'Unable to load account data. Please try again.',
      );
    }
  }

  Future<AuthSessionResolution> refreshCurrentUser({
    required String fallbackErrorMessage,
  }) async {
    try {
      final user = await _authService.refreshCurrentAppUser();
      return resolve(user);
    } catch (_) {
      return resolveError(fallbackErrorMessage: fallbackErrorMessage);
    }
  }

  AuthSessionResolution resolve(AuthUser? user) {
    if (user == null) {
      return const AuthSessionResolution.unauthenticated();
    }
    if (user.isArchived) {
      return AuthSessionResolution.archived(
        message: archivedMessage,
        email: user.email,
      );
    }
    if (!user.isEmailVerified) {
      return const AuthSessionResolution.needsVerification();
    }
    return AuthSessionResolution.authenticated(user);
  }

  AuthSessionResolution resolveError({required String fallbackErrorMessage}) {
    final firebaseUser = _authService.currentUser;
    final cached = _authService.lastKnownAppUser;

    if (firebaseUser != null &&
        cached != null &&
        cached.uid == firebaseUser.uid) {
      if (cached.isArchived) {
        return AuthSessionResolution.archived(
          message: archivedMessage,
          email: cached.email,
        );
      }
      return AuthSessionResolution.degraded(
        user: cached,
        message: degradedPermissionsMessage,
      );
    }

    return AuthSessionResolution.error(fallbackErrorMessage);
  }
}
