import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_detail_section_card.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/core/widgets/common/app_profile_header_card.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentDetailArgs args;

  const StudentDetailScreen({super.key, required this.args});

  bool _canEdit() => const CanMutateStudentUseCase()(args.actor, args.student);

  @override
  Widget build(BuildContext context) {
    final student = args.student;
    final canEdit = _canEdit();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  studentEdit,
                  arguments: StudentEditArgs(
                    actor: args.actor,
                    student: student,
                  ),
                );
              },
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () async {
                final shouldDelete = await showGenericDialog<bool>(
                  context: context,
                  title: 'Delete Student?',
                  content:
                      'This will permanently delete ${student.name}. This cannot be undone.',
                  optionBuilder: () => {'Cancel': false, 'Delete': true},
                );

                if (shouldDelete != true) return;
                if (!context.mounted) return;

                context.read<StudentDataBloc>().add(
                  StudentDeleted(actor: args.actor, docId: student.docID),
                );
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _HeaderCard(
            studentName: student.name,
            group: student.group,
            grade: student.grade,
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'Identity',
            children: [
              _InfoRow(label: 'Full Name', value: student.name),
              _InfoRow(label: 'Group', value: student.group.name),
              _InfoRow(label: 'Class ID', value: _optional(student.classId)),
              _InfoRow(label: 'Grade', value: student.grade.toString()),
              _InfoRow(
                label: 'Education Stage',
                value: student.educationStage.name,
              ),
            ],
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'Contact',
            children: [
              _InfoRow(label: 'Mobile', value: student.mobile),
              _InfoRow(label: 'Mother Phone', value: student.motherPhone),
              _InfoRow(label: 'Father Phone', value: student.fatherPhone),
            ],
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'School',
            children: [
              _InfoRow(
                label: 'School/College',
                value: _optional(student.school),
              ),
              _InfoRow(label: 'Address', value: _optional(student.address)),
            ],
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'Other',
            children: [
              _InfoRow(
                label: 'Birthdate',
                value: _formatDate(student.birthdate),
              ),
              _InfoRow(
                label: 'Father of Confession',
                value: student.fatherOfConfession,
              ),
              _InfoRow(label: 'Notes', value: _optional(student.notes)),
            ],
          ),
          AppSpacing.gapMd,
          AppInfoBanner(
            icon: Icons.cloud_done,
            message: canEdit
                ? 'Manage access: ${_roleLabel(args.actor.role)}'
                : 'Read-only view',
          ),
        ],
      ),
    );
  }

  static String _optional(String? value) =>
      value == null || value.isEmpty ? '--' : value;

  static String _formatDate(DateTime? date) {
    if (date == null) return '--';
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _roleLabel(UserRole role) {
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

class _HeaderCard extends StatelessWidget {
  final String studentName;
  final Group group;
  final int grade;

  const _HeaderCard({
    required this.studentName,
    required this.group,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    return AppProfileHeaderCard(
      title: studentName,
      subtitle: 'Group ${group.name} • Grade $grade',
      avatarText: studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppDetailSectionCard(title: title, children: children);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppKeyValueRow(label: label, value: value, labelWidth: 140);
  }
}
