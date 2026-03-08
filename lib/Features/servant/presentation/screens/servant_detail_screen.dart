import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_detail_section_card.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/core/widgets/common/app_profile_header_card.dart';
import 'package:flutter/material.dart';

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
          AppInfoBanner(
            icon: Icons.cloud_done,
            message: canEdit ? 'صلاحية المسؤول: تعديل' : 'عرض فقط',
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
    return AppProfileHeaderCard(
      title: servantName,
      subtitle: 'المجموعة: $teamName',
      avatarText: servantName.isNotEmpty ? servantName[0].toUpperCase() : '?',
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
