import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:flutter/material.dart';

class StudentListTile extends StatelessWidget {
  const StudentListTile({
    super.key,
    required this.student,
    required this.onTap,
  });

  final StudentModel student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          child: Text(student.name.isNotEmpty ? student.name[0] : '?'),
        ),
        title: Text(student.name),
        subtitle: Text(
          student.isArchived
              ? 'مؤرشف'
              : 'المجموعة ${student.group.name} • الصف ${student.grade}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
