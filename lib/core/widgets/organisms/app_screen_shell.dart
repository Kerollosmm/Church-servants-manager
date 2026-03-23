import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/organisms/app_gradient_decoration.dart';
import 'package:flutter/material.dart';

/// Wraps a screen in the shared Ochre canvas and ambient decoration.
class AppScreenShell extends StatelessWidget {
  /// Creates an [AppScreenShell].
  const AppScreenShell({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.padding = const EdgeInsets.all(AppSpacing.paddingPage),
  });

  /// Optional scaffold app bar.
  final PreferredSizeWidget? appBar;

  /// Main screen body.
  final Widget body;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Inner body padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppGradientDecoration(),
          SafeArea(
            child: Padding(padding: padding, child: body),
          ),
        ],
      ),
    );
  }
}
