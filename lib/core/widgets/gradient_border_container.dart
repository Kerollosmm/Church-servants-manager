import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A container with a gradient border effect (gold → brown).
///
/// Wraps [child] in a gradient-bordered container using the app's
/// primary gradient colors. Uses intrinsic sizing by default.
class GradientBorderContainer extends StatelessWidget {
  const GradientBorderContainer({
    super.key,
    required this.child,
    this.borderWidth = 3.0,
    this.borderRadius = AppRadius.lg,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: child,
      ),
    );
  }
}
