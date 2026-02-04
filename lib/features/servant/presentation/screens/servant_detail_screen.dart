import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDetailScreen extends StatelessWidget {
  final ServantDetailArgs args;

  const ServantDetailScreen({super.key, required this.args});

  bool _canEdit() {
    final actor = args.actor;
    return actor.role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final servant = args.servant;
    final theme = Theme.of(context);
    final canEdit = _canEdit();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الخادم'), // Servant Details
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'تعديل', // Edit
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  servantEdit,
                  arguments: ServantEditArgs(
                    actor: args.actor,
                    servant: servant,
                  ),
                );
              },
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'حذف', // Delete
              onPressed: () async {
                final shouldDelete = await showGenericDialog<bool>(
                  context: context,
                  title: 'حذف الخادم؟', // Delete Servant?
                  content:
                      'سيتم حذف ${servant.name} نهائياً. لا يمكن التراجع عن هذا الإجراء.', // Permanent delete warning
                  optionBuilder: () => {
                    'إلغاء': false, // Cancel
                    'حذف': true, // Delete
                  },
                );

                if (shouldDelete != true) return;
                if (!context.mounted) return;

                context.read<ServantDataBloc>().add(
                  ServantDeleted(actor: args.actor, docId: servant.docID),
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
            servantName: servant.name,
            teamName: servant.teamName ?? '--',
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'البيانات الأساسية', // Basic Info
            children: [
              _InfoRow(label: 'الاسم', value: servant.name), // Name
              _InfoRow(
                label: 'المجموعة',
                value: _optional(servant.teamName),
              ), // Team
              _InfoRow(label: 'الدور', value: servant.role.name), // Role
            ],
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'بيانات التواصل', // Contact
            children: [
              _InfoRow(
                label: 'رقم الهاتف',
                value: _optional(servant.phone),
              ), // Phone
              _InfoRow(
                label: 'البريد الإلكتروني',
                value: _optional(servant.email),
              ), // Email
            ],
          ),
          AppSpacing.gapMd,
          _InfoSection(
            title: 'بيانات أخرى', // Other
            children: [
              _InfoRow(
                label: 'تاريخ الميلاد',
                value: _formatDate(servant.birthdate),
              ), // Birthdate
              _InfoRow(
                label: 'أب الاعتراف',
                value: _optional(servant.fatherOfConfession),
              ), // Father of Confession
              _InfoRow(
                label: 'ملاحظات',
                value: _optional(servant.notes),
              ), // Notes
            ],
          ),
          AppSpacing.gapMd,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: AppColors.primary),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    canEdit
                        ? 'صلاحية المسؤول: تعديل/حذف'
                        : 'عرض فقط', // Admin access / Read-only
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
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
}

class _HeaderCard extends StatelessWidget {
  final String servantName;
  final String teamName;

  const _HeaderCard({required this.servantName, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                servantName.isNotEmpty ? servantName[0].toUpperCase() : '?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    servantName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    'المجموعة: $teamName', // Team
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapMd,
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
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
