import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/features/admin/presentation/widget/admin_gate.dart';
import 'package:church_managment_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/register_screen.dart';

import 'package:church_managment_system/core/routing/route_args.dart';
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
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case studentList:
        return MaterialPageRoute(
          builder: (_) => const StudentManagementScreen(),
          settings: settings,
        );
      case studentDetail:
        final args = settings.arguments;
        if (args is StudentDetailArgs) {
          return MaterialPageRoute(
            builder: (_) => StudentDetailScreen(args: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Invalid student data'))),
          settings: settings,
        );
      case studentEdit:
        final args = settings.arguments;
        if (args is StudentEditArgs) {
          return MaterialPageRoute(
            builder: (_) => StudentEditScreen(args: args),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Invalid student data'))),
          settings: settings,
        );
      // Servant Routes
      case servantList:
        return MaterialPageRoute(
          builder: (_) => const AdminGate(child: ServantListScreen()),
          settings: settings,
        );
      case servantDetail:
        final args = settings.arguments;
        if (args is ServantDetailArgs) {
          return MaterialPageRoute(
            builder: (_) =>
                AdminGate(child: ServantDetailScreen(args: args)),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Invalid servant data'))),
          settings: settings,
        );
      case servantEdit:
        final args = settings.arguments;
        if (args is ServantEditArgs) {
          return MaterialPageRoute(
            builder: (_) =>
                AdminGate(child: AddEditServantScreen(args: args)),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Invalid servant data'))),
          settings: settings,
        );

      case devTools:
        return MaterialPageRoute(
          builder: (_) => const AdminGate(child: DevToolsScreen()),
          settings: settings,
        );

      case teamManagement:
        return MaterialPageRoute(
          builder: (_) => const AdminGate(child: TeamManagementScreen()),
          settings: settings,
        );
      case teamMembers:
        final args = settings.arguments;
        if (args is TeamMembersArgs) {
          return MaterialPageRoute(
            builder: (_) => AdminGate(child: TeamMembersScreen(args: args)),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Invalid team member data')),
          ),
          settings: settings,
        );
      case adminScreen:
        return MaterialPageRoute(
          builder: (_) => const AdminGate(child: AdminDashboardScreen()),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
          settings: settings,
        );
    }
  }
}
