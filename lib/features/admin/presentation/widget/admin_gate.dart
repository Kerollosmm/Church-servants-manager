import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/admin/domain/admin_policy.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wrap any screen that must be visible to admins only.
/// NOTE: UI reads AuthBloc state only (no Firebase calls here).
class AdminGate extends StatelessWidget {
  const AdminGate({super.key, required this.child, AdminPolicy? policy})
    : _policy = policy ?? const AdminPolicy();

  final Widget child;
  final AdminPolicy _policy;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          final user = state.user;
          if (_policy.canAccessAdminArea(user: user, isSessionFresh: true)) {
            return child;
          }
          return const _AdminAccessDeniedScreen();
        }

        if (state is AuthDegraded) {
          return _AdminRequiresFreshSession(message: state.message);
        }

        if (state is AuthArchived) {
          return const Scaffold(
            body: Center(child: Text('هذا الحساب غير متاح حاليا.')),
          );
        }

        return const Scaffold(body: Center(child: Text('Not signed in')));
      },
    );
  }
}

class _AdminRequiresFreshSession extends StatelessWidget {
  final String message;

  const _AdminRequiresFreshSession({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد الوصول للمسؤول'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_outlined, size: 64, color: AppColors.outline),
              AppSpacing.gapMd,
              Text(
                'يرجى مزامنة بيانات الحساب للمتابعة',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapSm,
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapLg,
              FilledButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthEventRefreshUser());
                },
                icon: const Icon(Icons.sync),
                label: const Text('مزامنة الوصول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAccessDeniedScreen extends StatelessWidget {
  const _AdminAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وصول غير مسموح'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.outline),
              AppSpacing.gapMd,
              Text(
                'مطلوب صلاحيات مسؤول',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AppSpacing.gapSm,
              const Text(
                'ليس لديك الصلاحيات الكافية لفتح هذه الشاشة.',
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapLg,
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
