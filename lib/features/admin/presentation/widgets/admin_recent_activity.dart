import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:church_management_system/features/admin/presentation/widgets/activity_list_item.dart';
import 'package:flutter/material.dart';

class AdminRecentActivity extends StatelessWidget {
  final List<ActivityLog> activities;

  const AdminRecentActivity({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'النشاط الأخير',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ...activities.map(
            (activity) => ActivityListItem(
              icon: _getIconForType(activity.type),
              iconColor: _getIconColorForType(activity.type),
              iconBackgroundColor: _getIconBackgroundColorForType(
                activity.type,
              ),
              title: activity.title,
              subtitle: activity.subtitle,
              time: activity.time,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'person':
        return Icons.person_outlined;
      case 'event':
        return Icons.event_outlined;
      case 'assignment':
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'person':
        return Colors.blue.shade600;
      case 'event':
        return Colors.amber.shade600;
      case 'assignment':
        return Colors.green.shade600;
      default:
        return AppColors.primary;
    }
  }

  Color _getIconBackgroundColorForType(String type) {
    switch (type) {
      case 'person':
        return Colors.blue.shade100;
      case 'event':
        return Colors.amber.shade100;
      case 'assignment':
        return Colors.green.shade100;
      default:
        return AppColors.primary.withOpacity(0.1);
    }
  }
}
