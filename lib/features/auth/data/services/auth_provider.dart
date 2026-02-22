import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';

/// Abstract auth provider interface following clean architecture
abstract class AuthProvider {
  /// Get the current authenticated user
  AuthUser? get currentUser;

  /// Stream of auth state changes
  Stream<AuthUser?> get authStateChanges;

  /// Login with email and password
  Future<AuthUser> logIn({required String email, required String password});

  /// Create a new user account
  Future<AuthUser> createUser({
    required String email,
    required String password,
    required String name,
    UserRole role,
    String? grade,
  });

  /// Log out the current user
  Future<void> logOut();

  /// Send email verification to current user
  Future<void> sendEmailVerification();

  /// Send password reset email
  Future<void> sendPasswordReset({required String toEmail});

  /// Check if current user's email is verified
  Future<bool> isEmailVerified();

  /// Reload current user data
  Future<void> reloadUser();

  /// Create a new user account as admin without disrupting current session.
  /// Uses a secondary FirebaseApp instance so the admin remains logged in.
  Future<AuthUser> createUserAsAdmin({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
  });
}
