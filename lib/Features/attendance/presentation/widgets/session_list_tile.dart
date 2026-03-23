import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:flutter/material.dart';

class SessionListTile extends StatelessWidget {
  const SessionListTile({
    super.key,
    required this.session,
    required this.onTap,
    required this.teamName,
    this.isActive = false,
    this.canClose = false,
    this.onClose,
  });

  final AttendanceSession session;
  final VoidCallback onTap;
  final String teamName;
  final bool isActive;
  final bool canClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Card(
        color: const Color(0xFFF4FBF2),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.secondary),
                  AppSpacing.gapSm,
                  Expanded(
                    child: Text(
                      session.title?.isNotEmpty == true
                          ? session.title!
                          : 'جلسة مفتوحة - $teamName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Chip(label: Text('مفتوحة')),
                ],
              ),
              AppSpacing.gapSm,
              Text(
                '${_formatDateTime(session.startsAt)} - ${_formatTime(session.endsAt)}',
              ),
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('فتح الجلسة'),
                    ),
                  ),
                  if (canClose && onClose != null) ...[
                    AppSpacing.gapSm,
                    OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('إغلاق'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF3F4F6),
          child: const Icon(Icons.history, color: AppColors.primary),
        ),
        title: Text(
          session.title?.isNotEmpty == true ? session.title! : 'جلسة حضور',
        ),
        subtitle: Text(
          '${_formatDateTime(session.startsAt)} - ${_formatTime(session.endsAt)}',
        ),
        trailing: Chip(label: Text(session.isClosed ? 'مغلقة' : 'مفتوحة')),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day ${_formatTime(value)}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
