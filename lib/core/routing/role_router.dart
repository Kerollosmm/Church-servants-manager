import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

class RoleRouter {
  const RoleRouter._();

  static List<SingleChildWidget> listeners() {
    return [
      BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous is! AuthAuthenticated &&
            previous is! AuthDegraded &&
            (current is AuthAuthenticated || current is AuthDegraded),
        listener: (context, state) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (state is AuthDegraded) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            (previous is AuthDegraded &&
                current is AuthDegraded &&
                previous.message != current.message) ||
            ((previous is AuthAuthenticated || previous is AuthDegraded) &&
                current is AuthDegraded &&
                previous is! AuthDegraded),
        listener: (context, state) {
          if (state is AuthDegraded) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
      ),
    ];
  }

  static Widget resolve(UserRole role, AuthState state) {
    final user = switch (state) {
      AuthAuthenticated(:final user) || AuthDegraded(:final user) => user,
      _ => null,
    };
    if (user == null) return const SizedBox.shrink();

    return switch (role) {
      UserRole.servant => ServantDashboardScreen(user: user),
      UserRole.student => StudentProfileScreen(user: user),
      UserRole.admin => switch (state) {
        // FIX [P1-B]: Replace unsafe cast with Dart 3 pattern matching
        AuthAuthenticated() =>
          AdminDashboardScreen(), // FIX [P1-B]: Safe type check via exhaustive switch
        AuthDegraded(:final message) => AdminRefreshRequiredScreen(
          message: message,
        ), // FIX [P1-B]: Destructure message safely, no cast
        _ =>
          const SizedBox.shrink(), // FIX [P1-B]: Safe fallback for any unexpected admin auth state
      },
    };
  }
}

class AdminRefreshRequiredScreen extends StatelessWidget {
  const AdminRefreshRequiredScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تم إيقاف صلاحيات المسؤول مؤقتا')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'إجراءات المسؤول متوقفة مؤقتا حتى يتم تحديث بيانات الحساب.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthEventRefreshUser()),
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الصلاحيات'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthEventSignOut()),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArchivedAccountScreen extends StatelessWidget {
  const ArchivedAccountScreen({super.key, required this.message, this.email});

  final String message;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تم إيقاف الحساب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'هذا الحساب غير متاح حاليا',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (email?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(email!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthEventSignOut()),
                child: const Text('العودة لتسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
