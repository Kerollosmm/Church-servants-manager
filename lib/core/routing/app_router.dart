import 'package:church_managment_system/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/register_screen.dart';

import 'package:church_managment_system/features/student/presentation/screens/student_list_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String studentList = '/students';

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
          builder: (_) => const StudentListScreen(),
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
