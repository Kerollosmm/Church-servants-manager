import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:church_management_system/features/auth/data/utils/auth_error_mapper.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthProvider _provider;
  AuthUser? _lastKnownAppUser;

  FirebaseAuthRepository({required FirebaseAuthProvider provider}) : _provider = provider;

  /// Get the current Firebase user (basic info)
  AuthUser? get currentUser => _provider.currentUser;

  /// Get stream of auth state changes
  Stream<AuthUser?> get authStateChanges => _provider.authStateChanges;

  @override
  Future<AuthUser?> getCurrentUser() async => getCurrentAppUser();

  /// Get current user with full app data from Firestore
  Future<AuthUser?> getCurrentAppUser({bool forceRefresh = false}) async {
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
  }

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
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _provider.logOut();
      _lastKnownAppUser = null;
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _provider.sendEmailVerification();
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _provider.sendPasswordReset(toEmail: email);
    } catch (e) {
      throw AuthErrorMapper.mapException(e);
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() => _provider.isEmailVerified();

  /// Reload user data
  Future<void> reloadUser() => _provider.reloadUser();

  /// Reload Firebase auth user and fetch a fresh app profile snapshot.
  Future<AuthUser?> refreshCurrentAppUser() async {
    await reloadUser();
    return getCurrentAppUser(forceRefresh: true);
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
