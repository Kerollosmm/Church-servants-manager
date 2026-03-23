import 'package:church_management_system/core/widgets/common/app_state_message.dart';
import 'package:flutter/material.dart';

class TeamEmptyState extends StatelessWidget {
  const TeamEmptyState({super.key, required this.showArchived});

  final bool showArchived;

  @override
  Widget build(BuildContext context) {
    return AppStateMessage(
      icon: showArchived ? Icons.archive_outlined : Icons.group_work_outlined,
      title: showArchived ? 'لا توجد فرق مؤرشفة' : 'لا توجد فرق بعد',
      message: showArchived
          ? 'عند أرشفة فريق سيظهر هنا.'
          : 'اضغط + لإنشاء فريق لهذه السنة.',
    );
  }
}
