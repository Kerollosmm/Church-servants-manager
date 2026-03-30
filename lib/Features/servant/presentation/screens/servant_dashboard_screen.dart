import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDashboardScreen extends StatelessWidget {
  const ServantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = switch (state) {
      AuthAuthenticated(:final user) => user,
      AuthDegraded(:final user) => user,
      _ => null,
    };
    final assignedCount = user?.effectiveAssignedTeamIds.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الخادم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            user == null ? 'مرحباً' : 'مرحباً ${user.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('لديك حالياً $assignedCount فريق/فرق متاحة لإدارة الحضور.'),
          const SizedBox(height: 16),
          _ServantActionCard(
            title: 'بدء جلسة حضور',
            subtitle: 'أنشئ جلسة جديدة لأحد فرقك المصرح بها.',
            icon: Icons.playlist_add_check_circle_outlined,
            onTap: () =>
                Navigator.of(context).pushNamed(attendanceSessionCreate),
          ),
          const SizedBox(height: 12),
          _ServantActionCard(
            title: 'متابعة الجلسات',
            subtitle: 'راجع الجلسات الحالية والسابقـة وافتح الجلسة النشطة.',
            icon: Icons.fact_check_outlined,
            onTap: () => Navigator.of(context).pushNamed(attendanceHistory),
          ),
        ],
      ),
    );
  }
}

class _ServantActionCard extends StatelessWidget {
  const _ServantActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
