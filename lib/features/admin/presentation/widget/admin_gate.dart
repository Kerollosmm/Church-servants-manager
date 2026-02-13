import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/admin/domain/admin_policy.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wrap any screen that must be visible to admins only.
/// NOTE: UI reads AuthBloc state only (no Firebase calls here). :contentReference[oaicite:2]{index=2}
class AdminGate extends StatelessWidget {
  const AdminGate({
    super.key,
    required this.child,
    AdminPolicy? policy,
  }) : _policy = policy ?? const AdminPolicy();

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
          if (_policy.canAccessAllData(state.user)) return child;
          return const _AdminAccessDeniedScreen();
        }

        return const Scaffold(
          body: Center(child: Text('Not signed in')),
        );
      },
    );
  }
}

class _AdminAccessDeniedScreen extends StatelessWidget {
  const _AdminAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access denied'),
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
                'Admin access required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AppSpacing.gapSm,
              Text(
                'You don\'t have permission to open this screen.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              AppSpacing.gapLg,
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
