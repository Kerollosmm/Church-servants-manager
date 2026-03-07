import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthEventSignOut());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            _tile(
              context,
              icon: Icons.people_alt_outlined,
              title: 'Students',
              subtitle: 'Manage students (admin view)',
              route: studentList,
            ),
            AppSpacing.gapSm,
            _tile(
              context,
              icon: Icons.group_work_outlined,
              title: 'Teams',
              subtitle: 'Create / edit teams',
              route: teamManagement,
            ),
            AppSpacing.gapSm,
            _tile(
              context,
              icon: Icons.supervisor_account_outlined,
              title: 'Servants',
              subtitle: 'Create / edit servants',
              route: servantList,
            ),
            if (kDebugMode) ...[
              AppSpacing.gapSm,
              _tile(
                context,
                icon: Icons.build_outlined,
                title: 'Dev Tools',
                subtitle: 'Debug utilities',
                route: devTools,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
