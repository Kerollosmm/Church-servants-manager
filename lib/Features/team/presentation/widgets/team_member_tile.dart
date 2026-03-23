import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:flutter/material.dart';

class TeamMemberTile extends StatelessWidget {
  const TeamMemberTile({
    super.key,
    required this.student,
    required this.isChecked,
    required this.isEnabled,
    required this.onChanged,
  });

  final StudentModel student;
  final bool isChecked;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isChecked,
      onChanged: isEnabled ? (value) => onChanged(value ?? false) : null,
      title: Text(student.name),
      subtitle: Text('الصف ${student.grade}'),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
