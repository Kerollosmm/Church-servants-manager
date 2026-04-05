import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.church,
      size: size,
      color: Theme.of(context).primaryColor,
    );
  }
}
