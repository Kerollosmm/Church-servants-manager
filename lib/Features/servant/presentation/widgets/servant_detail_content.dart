import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/app_profile_header_card.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_info_section.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_team_section.dart';
import 'package:flutter/material.dart';

class ServantDetailContent extends StatelessWidget {
  const ServantDetailContent({
    super.key,
    required this.servant,
    required this.canEdit,
  });

  final ServantModel servant;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppProfileHeaderCard(
          title: servant.name,
          subtitle: 'المجموعة: ${servant.teamName ?? '--'}',
          avatarText: servant.name.isNotEmpty
              ? servant.name[0].toUpperCase()
              : '?',
        ),
        AppSpacing.gapMd,
        ServantTeamSection(servant: servant),
        AppSpacing.gapMd,
        ServantInfoSection(
          title: 'بيانات التواصل',
          rows: [
            ServantInfoRowData(
              label: 'رقم الهاتف',
              value: _optional(servant.phone),
            ),
            ServantInfoRowData(
              label: 'البريد الإلكتروني',
              value: _optional(servant.email),
            ),
          ],
        ),
        AppSpacing.gapMd,
        ServantInfoSection(
          title: 'بيانات أخرى',
          rows: [
            ServantInfoRowData(
              label: 'تاريخ الميلاد',
              value: _formatDate(servant.birthdate),
            ),
            ServantInfoRowData(
              label: 'أب الاعتراف',
              value: _optional(servant.fatherOfConfession),
            ),
            ServantInfoRowData(
              label: 'ملاحظات',
              value: _optional(servant.notes),
            ),
          ],
        ),
        AppSpacing.gapMd,
        AppInfoBanner(
          icon: servant.isArchived ? Icons.archive_outlined : Icons.cloud_done,
          message: servant.isArchived
              ? 'هذا الخادم مؤرشف حاليا ويحتاج إلى إعادة تعيين فريق بعد الاستعادة.'
              : canEdit
              ? 'صلاحية المسؤول: تعديل'
              : 'عرض فقط',
        ),
      ],
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
