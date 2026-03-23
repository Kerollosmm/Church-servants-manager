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
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          child: Builder(
            builder: (context) {
              final trimmed = name.trim();
              return Text(trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?');
            },
          ),
        ),
        title: Text(name),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
