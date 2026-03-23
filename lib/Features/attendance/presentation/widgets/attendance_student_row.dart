import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:flutter/material.dart';

class AttendanceStudentRow extends StatelessWidget {
  const AttendanceStudentRow({
    super.key,
    required this.item,
    required this.isSessionOpen,
    required this.isMutating,
    required this.onMarkPresent,
    required this.onMarkLate,
    required this.onClear,
  });

  final AttendanceRosterItem item;
  final bool isSessionOpen;
  final bool isMutating;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkLate;
  final VoidCallback onClear;

  bool get _canEdit => isSessionOpen && !isMutating && item.canEdit;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.effectiveStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.studentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(_statusLabel(item.effectiveStatus)),
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (item.markedByName != null) ...[
              AppSpacing.gapXs,
              Text(
                'تم التسجيل بواسطة ${item.markedByName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _canEdit ? onMarkPresent : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('حاضر'),
                ),
                OutlinedButton.icon(
                  onPressed: _canEdit ? onMarkLate : null,
                  icon: const Icon(Icons.alarm_on_outlined),
                  label: const Text('متأخر'),
                ),
                if (item.isMarked)
                  TextButton.icon(
                    onPressed: _canEdit ? onClear : null,
                    icon: const Icon(Icons.clear),
                    label: const Text('مسح التحديد'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(AttendanceEffectiveStatus status) {
  switch (status) {
    case AttendanceEffectiveStatus.present:
      return AppColors.secondary;
    case AttendanceEffectiveStatus.late:
      return Colors.orange;
    case AttendanceEffectiveStatus.absent:
      return AppColors.error;
    case AttendanceEffectiveStatus.unmarked:
      return AppColors.textSecondary;
  }
}

String _statusLabel(AttendanceEffectiveStatus status) {
  switch (status) {
    case AttendanceEffectiveStatus.present:
      return 'حاضر';
    case AttendanceEffectiveStatus.late:
      return 'متأخر';
    case AttendanceEffectiveStatus.absent:
      return 'غائب';
    case AttendanceEffectiveStatus.unmarked:
      return 'غير محدد';
  }
}
