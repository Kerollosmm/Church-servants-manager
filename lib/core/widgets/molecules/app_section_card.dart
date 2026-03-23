import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/theme/ochre_theme_extension.dart';
import 'package:flutter/material.dart';

/// Renders a rounded content card with an optional tinted header strip.
class AppSectionCard extends StatelessWidget {
  /// Creates an [AppSectionCard].
  const AppSectionCard({
    super.key,
    required this.child,
    this.headerTitle,
    this.padding = const EdgeInsets.all(AppSpacing.spacingM),
  });

  /// Optional card header title.
  final String? headerTitle;

  /// Card body content.
  final Widget child;

  /// Internal content padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ochreTheme = theme.extension<OchreTheme>() ?? OchreTheme.light;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: ochreTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerTitle?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacingM,
                vertical: AppSpacing.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusCard),
                ),
              ),
              child: Text(
                headerTitle!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
