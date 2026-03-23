import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:flutter/material.dart';

class StudentAttendanceChart extends StatelessWidget {
  const StudentAttendanceChart({super.key, required this.stats});

  final StudentAttendanceStats stats;

  @override
  Widget build(BuildContext context) {
    final percentage = (stats.attendancePercentage / 100).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصاءات الجلسات المكتملة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapMd,
            LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            AppSpacing.gapSm,
            Text(
              'نسبة الحضور ${stats.attendancePercentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _StatTile(
                  label: 'نسبة الحضور',
                  value: '${stats.attendancePercentage.toStringAsFixed(1)}%',
                ),
                _StatTile(label: 'حاضر', value: '${stats.presentCount}'),
                _StatTile(label: 'متأخر', value: '${stats.lateCount}'),
                _StatTile(label: 'غائب', value: '${stats.absentCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapXs,
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
