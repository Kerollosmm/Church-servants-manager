import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/molecules/app_section_card.dart';
import 'package:flutter/material.dart';

/// Renders a dashboard stat with icon, value, and label.
class AppStatCard extends StatelessWidget {
  /// Creates an [AppStatCard].
  const AppStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  /// Leading stat icon.
  final IconData icon;

  /// Primary numeric value.
  final String value;

  /// Supporting label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSectionCard(
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconSize, color: AppColors.primary),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.headlineSmall),
                AppSpacing.gapXs,
                Text(label, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
