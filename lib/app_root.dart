import 'package:csms/Features/auth/presentation/bloc/auth_bloc.dart';
import 'package:csms/Features/auth/presentation/screens/login_screen.dart';
import 'package:csms/Features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:csms/Features/student/presentation/screens/student_home_screen.dart';
import 'package:csms/core/constants/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root dispatcher widget that handles role-based navigation.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Loading state
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Authenticated - route based on role
        if (state is AuthAuthenticated) {
          final user = state.user;

          switch (user.role) {
            case UserRole.servant:
              return ServantDashboardScreen(user: user);
            case UserRole.student:
              return StudentHomeScreen(user: user);
            case UserRole.admin:
              return ServantDashboardScreen(user: user);
          }
        }

        // Needs verification - show login with dialog trigger
        // (LoginScreen handles the dialog via BlocListener)

        // Unauthenticated, Initial, NeedsVerification, Error - show login
        return const LoginScreen();
      },
    );
  }
}
