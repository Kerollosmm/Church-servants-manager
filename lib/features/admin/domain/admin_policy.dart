import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/core/constants/enums.dart';

/// Central place for admin authorization checks in the app.
/// Keep it pure (no Firebase, no UI) so it’s reusable & testable.
class AdminPolicy {
  const AdminPolicy();

  bool isAdmin(AuthUser user) => user.role == UserRole.admin;

  /// Admins have full access to all data and features.
  bool canAccessAllData(AuthUser user) => isAdmin(user);

  bool canManageTeams(AuthUser user) => isAdmin(user);
  bool canManageServants(AuthUser user) => isAdmin(user);
  bool canManageStudents(AuthUser user) => isAdmin(user);
  bool canOpenDevTools(AuthUser user) => isAdmin(user);
}
