import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:flutter/material.dart';

class ServantDashboardActions extends StatelessWidget {
  const ServantDashboardActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, studentList);
          },
          icon: const Icon(Icons.groups_2_outlined),
          label: const Text('إدارة مخدومي الفريق'),
        ),
        AppSpacing.gapSm,
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, attendanceHistory);
          },
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('تسجيل الحضور'),
        ),
        AppSpacing.gapSm,
        const AppInfoBanner(
          icon: Icons.refresh,
          message: 'اسحب لأسفل لتحديث بياناتك الحالية.',
        ),
      ],
    );
  }
}
