import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

class StudentEmptyState extends StatelessWidget {
  const StudentEmptyState({
    super.key,
    required this.showArchived,
    required this.onRefresh,
  });

  final bool showArchived;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: showArchived ? 'لا يوجد مخدومون مؤرشفون' : 'لا يوجد مخدومون',
      subtitle: showArchived
          ? 'عند أرشفة مخدوم سيظهر هنا.'
          : 'جرّب بحثا مختلفا أو حدّث القائمة.',
      onRefresh: onRefresh,
    );
  }
}
