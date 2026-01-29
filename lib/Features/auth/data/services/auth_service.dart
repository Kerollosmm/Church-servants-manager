import 'package:csms/Features/auth/data/services/firebase_auth_provider.dart';
import 'package:csms/Features/auth/data/services/auth_exceptions.dart';
import 'package:csms/Features/auth/domain/failures/auth_failures.dart';
import 'package:csms/core/constants/enums.dart';
import 'package:csms/core/models/auth_user.dart';

/// AuthService provides a facade over authentication providers.
/// This follows the service pattern from the reference Notely app.
class AuthService {
  final FirebaseAuthProvider _provider;

  AuthService._internal(this._provider);

  static final AuthService _instance = AuthService._internal(
    FirebaseAuthProvider(),
  );

  /// Factory constructor to get Firebase auth service
  factory AuthService.firebase() => _instance;

  /// Get the current Firebase user (basic info)
  AuthUser? get currentUser => _provider.currentUser;

  /// Get stream of auth state changes
  Stream<AuthUser?> get authStateChanges => _provider.authStateChanges;

  /// Get current user with full app data from Firestore
  Future<AuthUser?> getCurrentAppUser() async {
    final firebaseUser = _provider.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await _provider.getUserData(firebaseUser.uid);
    } catch (_) {
      return firebaseUser;
    }
  }

  /// Login with email and password
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _provider.logIn(email: email, password: password);
    } on EmailNotVerifiedAuthException {
      throw const EmailNotVerifiedFailure();
    } on UserNotFoundAuthException {
      throw const UserNotFoundFailure();
    } on WrongPasswordAuthException {
      throw const WrongPasswordFailure();
    } on InvalidEmailAuthException {
      throw const InvalidEmailFailure();
    } on GenericAuthException catch (e) {
      throw GenericAuthFailure(e.message ?? 'Authentication failed');
    } catch (_) {
      throw const GenericAuthFailure('An unexpected error occurred');
    }
  }

  /// Register a new user
  Future<AuthUser> register({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
    String? grade,
  }) async {
    try {
      return await _provider.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
        grade: grade,
      );
    } on WeakPasswordAuthException {
      throw const WeakPasswordFailure();
    } on EmailAlreadyInUseAuthException {
      throw const EmailAlreadyInUseFailure();
    } on InvalidEmailAuthException {
      throw const InvalidEmailFailure();
    } on GenericAuthException catch (e) {
      throw GenericAuthFailure(e.message ?? 'Registration failed');
    } catch (_) {
      throw const GenericAuthFailure('An unexpected error occurred');
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      await _provider.logOut();
    } on UserNotLoggedInAuthException {
      throw const UserNotLoggedInFailure();
    } catch (_) {
      throw const GenericAuthFailure('Logout failed');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _provider.sendEmailVerification();
    } on UserNotLoggedInAuthException {
      throw const UserNotLoggedInFailure();
    } catch (_) {
      throw const GenericAuthFailure('Failed to send verification email');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _provider.sendPasswordReset(toEmail: email);
    } on InvalidEmailAuthException {
      throw const InvalidEmailFailure();
    } on UserNotFoundAuthException {
      throw const UserNotFoundFailure();
    } on PasswordResetAuthException catch (e) {
      throw PasswordResetFailure(e.message ?? 'Password reset failed');
    } catch (_) {
      throw const GenericAuthFailure('Failed to send password reset email');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() => _provider.isEmailVerified();

  /// Reload user data
  Future<void> reloadUser() => _provider.reloadUser();
}
