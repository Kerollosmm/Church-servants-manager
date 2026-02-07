import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home screen for students.
///
/// Displays user info and provides actions like logout and refresh.
class StudentHomeScreen extends StatelessWidget {
  /// The authenticated user.
  final AuthUser user;

  /// Creates a [StudentHomeScreen].
  const StudentHomeScreen({super.key, required this.user});

  Future<void> _onRefresh(BuildContext context) async {
    context.read<AuthBloc>().add(const AuthEventRefreshUser());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Student Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthEventSignOut());
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 80, color: AppColors.primary),
                  AppSpacing.gapLg,
                  Text(
                    'Welcome Student',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapXl,
                  _UserInfoCard(user: user),
                  AppSpacing.gapLg,
                  Text(
                    'Pull down to refresh your role',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays user information in a card.
class _UserInfoCard extends StatelessWidget {
  final AuthUser user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _InfoRow(label: 'Email', value: user.email),
            _InfoRow(label: 'Role', value: user.role.name.toUpperCase()),
          ],
        ),
      ),
    );
  }
}

/// A single row displaying a label and value.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
