import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDashboardScreen extends StatelessWidget {
  final AuthUser user;
  static const double _appBarOffset = 100.0;

  const ServantDashboardScreen({super.key, required this.user});

  Future<void> _onRefresh(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    // Wait for the next non-loading state
    final future = authBloc.stream.firstWhere((state) => state is! AuthLoading);
    authBloc.add(const AuthEventRefreshUser());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = user.role == UserRole.admin;
    final roleLabel = isAdmin ? 'Admin' : 'Teacher';

    return Scaffold(
      appBar: _buildAppBar(context, isAdmin),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - _appBarOffset,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.church, size: 80, color: AppColors.primary),
                  AppSpacing.gapLg,
                  Text(
                    'Welcome $roleLabel',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.gapXl,
                  _UserStatsCard(user: user),
                  AppSpacing.gapLg,
                  // Manage Students button for admins and teachers
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, studentList);
                    },
                    icon: const Icon(Icons.people),
                    label: Text(
                      isAdmin ? 'Manage Students' : 'Manage My Group',
                    ),
                  ),
                  // Manage Servants button for admins only
                  if (isAdmin) ...[
                    AppSpacing.gapMd,
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, servantList);
                      },
                      icon: const Icon(Icons.supervisor_account),
                      label: const Text('Manage Servants'),
                    ),
                  ],
                  if (kDebugMode) ...[
                    AppSpacing.gapMd,
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, devTools);
                      },
                      icon: const Icon(Icons.build_outlined),
                      label: const Text('Dev Tools'),
                    ),
                  ],
                  AppSpacing.gapMd,
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

  AppBar _buildAppBar(BuildContext context, bool isAdmin) {
    return AppBar(
      title: Text(isAdmin ? 'Admin Dashboard' : 'Teacher Dashboard'),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            context.read<AuthBloc>().add(const AuthEventSignOut());
          },
          tooltip: 'Logout',
        ),
      ],
    );
  }
}

class _UserStatsCard extends StatelessWidget {
  final AuthUser user;

  const _UserStatsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.role == UserRole.servant
        ? 'TEACHER'
        : user.role.name.toUpperCase();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _infoRow('Email', user.email),
            _infoRow('Role', roleLabel),
            if (user.role == UserRole.servant)
              _infoRow('Group', user.groupId ?? '--'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
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
