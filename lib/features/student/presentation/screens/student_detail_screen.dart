import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentDetailScreen extends StatelessWidget {
  final StudentDetailArgs args;

  const StudentDetailScreen({super.key, required this.args});

  bool _canEdit() {
    final actor = args.actor;
    final student = args.student;

    if (actor.role == UserRole.admin) return true;
    if (actor.role == UserRole.servant) {
      return actor.groupId != null && student.classId == actor.groupId;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final student = args.student;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                  AppRouter.studentEdit,
                  arguments: StudentEditArgs(actor: args.actor, student: student),
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
                  optionBuilder: () => {
                    'Cancel': false,
                    'Delete': true,
                  },
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
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(studentName: student.name, group: student.group, grade: student.grade),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Identity',
            children: [
              _InfoRow(label: 'Full Name', value: student.name),
              _InfoRow(label: 'Group', value: student.group.name),
              _InfoRow(label: 'Class ID', value: _optional(student.classId)),
              _InfoRow(label: 'Grade', value: student.grade.toString()),
              _InfoRow(label: 'Education Stage', value: student.educationStage.name),
            ],
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Contact',
            children: [
              _InfoRow(label: 'Mobile', value: student.mobile),
              _InfoRow(label: 'Mother Phone', value: student.motherPhone),
              _InfoRow(label: 'Father Phone', value: student.fatherPhone),
            ],
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'School',
            children: [
              _InfoRow(label: 'School/College', value: _optional(student.school)),
              _InfoRow(label: 'Address', value: _optional(student.address)),
            ],
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: 'Other',
            children: [
              _InfoRow(label: 'Birthdate', value: _formatDate(student.birthdate)),
              _InfoRow(label: 'Father of Confession', value: student.fatherOfConfession),
              _InfoRow(label: 'Notes', value: _optional(student.notes)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canEdit ? 'Manage access: ${_roleLabel(args.actor.role)}' : 'Read-only view',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Group ${group.name} • Grade $grade',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

