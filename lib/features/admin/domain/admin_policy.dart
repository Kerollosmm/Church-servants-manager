import 'package:church_management_system/core/security/permission_matrix.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';

/// Central place for admin authorization checks in the app.
///
/// All admin permissions are derived from the canonical [PermissionMatrix]
/// to ensure consistency between app-level checks and Firestore security rules.
class AdminPolicy {
  const AdminPolicy();

  /// Checks if the user has admin role.
  bool isAdmin(AuthUser user) =>
      PermissionMatrix.canAccessAdminArea(user, isSessionFresh: true);

  /// Admins have full access to all data and features.
  bool canAccessAllData(AuthUser user) =>
      PermissionMatrix.canAccessAdminArea(user, isSessionFresh: true);

  /// Privileged access requires both admin role and a fresh session.
  bool canAccessAdminArea({
    required AuthUser user,
    required bool isSessionFresh,
  }) {
    return PermissionMatrix.canAccessAdminArea(
      user,
      isSessionFresh: isSessionFresh,
    );
  }

  /// Can the admin manage teams?
  bool canManageTeams(AuthUser user) => PermissionMatrix.canManageTeams(user);

  /// Can the admin manage servants?
  bool canManageServants(AuthUser user) =>
      PermissionMatrix.canManageServants(user);

  /// Can the admin manage students?
  bool canManageStudents(AuthUser user) =>
      PermissionMatrix.canManageStudents(user);

  /// Can the admin access dev tools?
  bool canOpenDevTools(AuthUser user) =>
      PermissionMatrix.canAccessDevTools(user);
}
