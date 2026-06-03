import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SanctuaryBackground extends StatelessWidget {
  final Widget child;

  const SanctuaryBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Background
        const Positioned.fill(child: ColoredBox(color: AppColors.background)),

        // Simulated Blur Blobs (using RadialGradient for 60fps performance)
        Positioned(
          top: -150,
          left: -150,
          child: _BlurBlob(
            color: AppColors.primary.withValues(alpha: 0.15),
            size: 400,
          ),
        ),
        Positioned(
          bottom: -150,
          right: -150,
          child: _BlurBlob(
            color: AppColors.primary.withValues(alpha: 0.15),
            size: 400,
          ),
        ),

        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}
