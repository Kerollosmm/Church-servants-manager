import 'dart:ui';

import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/ochre_theme_extension.dart';
import 'package:flutter/material.dart';

/// Paints soft ambient ochre blobs behind screen content.
class AppGradientDecoration extends StatelessWidget {
  /// Creates an [AppGradientDecoration].
  const AppGradientDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    final ochreTheme =
        Theme.of(context).extension<OchreTheme>() ?? OchreTheme.light;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _DecorativeBlob(
            alignment: Alignment.topRight,
            colors: <Color>[
              AppColors.primary.withValues(alpha: ochreTheme.blobOpacity),
              AppColors.primary.withValues(alpha: 0.02),
            ],
            offset: const Offset(120, -120),
          ),
          _DecorativeBlob(
            alignment: Alignment.bottomLeft,
            colors: <Color>[
              AppColors.primary.withValues(alpha: ochreTheme.blobOpacity * 0.8),
              AppColors.primaryContainer,
            ],
            offset: const Offset(-100, 140),
          ),
        ],
      ),
    );
  }
}

class _DecorativeBlob extends StatelessWidget {
  const _DecorativeBlob({
    required this.alignment,
    required this.colors,
    required this.offset,
  });

  final Alignment alignment;
  final List<Color> colors;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(160),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(160),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.24),
                    blurRadius: 100,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
