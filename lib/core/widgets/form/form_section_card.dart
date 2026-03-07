import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class FormSectionCard extends StatelessWidget {
  const FormSectionCard({
    super.key,
    required this.title,
    required this.titleStyle,
    required this.children,
  });

  final String title;
  final TextStyle? titleStyle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            AppSpacing.gapMd,
            ...children,
          ],
        ),
      ),
    );
  }
}
