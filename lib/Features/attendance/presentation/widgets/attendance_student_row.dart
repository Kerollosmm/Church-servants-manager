import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:flutter/material.dart';

class AttendanceStudentRow extends StatelessWidget {
  const AttendanceStudentRow({
    super.key,
    required this.item,
    required this.isBusy,
    required this.onPresent,
    required this.onLate,
    required this.onClear,
    required this.onOpenHistory,
  });

  final AttendanceRosterItem item;
  final bool isBusy;
  final VoidCallback onPresent;
  final VoidCallback onLate;
  final VoidCallback onClear;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (item.effectiveStatus) {
      AttendanceEffectiveStatus.present => 'حاضر',
      AttendanceEffectiveStatus.late => 'متأخر',
      AttendanceEffectiveStatus.absent => 'غائب',
      AttendanceEffectiveStatus.unmarked => 'غير محدد',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.studentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(statusText)),
                IconButton(
                  tooltip: 'سجل الطالب',
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.insights_outlined),
                ),
              ],
            ),
            if (item.markedByName?.trim().isNotEmpty == true)
              Text('آخر تحديث بواسطة: ${item.markedByName}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: !item.canEdit || isBusy ? null : onPresent,
                  child: isBusy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حاضر'),
                ),
                OutlinedButton(
                  onPressed: !item.canEdit || isBusy ? null : onLate,
                  child: const Text('متأخر'),
                ),
                TextButton(
                  onPressed: !item.canEdit || isBusy || !item.isMarked
                      ? null
                      : onClear,
                  child: const Text('مسح العلامة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
