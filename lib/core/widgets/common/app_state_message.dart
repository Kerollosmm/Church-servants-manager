import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppStateMessage extends StatelessWidget {
  const AppStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: iconColor ?? AppColors.outline,
            ),
            AppSpacing.gapMd,
            Text(title, style: theme.textTheme.titleMedium),
            AppSpacing.gapSm,
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapMd,
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
