import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:church_management_system/features/auth/data/utils/auth_error_mapper.dart';
import 'package:church_management_system/features/auth/domain/auth_freshness_policy.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthProvider _provider;
  final AuthFreshnessPolicy _freshnessPolicy;
  AuthUser? _lastKnownAppUser;

  FirebaseAuthRepository({
    required FirebaseAuthProvider provider,
    required AuthFreshnessPolicy freshnessPolicy,
  }) : _provider = provider,
       _freshnessPolicy = freshnessPolicy;

  /// Get the current Firebase user (basic info)
  @override
  AuthUser? get currentUser => _provider.currentUser;

  /// Get stream of auth state changes
  @override
  Stream<AuthUser?> get authStateChanges => _provider.authStateChanges;

  @override
  Future<AuthUser?> getCurrentUser() async => getCurrentAppUser();

  /// Get current user with full app data from Firestore
  @override
  Future<AuthUser?> getCurrentAppUser({bool forceRefresh = false}) async {
    try {
      final firebaseUser = _provider.currentUser;
      if (firebaseUser == null) {
        _lastKnownAppUser = null;
        return null;
      }

      final appUser = await _provider.getUserData(
        firebaseUser.uid,
        forceRefresh: forceRefresh,
      );
      _lastKnownAppUser = appUser;
      return appUser;
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  AuthUser? get lastKnownAppUser => _lastKnownAppUser;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _provider.logIn(email: email, password: password);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String name,
    String? grade,
  }) async {
    try {
      return await _provider.createUser(
        email: email,
        password: password,
        name: name,
        grade: grade,
      );
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _provider.logOut();
      await _freshnessPolicy.reset();
      _lastKnownAppUser = null;
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Send email verification
  @override
  Future<void> sendEmailVerification() async {
    try {
      await _provider.sendEmailVerification();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Send password reset email
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _provider.sendPasswordReset(toEmail: email);
    } catch (e) {
      if (e is UserNotFoundAuthException) {
        // Swallow exception to prevent account enumeration
        return;
      }
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      return await _provider.isEmailVerified();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Reload user data
  @override
  Future<void> reloadUser() async {
    try {
      await _provider.reloadUser();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Reload Firebase auth user and fetch a fresh app profile snapshot.
  @override
  Future<AuthUser?> refreshCurrentAppUser() async {
    try {
      await forceTokenRefresh();
      await reloadUser();
      return getCurrentAppUser(forceRefresh: true);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Force a token refresh, e.g. when claims change
  Future<void> forceTokenRefresh() async {
    try {
      await _provider.forceTokenRefresh();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _provider.updatePassword(newPassword);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Clear the restorePendingPasswordReset flag on the user's Firestore doc
  @override
  Future<void> clearRestorePendingPasswordReset(String uid) async {
    final currentUid = currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw GenericAuthException(
        'تحذير أمني: لا تملك صلاحية تعديل هذا الحساب.',
      );
    }
    try {
      await _provider.clearRestorePendingPasswordReset(uid);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }
}
