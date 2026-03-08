import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class PersonListCard extends StatelessWidget {
  const PersonListCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.outline),
        ),
      ),
    );
  }
}
