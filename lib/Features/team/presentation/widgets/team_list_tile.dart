import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_action_row.dart';
import 'package:flutter/material.dart';

class TeamListTile extends StatelessWidget {
  const TeamListTile({
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
    final theme = Theme.of(context);

    return Card(
      color: team.isArchived ? const Color(0xFFF6F3ED) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.group, color: AppColors.primary),
        ),
        title: Text(
          team.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: _TeamSubtitle(team: team),
        trailing: TeamActionRow(
          team: team,
          onEdit: onEdit,
          onDelete: onDelete,
          onRestore: onRestore,
          onAssignServant: onAssignServant,
          onManageMembers: onManageMembers,
        ),
      ),
    );
  }
}

class _TeamSubtitle extends StatelessWidget {
  const _TeamSubtitle({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    if (team.isArchived) {
      return Text(
        'فريق مؤرشف',
        style: style?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    if (team.assignedServantName != null) {
      return Text('الخادم: ${team.assignedServantName}', style: style);
    }

    return Text(
      'لا يوجد خادم مخصص',
      style: style?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
