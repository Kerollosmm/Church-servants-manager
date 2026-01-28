import 'package:csms/core/constants/enums.dart';
import 'package:csms/core/models/user.dart';

/// Abstract repository interface for authentication operations.
/// This follows Clean Architecture principles - domain layer doesn't
/// depend on external frameworks.
abstract class AuthRepository {
  /// Signs in user with email and password.
  Future<AppUser> signIn({required String email, required String password});

  /// Creates a new user account.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? grade,
  });

  /// Signs out the current user.
  Future<void> signOut();

  /// Gets the currently authenticated user, if any.
  Future<AppUser?> getCurrentUser();
}
