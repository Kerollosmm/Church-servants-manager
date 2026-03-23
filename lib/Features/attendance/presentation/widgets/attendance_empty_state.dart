import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

class AttendanceEmptyState extends StatelessWidget {
  const AttendanceEmptyState({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'لا توجد جلسات حضور',
      subtitle: 'أنشئ جلسة جديدة لبدء تسجيل الحضور لهذا الفريق.',
      onRefresh: onRefresh,
    );
  }
}
