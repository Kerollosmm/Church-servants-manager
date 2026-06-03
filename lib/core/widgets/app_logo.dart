import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_elkarooz.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.church, size: size, color: Theme.of(context).primaryColor),
    );
  }
}
