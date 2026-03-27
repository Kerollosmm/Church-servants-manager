import 'package:church_management_system/core/routing/role_router.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleUserRoute extends StatelessWidget {
  const RoleUserRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: RoleRouter.listeners(),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return switch (state) {
            AuthLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            AuthArchived() => ArchivedAccountScreen(
              message: state.message,
              email: state.email,
            ),
            AuthAuthenticated() => RoleRouter.resolve(state.user.role, state),
            AuthDegraded() => RoleRouter.resolve(state.user.role, state),
            AuthNeedsVerification() => const VerifyEmailScreen(),
            _ => const LoginScreen(),
          };
        },
      ),
    );
  }
}
