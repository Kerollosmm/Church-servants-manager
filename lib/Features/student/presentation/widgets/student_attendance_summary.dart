import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:flutter/material.dart';

class StudentAttendanceSummary extends StatelessWidget {
  const StudentAttendanceSummary({
    super.key,
    required this.student,
    required this.actorRole,
    required this.canEdit,
  });

  final StudentModel student;
  final UserRole actorRole;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return AppInfoBanner(
      icon: student.isArchived
          ? Icons.archive_outlined
          : Icons.fact_check_outlined,
      message: student.isArchived
          ? 'هذا المخدوم مؤرشف حاليا.'
          : canEdit
          ? 'Manage access: ${_roleLabel(actorRole)}'
          : 'Read-only view',
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.servant:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
    }
  }
}
