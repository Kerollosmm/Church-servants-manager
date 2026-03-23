import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:flutter/material.dart';

class TeamActionRow extends StatelessWidget {
  const TeamActionRow({
    super.key,
    required this.team,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onAssignServant,
    required this.onManageMembers,
  });

  final TeamModel team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onAssignServant;
  final VoidCallback onManageMembers;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'members':
            onManageMembers();
            break;
          case 'assign':
            onAssignServant();
            break;
          case 'edit':
            onEdit();
            break;
          case 'delete':
            onDelete();
            break;
          case 'restore':
            onRestore();
            break;
        }
      },
      itemBuilder: (_) => team.isArchived
          ? const [PopupMenuItem(value: 'restore', child: Text('استعادة'))]
          : const [
              PopupMenuItem(value: 'members', child: Text('إدارة الأعضاء')),
              PopupMenuItem(value: 'assign', child: Text('تعيين خادم')),
              PopupMenuItem(value: 'edit', child: Text('تعديل')),
              PopupMenuItem(value: 'delete', child: Text('أرشفة')),
            ],
    );
  }
}
