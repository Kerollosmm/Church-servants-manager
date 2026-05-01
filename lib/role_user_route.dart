import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/forced_password_reset_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_dashboard_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root dispatcher widget that handles role-based navigation.
class RoleUserRoute extends StatelessWidget {
  const RoleUserRoute({super.key});

  bool _isAuthenticatedState(AuthState state) =>
      state is AuthAuthenticated || state is AuthDegraded;

  Widget _buildHomeForAuthenticatedUser(UserRole role, AuthState state) {
    final user = state is AuthAuthenticated
        ? state.user
        : (state as AuthDegraded).user;

    switch (role) {
      case UserRole.servant:
        return ServantDashboardScreen(user: user);
      case UserRole.student:
        return StudentProfileScreen(user: user);
      case UserRole.admin:
        if (state is AuthAuthenticated) {
          return AdminDashboardScreen();
        }
        return _AdminRefreshRequiredScreen(
          message: (state as AuthDegraded).message,
        );
    }
  }

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
              AppSnackbars.showInfo(context, state.message);
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
              AppSnackbars.showInfo(context, state.message);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthRoleUpdated) {
              AppSnackbars.showSuccess(
                context,
                'تم تحديث صلاحيات الحساب بنجاح.',
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Loading state
          if (state is AuthLoading ||
              state is AuthSigningOut ||
              state is AuthRoleRefreshing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is AuthArchived) {
            return _ArchivedAccountScreen(
              message: state.message,
              email: state.email,
            );
          }

          // Authenticated - route based on role
          if (state is AuthAuthenticated || state is AuthDegraded) {
            final role = state is AuthAuthenticated
                ? state.user.role
                : (state as AuthDegraded).user.role;
            return _buildHomeForAuthenticatedUser(role, state);
          }

          // Needs verification
          if (state is AuthNeedsVerification) {
            return const VerifyEmailScreen();
          }

          // Needs forced password reset
          if (state is AuthNeedsPasswordReset) {
            return const ForcedPasswordResetScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class _AdminRefreshRequiredScreen extends StatelessWidget {
  final String message;

  const _AdminRefreshRequiredScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديث الوصول للمسؤول')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'يرجى مزامنة البيانات للحصول على كامل صلاحيات المسؤول.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventRefreshUser());
                },
                icon: const Icon(Icons.sync),
                label: const Text('مزامنة الوصول'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventSignOut());
                },
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedAccountScreen extends StatelessWidget {
  const _ArchivedAccountScreen({required this.message, this.email});

  final String message;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحساب غير متاح')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_outlined, size: 56),
              const SizedBox(height: 12),
              const Text(
                'عذراً، الوصول لهذا الحساب متوقف حالياً.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(email!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventSignOut());
                },
                child: const Text('العودة لتسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
