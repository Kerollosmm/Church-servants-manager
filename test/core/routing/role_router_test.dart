import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/role_router.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AuthUser buildUser(UserRole role) => AuthUser(
    uid: 'user-${role.name}',
    email: '${role.name}@example.com',
    name: role.name,
    role: role,
    isEmailVerified: true,
  );

  group('RoleRouter.resolve', () {
    test('returns servant dashboard for servant users', () {
      final user = buildUser(UserRole.servant);

      final widget = RoleRouter.resolve(
        UserRole.servant,
        AuthAuthenticated(user),
      );

      expect(widget, isA<ServantDashboardScreen>());
    });

    test('returns student profile for student users', () {
      final user = buildUser(UserRole.student);

      final widget = RoleRouter.resolve(
        UserRole.student,
        AuthAuthenticated(user),
      );

      expect(widget, isA<StudentProfileScreen>());
    });

    test('returns admin dashboard for authenticated admins', () {
      final user = buildUser(UserRole.admin);

      final widget = RoleRouter.resolve(
        UserRole.admin,
        AuthAuthenticated(user),
      );

      expect(widget, isA<BlocProvider<AdminDashboardCubit>>());
    });

    test('returns refresh-required screen for degraded admins', () {
      final user = buildUser(UserRole.admin);

      final widget = RoleRouter.resolve(
        UserRole.admin,
        AuthDegraded(user: user, message: 'Refresh required'),
      );

      expect(widget, isA<AdminRefreshRequiredScreen>());
    });

    test('returns refresh-required screen for degraded servants', () {
      final user = buildUser(UserRole.servant);

      final widget = RoleRouter.resolve(
        UserRole.servant,
        AuthDegraded(user: user, message: 'Refresh required'),
      );

      expect(widget, isA<RoleRefreshRequiredScreen>());
    });

    test('returns refresh-required screen for degraded students', () {
      final user = buildUser(UserRole.student);

      final widget = RoleRouter.resolve(
        UserRole.student,
        AuthDegraded(user: user, message: 'Refresh required'),
      );

      expect(widget, isA<RoleRefreshRequiredScreen>());
    });
  });
}
