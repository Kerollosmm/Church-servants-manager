import 'dart:async';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, FirebaseAuthException, User;

class FirebaseIdentityProvider {
  final FirebaseAuth _auth;

  FirebaseIdentityProvider({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.userChanges();

  Stream<Map<String, dynamic>> get idTokenChanges =>
      _auth.idTokenChanges().asyncMap((user) async {
        if (user == null) return {};
        final result = await user.getIdTokenResult();
        return result.claims ?? {};
      });

  Future<User> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw UserNotLoggedInAuthException();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw UserNotFoundAuthException();
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          throw WrongPasswordAuthException();
        case 'invalid-email':
          throw InvalidEmailAuthException();
        case 'user-disabled':
          throw const GenericAuthException('This account has been disabled');
        default:
          rethrow;
      }
    } catch (e) {
      if (e is AuthFailure || e is Exception) rethrow;
      throw GenericAuthException('Login failed: $e');
    }
  }

  Future<User> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw UserNotLoggedInAuthException();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw WeakPasswordAuthException();
        case 'email-already-in-use':
          throw EmailAlreadyInUseAuthException();
        case 'invalid-email':
          throw InvalidEmailAuthException();
        default:
          rethrow;
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  Future<void> sendPasswordReset({required String toEmail}) async {
    try {
      await _auth.sendPasswordResetEmail(email: toEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'firebase_auth/user-not-found') {
        // Swallow user-not-found to prevent account enumeration
        return;
      }
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw UserNotLoggedInAuthException();
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          throw RequiresRecentLoginAuthException();
        case 'weak-password':
          throw WeakPasswordAuthException();
        default:
          throw GenericAuthException('Password update failed: ${e.message}');
      }
    } catch (e) {
      throw GenericAuthException('Password update failed: $e');
    }
  }

  Future<void> forceTokenRefresh() async {
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }
}
