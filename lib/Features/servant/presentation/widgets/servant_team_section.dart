import 'package:church_management_system/core/widgets/common/app_detail_section_card.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:flutter/material.dart';

class ServantTeamSection extends StatelessWidget {
  const ServantTeamSection({super.key, required this.servant});

  final ServantModel servant;

  @override
  Widget build(BuildContext context) {
    return AppDetailSectionCard(
      title: 'البيانات الأساسية',
      children: [
        AppKeyValueRow(label: 'الاسم', value: servant.name, labelWidth: 140),
        AppKeyValueRow(
          label: 'المجموعة',
          value: _optional(servant.teamName),
          labelWidth: 140,
        ),
        AppKeyValueRow(
          label: 'الدور',
          value: servant.role.name,
          labelWidth: 140,
        ),
      ],
    );
  }

  static String _optional(String? value) =>
      value == null || value.isEmpty ? '--' : value;
}
