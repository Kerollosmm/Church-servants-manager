import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
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
    final colorScheme = theme.colorScheme;
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
                  Icon(Icons.church, size: 80, color: colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome $roleLabel',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _UserStatsCard(user: user),
                  const SizedBox(height: 24),
                  // Manage Students button for admins and teachers
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.studentList);
                    },
                    icon: const Icon(Icons.people),
                    label: Text(isAdmin ? 'Manage Students' : 'Manage My Group'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRouter.devTools);
                      },
                      icon: const Icon(Icons.build_outlined),
                      label: const Text('Dev Tools'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Pull down to refresh your role',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      title: Text(isAdmin ? 'Admin Dashboard' : 'Teacher Dashboard'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
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
    final roleLabel = user.role == UserRole.servant ? 'TEACHER' : user.role.name.toUpperCase();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
