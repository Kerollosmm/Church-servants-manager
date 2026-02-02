import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        children: [
          _buildDashboardItem(
            context,
            title: 'My Profile',
            icon: Icons.person,
            onTap: () {},
          ),
          _buildDashboardItem(
            context,
            title: 'My Lessons',
            icon: Icons.book,
            onTap: () {},
          ),
          _buildDashboardItem(
            context,
            title: 'Attendance',
            icon: Icons.calendar_today,
            onTap: () {},
          ),
          _buildDashboardItem(
            context,
            title: 'Assignments',
            icon: Icons.assignment,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
