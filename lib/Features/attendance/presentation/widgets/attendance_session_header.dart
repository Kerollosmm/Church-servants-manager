import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:flutter/material.dart';

class AttendanceSessionHeader extends StatelessWidget {
  const AttendanceSessionHeader({super.key, required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    final timeText = TimeOfDay.fromDateTime(session.startsAt).format(context);
    final endText = TimeOfDay.fromDateTime(session.endsAt).format(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title?.trim().isNotEmpty == true
                  ? session.title!
                  : 'جلسة حضور',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              session.teamNameSnapshot?.trim().isNotEmpty == true
                  ? session.teamNameSnapshot!
                  : session.teamId,
            ),
            const SizedBox(height: 4),
            Text('$timeText - $endText'),
          ],
        ),
      ),
    );
  }
}
