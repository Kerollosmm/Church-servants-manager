import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/force_password_reset_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

class RoleRouter {
  const RoleRouter._();

  static List<SingleChildWidget> listeners() {
    return [
      // FIX [015] Gate restored accounts that have restorePendingPasswordReset
      // to ForcePasswordResetScreen before granting access to the app.
      BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            current is AuthPendingPasswordReset &&
            previous is! AuthPendingPasswordReset,
        listener: (context, state) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const ForcePasswordResetScreen(),
            ),
            (route) => false,
          );
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            (previous is AuthAuthenticated && current is AuthDegraded) ||
            (previous is AuthDegraded && current is AuthAuthenticated),
        listener: (context, state) {
          if (state is AuthDegraded) {
            final destination = resolve(state.user.role, state);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => destination),
              (route) => false,
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            return;
          }

          if (state is AuthAuthenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
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
            final destination = resolve(state.user.role, state);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => destination),
              (route) => false,
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
      ),
      BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            (previous is AuthAuthenticated || previous is AuthDegraded) &&
            current is! AuthAuthenticated &&
            current is! AuthDegraded,
        listener: (context, state) {
          final Widget destination = switch (state) {
            AuthArchived(:final message, :final email) => ArchivedAccountScreen(
              message: message,
              email: email,
            ),
            AuthNeedsVerification() => const VerifyEmailScreen(),
            AuthError() || AuthUnauthenticated() => const LoginScreen(),
            _ => const LoginScreen(),
          };

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => destination),
            (route) => false,
          );

          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
      ),
    ];
  }

  static Widget resolve(UserRole role, AuthState state) {
    final hasResolvedUser = switch (state) {
      AuthAuthenticated() || AuthDegraded() => true,
      _ => false,
    };
    if (!hasResolvedUser) return const SizedBox.shrink();

    return switch (role) {
      UserRole.servant => switch (state) {
        AuthAuthenticated() => const ServantDashboardScreen(),
        AuthDegraded(:final message) => RoleRefreshRequiredScreen(
          title: 'يلزم تحديث صلاحيات الخادم',
          message: message,
        ),
        _ => const SizedBox.shrink(),
      },
      UserRole.student => switch (state) {
        AuthAuthenticated() => const StudentProfileScreen(),
        AuthDegraded(:final message) => RoleRefreshRequiredScreen(
          title: 'يلزم تحديث بيانات الحساب',
          message: message,
        ),
        _ => const SizedBox.shrink(),
      },
      UserRole.admin => switch (state) {
        // FIX [P1-B]: Replace unsafe cast with Dart 3 pattern matching
        AuthAuthenticated() => BlocProvider<AdminDashboardCubit>(
          create: (_) => getIt<AdminDashboardCubit>(),
          child: const AdminDashboardScreen(),
        ),
        AuthDegraded(:final message) => AdminRefreshRequiredScreen(
          message: message,
        ),
        _ => const SizedBox.shrink(),
      },
    };
  }
}

class RoleRefreshRequiredScreen extends StatelessWidget {
  const RoleRefreshRequiredScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_outlined, size: 56),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthEventRefreshUser()),
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث البيانات'),
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
