import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';

/// Reusable auth header with icon and title/subtitle
class AuthHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final bool useBrandLogo;
  final String? brandName;
  final double logoSize;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.church_rounded,
    this.useBrandLogo = false,
    this.brandName,
    this.logoSize = 150,
  });

  const AuthHeader.brand({
    super.key,
    this.brandName = 'CSMS',
    this.title,
    this.subtitle,
    this.logoSize = 150,
  }) : icon = null,
       useBrandLogo = true;

  bool get _showsTextSection => title != null && subtitle != null;

  Color get _titleColor =>
      useBrandLogo ? AppColors.tertiary : AppColors.textPrimary;

  TextStyle? _titleStyle(ThemeData theme) => theme.textTheme.headlineMedium
      ?.copyWith(fontWeight: FontWeight.bold, color: _titleColor);

  TextStyle? _subtitleStyle(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary);

  TextStyle? _brandStyle(ThemeData theme) => theme.textTheme.headlineLarge
      ?.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.bold);

  Widget _buildBrandHeader(ThemeData theme) {
    return Column(
      children: [
        // FIX [P2]: Reuse a shared brand header instead of duplicating login logo markup.
        AppLogo(size: logoSize),
        AppSpacing.gapMd,
        Text(
          brandName ?? 'CSMS',
          style: _brandStyle(theme),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIconHeader() {
    return Column(
      children: [
        // FIX [P2]: Keep the existing icon-based auth header for register and reset screens.
        Icon(icon, size: 64, color: AppColors.primary),
        AppSpacing.gapMd,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (useBrandLogo) _buildBrandHeader(theme) else _buildIconHeader(),
        if (_showsTextSection) ...[
          if (useBrandLogo) AppSpacing.gapXl,
          Text(title!, style: _titleStyle(theme), textAlign: TextAlign.center),
          AppSpacing.gapSm,
          Text(
            subtitle!,
            style: _subtitleStyle(theme),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
