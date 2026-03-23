import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_detail_section_card.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:flutter/material.dart';

class StudentBioSection extends StatelessWidget {
  const StudentBioSection({
    super.key,
    required this.student,
    this.showIdentitySection = true,
  });

  final StudentModel student;
  final bool showIdentitySection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showIdentitySection) ...[
          AppDetailSectionCard(
            title: 'Identity',
            children: [
              AppKeyValueRow(
                label: 'Full Name',
                value: student.name,
                labelWidth: 140,
              ),
              AppKeyValueRow(
                label: 'Group',
                value: student.group.name,
                labelWidth: 140,
              ),
              AppKeyValueRow(
                label: 'Class ID',
                value: _optional(student.classId),
                labelWidth: 140,
              ),
              AppKeyValueRow(
                label: 'Grade',
                value: student.grade.toString(),
                labelWidth: 140,
              ),
              AppKeyValueRow(
                label: 'Education Stage',
                value: student.educationStage.name,
                labelWidth: 140,
              ),
            ],
          ),
          AppSpacing.gapMd,
        ],
        AppDetailSectionCard(
          title: 'Contact',
          children: [
            AppKeyValueRow(
              label: 'Mobile',
              value: student.mobile,
              labelWidth: 140,
            ),
            AppKeyValueRow(
              label: 'Mother Phone',
              value: student.motherPhone,
              labelWidth: 140,
            ),
            AppKeyValueRow(
              label: 'Father Phone',
              value: student.fatherPhone,
              labelWidth: 140,
            ),
          ],
        ),
        AppSpacing.gapMd,
        AppDetailSectionCard(
          title: 'School',
          children: [
            AppKeyValueRow(
              label: 'School/College',
              value: _optional(student.school),
              labelWidth: 140,
            ),
            AppKeyValueRow(
              label: 'Address',
              value: _optional(student.address),
              labelWidth: 140,
            ),
          ],
        ),
        AppSpacing.gapMd,
        AppDetailSectionCard(
          title: 'Other',
          children: [
            AppKeyValueRow(
              label: 'Birthdate',
              value: _formatDate(student.birthdate),
              labelWidth: 140,
            ),
            AppKeyValueRow(
              label: 'Father of Confession',
              value: student.fatherOfConfession,
              labelWidth: 140,
            ),
            AppKeyValueRow(
              label: 'Notes',
              value: _optional(student.notes),
              labelWidth: 140,
            ),
          ],
        ),
      ],
    );
  }

  String _optional(String? value) {
    return value == null || value.isEmpty ? '--' : value;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '--';
    }
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
