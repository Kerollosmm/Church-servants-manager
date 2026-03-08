import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppProfileHeaderCard extends StatelessWidget {
  const AppProfileHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarText,
    this.icon,
  }) : assert(avatarText != null || icon != null);

  final String title;
  final String subtitle;
  final String? avatarText;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: icon != null
                  ? Icon(icon, color: AppColors.primary, size: 28)
                  : Text(
                      avatarText!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
