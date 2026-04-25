import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<void> Function()? onRefresh;
  final String refreshLabel;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData icon;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.refreshLabel = 'تحديث',
    this.onAction,
    this.actionLabel,
    this.icon = Icons.people_outline,
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
            Icon(icon, size: 64, color: AppColors.outline),
            AppSpacing.gapMd,
            Text(title, style: theme.textTheme.titleMedium),
            AppSpacing.gapSm,
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              AppSpacing.gapMd,
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
            if (onRefresh != null) ...[
              AppSpacing.gapMd,
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(refreshLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
