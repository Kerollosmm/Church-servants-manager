import 'package:church_management_system/core/widgets/common/app_detail_section_card.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:flutter/material.dart';

class ServantInfoSection extends StatelessWidget {
  const ServantInfoSection({
    super.key,
    required this.title,
    required this.rows,
  });

  final String title;
  final List<ServantInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return AppDetailSectionCard(
      title: title,
      children: rows
          .map(
            (row) => AppKeyValueRow(
              label: row.label,
              value: row.value,
              labelWidth: 140,
            ),
          )
          .toList(growable: false),
    );
  }
}

class ServantInfoRowData {
  const ServantInfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}
