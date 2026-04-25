import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_auth_client.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_management_system/features/auth/domain/failures/auth_failures.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';

abstract class AdminUserProvisioningService {
  Future<AuthUser> createUser({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
  });

  Future<void> rollbackCreatedUser({
    required String uid,
    required String email,
    required String password,
  });

  Future<void> archiveUser({required String uid});

  Future<void> restoreUser({required String uid});

  Future<void> changeUserRole({required String uid, required UserRole role});
}

class ClientAdminUserProvisioningService
    implements AdminUserProvisioningService {
  ClientAdminUserProvisioningService({
    required AuthUserProfileStore userProfileStore,
    required AuthRepository authService,
    AdminAuthClient? adminAuthClient,
  }) : _userProfileStore = userProfileStore,
       _authService = authService,
       _adminAuthClient = adminAuthClient ?? FirebaseAdminAuthClient();

  final AuthUserProfileStore _userProfileStore;
  final AuthRepository _authService;
  final AdminAuthClient _adminAuthClient;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.student,
  }) async {
    AdminAuthUserHandle? createdAuthUser;
    var profileSaved = false;

    try {
      createdAuthUser = await _adminAuthClient.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      final appUser = AuthUser(
        uid: createdAuthUser.uid,
        name: name,
        email: email,
        role: role,
      );

      await _userProfileStore.saveUser(appUser);
      profileSaved = true;

      return appUser;
    } catch (e) {
      if (!profileSaved && createdAuthUser != null) {
        try {
          await _adminAuthClient.rollbackCreatedUser(uid: createdAuthUser.uid);
        } catch (_) {
          throw const GenericAuthException(
            'Account setup failed and cleanup was incomplete. Please contact support or try again later.',
          );
        }
      }

      if (e is AuthFailure ||
          e is EmailAlreadyInUseAuthException ||
          e is InvalidEmailAuthException ||
          e is WeakPasswordAuthException ||
          e is UserNotLoggedInAuthException ||
          e is GenericAuthException) {
        rethrow;
      }
      throw GenericAuthException('Account creation failed: $e');
    }
  }

  @override
  Future<void> rollbackCreatedUser({
    required String uid,
    required String email,
    required String password,
  }) async {
    try {
      await _adminAuthClient.rollbackCreatedUser(uid: uid);
      await _userProfileStore.deleteUser(uid);
    } catch (e) {
      if (e is UserNotFoundAuthException) {
        try {
          await _userProfileStore.deleteUser(uid);
          return;
        } catch (_) {
          throw const GenericAuthException(
            'Rollback removed the auth account but failed to remove the user profile. Please clean up the profile manually.',
          );
        }
      }

      if (e is AuthFailure) rethrow;
      throw GenericAuthException('Rollback failed: $e');
    }
  }

  @override
  Future<void> archiveUser({required String uid}) async {
    try {
      // AdminAuthClient now handles direct Firestore update for Spark Plan compatibility
      await _adminAuthClient.archiveUser(uid: uid);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw GenericAuthException('Archive failed: $e');
    }
  }

  @override
  Future<void> restoreUser({required String uid}) async {
    try {
      final user = await _userProfileStore.fetchUser(uid);
      // AdminAuthClient handles direct Firestore update
      await _adminAuthClient.restoreUser(uid: uid);
      // We still trigger a password reset for the restored user as a security best practice
      await _authService.sendPasswordResetEmail(user.email);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw GenericAuthException('Restore failed: $e');
    }
  }

  @override
  Future<void> changeUserRole({
    required String uid,
    required UserRole role,
  }) async {
    try {
      await _adminAuthClient.changeUserRole(uid: uid, role: role);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw GenericAuthException('Role change failed: $e');
    }
  }
}
