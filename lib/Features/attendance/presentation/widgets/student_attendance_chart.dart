import 'package:flutter/material.dart';

class StudentAttendanceChart extends StatelessWidget {
  const StudentAttendanceChart({
    super.key,
    required this.percentage,
    required this.attended,
    required this.total,
  });

  final double percentage;
  final int attended;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (percentage / 100).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نسبة الحضور', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}% • $attended من $total جلسة',
            ),
          ],
        ),
      ),
    );
  }
}
