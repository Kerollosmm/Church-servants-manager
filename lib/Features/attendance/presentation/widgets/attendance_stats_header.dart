import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AttendanceStatsHeader extends StatelessWidget {
  const AttendanceStatsHeader({
    super.key,
    required this.teamName,
    required this.totalSessions,
    required this.activeSessions,
  });

  final String teamName;
  final int totalSessions;
  final int activeSessions;

  @override
  Widget build(BuildContext context) {
    final closedSessions = totalSessions - activeSessions;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              teamName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              'ملخص جلسات الحضور الحالية',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _AttendanceStatChip(
                  label: 'إجمالي الجلسات',
                  value: '$totalSessions',
                ),
                _AttendanceStatChip(
                  label: 'جلسات مفتوحة',
                  value: '$activeSessions',
                ),
                _AttendanceStatChip(
                  label: 'جلسات مغلقة',
                  value: '$closedSessions',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceStatChip extends StatelessWidget {
  const _AttendanceStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapXs,
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
