import 'package:flutter/material.dart';

/// Renders the primary church logo asset.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 180,
    this.enableHero = false,
    this.heroTag = 'app_logo',
  });

  final double size;
  final bool enableHero;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo_elkarooz.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!enableHero) {
      return image;
    }

    return Hero(tag: heroTag, child: image);
  }
}
