import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_managment_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:church_managment_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_managment_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root dispatcher widget that handles role-based navigation.
class RoleUserRoute extends StatelessWidget {
  const RoleUserRoute({super.key});

  bool _isAuthenticatedState(AuthState state) =>
      state is AuthAuthenticated || state is AuthDegraded;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              !_isAuthenticatedState(previous) &&
              _isAuthenticatedState(current),
          listener: (context, state) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            if (state is AuthDegraded) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            if (current is! AuthDegraded) return false;
            if (!_isAuthenticatedState(previous)) return false;
            if (previous is AuthDegraded) {
              return previous.message != current.message;
            }
            return true;
          },
          listener: (context, state) {
            if (state is AuthDegraded) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Loading state
          if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Authenticated - route based on role
          if (state is AuthAuthenticated || state is AuthDegraded) {
            final user = state is AuthAuthenticated
                ? state.user
                : (state as AuthDegraded).user;
            switch (user.role) {
              case UserRole.servant:
                return ServantDashboardScreen(user: user);
              case UserRole.student:
                return StudentProfileScreen(user: user);
              case UserRole.admin:
                return AdminDashboardScreen();
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
