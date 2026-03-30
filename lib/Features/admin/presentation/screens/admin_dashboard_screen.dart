import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = switch (state) {
      AuthAuthenticated(:final user) => user,
      AuthDegraded(:final user) => user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإدارة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            user == null ? 'مرحباً' : 'مرحباً ${user.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('ابدأ من هنا لإدارة جلسات الحضور ومراجعة السجلات بسرعة.'),
          const SizedBox(height: 16),
          // FIX [014-US4]: surface bounded reporting and audit review directly on the admin dashboard.
          BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
            builder: (context, dashboardState) {
              return Column(
                children: [
                  _DashboardSummarySection(state: dashboardState),
                  const SizedBox(height: 12),
                  _DashboardAuditSection(state: dashboardState),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          _DashboardActionCard(
            title: 'إنشاء جلسة حضور',
            subtitle: 'ابدأ جلسة جديدة لأي فريق متاح لك.',
            icon: Icons.add_task_outlined,
            onTap: () =>
                Navigator.of(context).pushNamed(attendanceSessionCreate),
          ),
          const SizedBox(height: 12),
          _DashboardActionCard(
            title: 'سجل الحضور',
            subtitle: 'راجع الجلسات الحالية والسابقة وافتح الجلسة النشطة.',
            icon: Icons.history_outlined,
            onTap: () => Navigator.of(context).pushNamed(attendanceHistory),
          ),
          const SizedBox(height: 12),
          _DashboardActionCard(
            title: 'إدارة الفرق',
            subtitle: 'انتقل إلى إدارة الفرق والأعضاء المرتبطين بها.',
            icon: Icons.groups_outlined,
            onTap: () => Navigator.of(context).pushNamed(teamManagement),
          ),
        ],
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
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

class _DashboardSummarySection extends StatelessWidget {
  const _DashboardSummarySection({required this.state});

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تقارير سريعة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricCard(
              label: 'المخدومون',
              value: state.totalStudents.toString(),
            ),
            _MetricCard(label: 'الخدام', value: state.totalServants.toString()),
            _MetricCard(
              label: 'جلسات هذا الشهر',
              value: state.sessionsThisMonth.toString(),
            ),
          ],
        ),
        if (state.recentSessions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('أحدث الجلسات', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...state.recentSessions.map(
            (session) => Card(
              child: ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: Text(session.title ?? session.dateKey),
                subtitle: Text(session.teamNameSnapshot ?? session.teamId),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DashboardAuditSection extends StatelessWidget {
  const _DashboardAuditSection({required this.state});

  final AdminDashboardState state;

  String _eventLabel(String eventType) {
    switch (eventType) {
      case 'session.created':
        return 'إنشاء جلسة';
      case 'session.closed':
        return 'إغلاق جلسة';
      case 'mark.created':
        return 'تسجيل حضور';
      case 'mark.updated':
        return 'تعديل حضور';
      case 'mark.cleared':
        return 'مسح علامة';
      case 'mark.bulk_present':
        return 'تحديد جماعي';
      default:
        return eventType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مراجعة النشاط', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.recentAuditEntries.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('لا توجد أحداث مراجعة حديثة'),
            ),
          )
        else
          ...state.recentAuditEntries.map(
            (entry) => Card(
              child: ListTile(
                leading: const Icon(Icons.history_toggle_off_outlined),
                title: Text(_eventLabel(entry.eventType)),
                subtitle: Text(
                  '${entry.actorName} • ${entry.teamId}${entry.targetStudentId == null ? '' : ' • ${entry.targetStudentId}'}',
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'حسابات تحتاج متابعة',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (state.pendingRestoreAccounts.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.mark_email_read_outlined),
              title: Text('لا توجد حسابات تحتاج متابعة حالياً'),
            ),
          )
        else
          ...state.pendingRestoreAccounts.map(
            (account) => Card(
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(account.name),
                subtitle: Text(account.email),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
