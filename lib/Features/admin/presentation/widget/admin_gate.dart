import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/core/routing/role_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final isAdmin =
        state is AuthAuthenticated && state.user.role == UserRole.admin;

    if (isAdmin) {
      return child;
    }

    if (state is AuthDegraded && state.user.role == UserRole.admin) {
      return AdminRefreshRequiredScreen(message: state.message);
    }

    if (state is AuthArchived) {
      return ArchivedAccountScreen(message: state.message, email: state.email);
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
    });

    return const SizedBox.shrink();
  }
}
