import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/features/admin/presentation/widget/admin_gate.dart';
import 'package:church_managment_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/register_screen.dart';

import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/widgets/not_found_screen.dart';
import 'package:church_managment_system/features/devtools/presentation/dev_tools_screen.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_detail_screen.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_edit_screen.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_management_screen.dart';
import 'package:church_managment_system/features/servant/presentation/screens/servant_list_screen.dart';
import 'package:church_managment_system/features/servant/presentation/screens/servant_detail_screen.dart';
import 'package:church_managment_system/features/servant/presentation/screens/add_edit_servant_screen.dart';
import 'package:church_managment_system/features/team/presentation/screens/team_management_screen.dart';
import 'package:church_managment_system/features/team/presentation/screens/team_members_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  Route<dynamic> _buildPageRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  Route<dynamic> _buildMessageRoute({
    required RouteSettings settings,
    required String message,
  }) {
    return _buildPageRoute(
      settings: settings,
      builder: (_) => Scaffold(body: Center(child: Text(message))),
    );
  }

  Route<dynamic> _buildArgsValidatedRoute<T>({
    required RouteSettings settings,
    required Widget Function(T args) builder,
    required String invalidMessage,
  }) {
    final args = settings.arguments;
    if (args is T) {
      return _buildPageRoute(settings: settings, builder: (_) => builder(args));
    }
    return _buildMessageRoute(settings: settings, message: invalidMessage);
  }

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return _buildPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case forgotPassword:
        return _buildPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case studentList:
        return _buildPageRoute(
          builder: (_) => const StudentManagementScreen(),
          settings: settings,
        );
      case studentDetail:
        return _buildArgsValidatedRoute<StudentDetailArgs>(
          settings: settings,
          builder: (args) => StudentDetailScreen(args: args),
          invalidMessage: 'Invalid student data',
        );
      case studentEdit:
        return _buildArgsValidatedRoute<StudentEditArgs>(
          settings: settings,
          builder: (args) => StudentEditScreen(args: args),
          invalidMessage: 'Invalid student data',
        );
      // Servant Routes
      case servantList:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: ServantListScreen()),
          settings: settings,
        );
      case servantDetail:
        return _buildArgsValidatedRoute<ServantDetailArgs>(
          settings: settings,
          builder: (args) => AdminGate(child: ServantDetailScreen(args: args)),
          invalidMessage: 'Invalid servant data',
        );
      case servantEdit:
        return _buildArgsValidatedRoute<ServantEditArgs>(
          settings: settings,
          builder: (args) => AdminGate(child: AddEditServantScreen(args: args)),
          invalidMessage: 'Invalid servant data',
        );

      case devTools:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: DevToolsScreen()),
          settings: settings,
        );

      case teamManagement:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: TeamManagementScreen()),
          settings: settings,
        );
      case teamMembers:
        return _buildArgsValidatedRoute<TeamMembersArgs>(
          settings: settings,
          builder: (args) => AdminGate(child: TeamMembersScreen(args: args)),
          invalidMessage: 'Invalid team member data',
        );
      case adminScreen:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: AdminDashboardScreen()),
          settings: settings,
        );

      default:
        return _buildPageRoute(
          builder: (_) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }
}
