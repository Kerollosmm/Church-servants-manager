import 'package:church_management_system/features/auth/data/models/auth_user.dart';

abstract class AuthRepository {
  /// Get stream of auth state changes
  Stream<AuthUser?> get authStateChanges;

  /// Get the current Firebase user (basic info)
  AuthUser? get currentUser;

  /// Get the last known app user data
  AuthUser? get lastKnownAppUser;

  /// Reloads the current user data from the provider
  Future<void> reloadUser();

  /// Gets the currently authenticated user, if any.
  Future<AuthUser?> getCurrentUser();

  /// Get current user with full app data from Firestore
  Future<AuthUser?> getCurrentAppUser({bool forceRefresh = false});

  /// Refresh current app user and return it
  Future<AuthUser?> refreshCurrentAppUser();

  /// Signs in user with email and password.
  Future<AuthUser> signIn({required String email, required String password});

  /// Creates a new user account.
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String name,
    String? grade,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Updates the current user's password.
  Future<void> updatePassword(String newPassword);

  /// Clears the restorePendingPasswordReset flag on the user's Firestore doc.
  Future<void> clearRestorePendingPasswordReset(String uid);

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email);
}
