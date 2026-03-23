import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/theme/ochre_theme_extension.dart';
import 'package:church_management_system/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';

/// Shows the branded page header used by shared screens.
class AppHeader extends StatelessWidget {
  /// Creates an [AppHeader].
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
    this.enableLogoHero = false,
    this.heroTag = 'app_logo',
  });

  /// Main header title.
  final String title;

  /// Optional supporting subtitle.
  final String? subtitle;

  /// Whether the logo should be shown beside the title.
  final bool showLogo;

  /// Whether the logo should participate in a hero transition.
  final bool enableLogoHero;

  /// Shared hero tag for the logo transition.
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ochreTheme = theme.extension<OchreTheme>() ?? OchreTheme.light;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacingM),
            decoration: BoxDecoration(
              color: ochreTheme.headerTint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Row(
              children: [
                if (showLogo) ...[
                  AppLogo(
                    size: 40,
                    enableHero: enableLogoHero,
                    heroTag: heroTag,
                  ),
                  AppSpacing.gapMd,
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headlineSmall),
                      if (subtitle?.isNotEmpty == true) ...[
                        AppSpacing.gapXs,
                        Text(subtitle!, style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSpacing.radiusCard),
              ),
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.65),
                  AppColors.primary.withValues(alpha: 0.20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
