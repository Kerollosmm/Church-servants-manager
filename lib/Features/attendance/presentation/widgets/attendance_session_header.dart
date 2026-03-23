import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:flutter/material.dart';

class AttendanceSessionHeader extends StatelessWidget {
  const AttendanceSessionHeader({super.key, required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.teamNameSnapshot ?? 'الفريق',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.gapXs,
            Text('البداية: ${_formatDateTime(session.startsAt)}'),
            Text('النهاية: ${_formatDateTime(session.endsAt)}'),
            Text('المدة: ${session.durationMinutes} دقيقة'),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
