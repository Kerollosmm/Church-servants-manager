import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  static AuthFailure mapException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return const UserNotFoundFailure();
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return const WrongPasswordFailure();
        case 'email-already-in-use':
          return const EmailAlreadyInUseFailure();
        case 'weak-password':
          return const WeakPasswordFailure();
        case 'invalid-email':
          return const InvalidEmailFailure();
        case 'user-disabled':
          return const GenericAuthFailure('This account has been disabled');
        default:
          return GenericAuthFailure(e.message ?? e.code);
      }
    }

    if (e is UserNotFoundAuthException) return const UserNotFoundFailure();
    if (e is WrongPasswordAuthException) return const WrongPasswordFailure();
    if (e is WeakPasswordAuthException) return const WeakPasswordFailure();
    if (e is EmailAlreadyInUseAuthException) {
      return const EmailAlreadyInUseFailure();
    }
    if (e is InvalidEmailAuthException) return const InvalidEmailFailure();
    if (e is EmailNotVerifiedAuthException) {
      return const EmailNotVerifiedFailure();
    }
    if (e is UserNotLoggedInAuthException) {
      return const UserNotLoggedInFailure();
    }
    if (e is PasswordResetAuthException) {
      return PasswordResetFailure(e.message ?? 'Password reset failed');
    }
    if (e is GenericAuthException) {
      return GenericAuthFailure(e.message ?? 'Authentication failed');
    }

    if (e is AuthFailure) {
      return e;
    }

    return const GenericAuthFailure();
  }
}
