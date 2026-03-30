import 'package:flutter/material.dart';

class SessionExpiryBanner extends StatelessWidget {
  const SessionExpiryBanner({
    super.key,
    required this.isSessionOpen,
    required this.isClosed,
  });

  final bool isSessionOpen;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final color = isClosed
        ? Colors.red.shade100
        : isSessionOpen
        ? Colors.green.shade100
        : Colors.orange.shade100;
    final text = isClosed
        ? 'تم إغلاق هذه الجلسة.'
        : isSessionOpen
        ? 'الجلسة مفتوحة لتسجيل الحضور الآن.'
        : 'انتهى وقت الجلسة ولم تعد تقبل تعديلات.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}
