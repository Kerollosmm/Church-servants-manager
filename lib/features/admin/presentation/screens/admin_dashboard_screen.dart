import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/cards/app_navigation_tile_card.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المسؤول'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
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
            _AdminNavigationTile(
              icon: Icons.people_alt_outlined,
              title: 'المخدومون',
              subtitle: 'إدارة بيانات المخدومين',
              route: studentList,
            ),
            AppSpacing.gapSm,
            _AdminNavigationTile(
              icon: Icons.group_work_outlined,
              title: 'الفرق',
              subtitle: 'إنشاء الفرق وتعديلها',
              route: teamManagement,
            ),
            AppSpacing.gapSm,
            _AdminNavigationTile(
              icon: Icons.fact_check_outlined,
              title: 'الحضور',
              subtitle: 'إدارة الجلسات ومتابعة الحضور',
              route: attendanceHistory,
            ),
            AppSpacing.gapSm,
            _AdminNavigationTile(
              icon: Icons.supervisor_account_outlined,
              title: 'الخدام',
              subtitle: 'إدارة بيانات الخدام',
              route: servantList,
            ),
            if (kDebugMode) ...[
              AppSpacing.gapSm,
              _AdminNavigationTile(
                icon: Icons.build_outlined,
                title: 'أدوات التطوير',
                subtitle: 'أدوات التشخيص والاختبار',
                route: devTools,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminNavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _AdminNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return AppNavigationTileCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
