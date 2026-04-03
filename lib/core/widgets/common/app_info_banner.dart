import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.backgroundColor = AppColors.surfaceContainer,
    this.foregroundColor = AppColors.textSecondary,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foregroundColor),
            ),
          ),
        ],
      ),
    );

    if (margin == null) {
      return child;
    }

    return Padding(padding: margin!, child: child);
  }
}
