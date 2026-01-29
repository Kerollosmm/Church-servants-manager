import 'package:csms/core/constants/enums.dart';
import 'package:csms/core/models/auth_user.dart';

abstract class AuthRepository {
  /// Signs in user with email and password.
  Future<AuthUser> signIn({required String email, required String password});

  /// Creates a new user account.
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? grade,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Gets the currently authenticated user, if any.
  Future<AuthUser?> getCurrentUser();
}
