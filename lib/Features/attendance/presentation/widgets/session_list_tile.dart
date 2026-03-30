import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:flutter/material.dart';

class SessionListTile extends StatelessWidget {
  const SessionListTile({super.key, required this.session, this.onTap});

  final AttendanceSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final timeText = TimeOfDay.fromDateTime(session.startsAt).format(context);
    return Card(
      child: ListTile(
        leading: Icon(
          session.isClosed ? Icons.lock_clock : Icons.event_available,
        ),
        title: Text(
          session.title?.trim().isNotEmpty == true
              ? session.title!
              : 'جلسة ${session.dateKey}',
        ),
        subtitle: Text(
          '$timeText • ${session.teamNameSnapshot ?? session.teamId}',
        ),
        trailing: session.isClosed
            ? const Chip(label: Text('مغلقة'))
            : const Chip(label: Text('نشطة')),
        onTap: onTap,
      ),
    );
  }
}
