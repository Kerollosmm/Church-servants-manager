import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';

/// Central place for admin authorization checks in the app.
/// Keep it pure (no Firebase, no UI) so it’s reusable & testable.
class AdminPolicy {
  const AdminPolicy();

  bool isAdmin(AuthUser user) => user.role == UserRole.admin;

  /// Admins have full access to all data and features.
  bool canAccessAllData(AuthUser user) => isAdmin(user);

  /// Privileged access requires both admin role and a fresh session.
  bool canAccessAdminArea({
    required AuthUser user,
    required bool isSessionFresh,
  }) {
    return isSessionFresh && isAdmin(user);
  }

  bool canManageTeams(AuthUser user) => isAdmin(user);
  bool canManageServants(AuthUser user) => isAdmin(user);
  bool canManageStudents(AuthUser user) => isAdmin(user);
  bool canOpenDevTools(AuthUser user) => isAdmin(user);
}
