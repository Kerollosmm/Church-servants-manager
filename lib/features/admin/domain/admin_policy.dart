import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';

/// Central place for admin authorization checks in the app.
class AdminPolicy {
  const AdminPolicy();

  /// Checks if the user has admin role.
  bool isAdmin(AuthUser user) => user.role == UserRole.admin;

  /// Admins have full access to all data and features.
  bool canAccessAllData(AuthUser user) => user.role == UserRole.admin;

  /// Privileged access requires both admin role and a fresh session.
  bool canAccessAdminArea({
    required AuthUser user,
    required bool isSessionFresh,
  }) {
    return user.role == UserRole.admin && isSessionFresh;
  }

  /// Can the admin manage teams?
  bool canManageTeams(AuthUser user) => user.role == UserRole.admin;

  /// Can the admin manage servants?
  bool canManageServants(AuthUser user) => user.role == UserRole.admin;

  /// Can the admin manage students?
  bool canManageStudents(AuthUser user) => user.role == UserRole.admin;

  /// Can the admin access dev tools?
  bool canOpenDevTools(AuthUser user) => user.role == UserRole.admin;
}
