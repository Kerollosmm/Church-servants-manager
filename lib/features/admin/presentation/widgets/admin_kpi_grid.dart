import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:church_management_system/features/admin/presentation/widgets/kpi_card.dart';
import 'package:flutter/material.dart';

class AdminKpiGrid extends StatelessWidget {
  final DashboardKpiData kpiData;

  const AdminKpiGrid({super.key, required this.kpiData});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        delegate: SliverChildListDelegate([
          KpiCard(
            icon: Icons.groups_outlined,
            title: 'إجمالي الطلاب',
            value: kpiData.totalStudents.toString(),
            trend: '5%+',
          ),
          KpiCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'الخدام',
            value: kpiData.totalServants.toString(),
            trend: '2%+',
          ),
          KpiCard(
            icon: Icons.diversity_3_outlined,
            title: 'الفرق',
            value: kpiData.totalTeams.toString(),
            trend: '0%',
            trendType: TrendType.neutral,
          ),
          KpiCard(
            icon: Icons.fact_check_outlined,
            title: 'معدل الحضور',
            value: '${kpiData.attendanceRate.toInt()}%',
            trend: '8%+',
          ),
        ]),
      ),
    );
  }
}
