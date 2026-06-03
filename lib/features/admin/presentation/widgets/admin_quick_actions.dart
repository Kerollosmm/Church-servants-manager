import 'package:church_management_system/features/admin/presentation/widgets/quick_action_card.dart';
import 'package:flutter/material.dart';

class AdminQuickActions extends StatelessWidget {
  const AdminQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 16.0,
            ),
            child: Text(
              'إجراءات سريعة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: QuickActionCard(
                  icon: Icons.person_add_outlined,
                  title: 'إضافة طالب',
                  isPrimary: true,
                  onTap: () {
                    // Navigate to add student
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.group_add_outlined,
                  title: 'إنشاء فريق',
                  onTap: () {
                    // Navigate to add team
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'بدء الحضور',
                  onTap: () {
                    // Navigate to attendance
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
