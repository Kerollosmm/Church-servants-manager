import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppKeyValueRow extends StatelessWidget {
  const AppKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth,
    this.dense = false,
    this.valueTextAlign = TextAlign.start,
  });

  final String label;
  final String value;
  final double? labelWidth;
  final bool dense;
  final TextAlign valueTextAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowPadding = dense ? 4.0 : 6.0;

    Widget labelWidget = Text(
      label,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    );

    if (labelWidth != null) {
      labelWidget = SizedBox(width: labelWidth, child: labelWidget);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelWidget,
          if (labelWidth != null) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: valueTextAlign,
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
