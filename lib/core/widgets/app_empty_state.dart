import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/app_state_card.dart';
import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<void> Function()? onRefresh;
  final String refreshLabel;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData icon;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.refreshLabel = 'تحديث',
    this.onAction,
    this.actionLabel,
    this.icon = Icons.people_outline,
  });

  @override
  Widget build(BuildContext context) {
    return AppStateCard(
      icon: icon,
      iconColor: AppColors.outline,
      title: title,
      description: subtitle,
      actions: [
        if (onAction != null && actionLabel != null)
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel!),
          ),
        if (onRefresh != null)
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(refreshLabel),
          ),
      ],
    );
  }
}
