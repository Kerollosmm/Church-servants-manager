import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/widgets/dialogs/error_dialog.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:church_managment_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root dispatcher widget that handles role-based navigation.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          // Only show global error dialog if we're not on a specific auth screen
          // Or if it's a critical initialization error.
          // For now, we'll keep it but ensure local screens also handle it.
          showErrorDialog(context, state.message);
        } else if (state is AuthAuthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
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
                return StudentProfileScreen(user: user);
              case UserRole.admin:
                return ServantDashboardScreen(user: user);
            }
          }

          // Needs verification
          if (state is AuthNeedsVerification) {
            return const VerifyEmailScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
