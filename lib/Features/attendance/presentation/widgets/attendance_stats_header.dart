import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:flutter/material.dart';

class AttendanceStatsHeader extends StatelessWidget {
  const AttendanceStatsHeader({super.key, required this.roster});

  final List<AttendanceRosterItem> roster;

  @override
  Widget build(BuildContext context) {
    final present = roster
        .where(
          (item) => item.effectiveStatus == AttendanceEffectiveStatus.present,
        )
        .length;
    final late = roster
        .where((item) => item.effectiveStatus == AttendanceEffectiveStatus.late)
        .length;
    final absent = roster
        .where(
          (item) => item.effectiveStatus == AttendanceEffectiveStatus.absent,
        )
        .length;
    final unmarked = roster
        .where(
          (item) => item.effectiveStatus == AttendanceEffectiveStatus.unmarked,
        )
        .length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(label: 'حاضر', value: present, color: Colors.green),
        _StatChip(label: 'متأخر', value: late, color: Colors.orange),
        _StatChip(label: 'غائب', value: absent, color: Colors.red),
        _StatChip(label: 'غير محدد', value: unmarked, color: Colors.blueGrey),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, child: Text('$value')),
      label: Text(label),
    );
  }
}
