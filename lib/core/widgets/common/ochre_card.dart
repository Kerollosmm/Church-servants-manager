import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/ochre_ambient_shadow.dart';
import 'package:flutter/material.dart';

class OchreCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const OchreCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius:
            borderRadius ?? AppRadius.lgRadius, // 16px for Sanctuary feel
        border:
            border ??
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: OchreAmbientShadow.level1,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppRadius.lgRadius,
        child: card,
      );
    }

    return card;
  }
}
