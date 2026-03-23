import 'dart:async';

import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Displays a reusable empty state with an optional recovery action.
class AppEmptyState extends StatelessWidget {
  /// Creates an [AppEmptyState].
  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
    this.onRefresh,
    this.refreshLabel = 'Refresh',
    this.icon = Icons.people_outline,
  });

  final String title;
  final String subtitle;
  final FutureOr<void> Function()? onAction;
  final String? actionLabel;
  final FutureOr<void> Function()? onRefresh;
  final String refreshLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionCallback = onAction ?? onRefresh;
    final resolvedActionLabel = actionLabel ?? refreshLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.primary),
            AppSpacing.gapMd,
            Text(title, style: theme.textTheme.titleMedium),
            AppSpacing.gapSm,
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionCallback != null) ...[
              AppSpacing.gapMd,
              FilledButton.icon(
                onPressed: actionCallback,
                icon: const Icon(Icons.refresh),
                label: Text(resolvedActionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
