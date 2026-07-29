import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared layout component for presenting empty states, error states, and status cards.
class AppStateCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String description;
  final List<Widget> actions;

  const AppStateCard({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.description,
    this.actions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor ?? AppColors.outline),
            AppSpacing.gapMd,
            Text(title, style: theme.textTheme.titleMedium),
            AppSpacing.gapSm,
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actions.isNotEmpty) ...[
              AppSpacing.gapMd,
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}
