import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
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
    const roleLabel = 'Teacher';

    return Scaffold(
      appBar: _buildAppBar(context),
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
                    label: const Text('Manage My Group'),
                  ),
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Teacher Dashboard'),
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
            if (user.role == UserRole.servant) ...[
              _infoRow('Group', user.groupId ?? '--'),
              _assignedTeamRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _assignedTeamRow(BuildContext context) {
    final assignedTeamIds = user.effectiveAssignedTeamIds;
    if (assignedTeamIds.isEmpty) {
      return _infoRow('Assigned Teams', 'Not assigned');
    }

    return FutureBuilder<List<String>>(
      future: () async {
        final repo = context.read<TeamRepository>();
        final teams = await Future.wait(
          assignedTeamIds.map((teamId) => repo.getTeamById(teamId)),
        );
        final names = <String>[];
        for (var i = 0; i < teams.length; i++) {
          final name = teams[i]?.name.trim();
          if (name != null && name.isNotEmpty) {
            names.add(name);
          } else {
            names.add('Unknown team');
          }
        }
        return names;
      }(),
      builder: (context, snapshot) {
        final teamNames = switch (snapshot.connectionState) {
          ConnectionState.waiting => 'Loading...',
          _ => (snapshot.data ?? const <String>['Unknown team']).join(', '),
        };
        final label = assignedTeamIds.length > 1
            ? 'Assigned Teams'
            : 'Assigned Team';
        return _infoRow(label, teamNames);
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
