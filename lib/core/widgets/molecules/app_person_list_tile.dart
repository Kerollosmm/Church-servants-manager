import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/atoms/app_avatar.dart';
import 'package:flutter/material.dart';

/// Shows a person row with avatar, text content, and optional trailing action.
class AppPersonListTile extends StatelessWidget {
  /// Creates an [AppPersonListTile].
  const AppPersonListTile({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.trailing,
    this.onTap,
  });

  /// Primary person name.
  final String name;

  /// Optional supporting text.
  final String? subtitle;

  /// Optional avatar image URL.
  final String? imageUrl;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Tap callback for the row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacingM),
        child: Row(
          children: [
            AppAvatar(name: name, imageUrl: imageUrl),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    AppSpacing.gapXs,
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[AppSpacing.gapSm, trailing!],
          ],
        ),
      ),
    );
  }
}
