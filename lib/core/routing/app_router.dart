import 'package:csms/Features/auth/presentation/screens/login_screen.dart';
import 'package:csms/Features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
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
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
          settings: settings,
        );
    }
  }
}
