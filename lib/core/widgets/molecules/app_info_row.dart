import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Displays a labeled value pair used by profile detail screens.
class AppInfoRow extends StatelessWidget {
  /// Creates an [AppInfoRow].
  const AppInfoRow({super.key, required this.label, required this.value});

  /// Descriptive row label.
  final String label;

  /// Row value text.
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacingM),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacingS),
        Divider(color: AppColors.primary.withValues(alpha: 0.10), height: 1),
      ],
    );
  }
}
