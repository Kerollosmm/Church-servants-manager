import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:flutter/material.dart';

class AttendanceFilterBar extends StatelessWidget {
  const AttendanceFilterBar({
    super.key,
    required this.teams,
    required this.selectedTeamId,
    required this.onChanged,
  });

  final List<TeamModel> teams;
  final String? selectedTeamId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedTeamId,
      decoration: const InputDecoration(
        labelText: 'الفريق',
        border: OutlineInputBorder(),
      ),
      items: teams
          .map(
            (team) => DropdownMenuItem<String>(
              value: team.id,
              child: Text(team.name),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}
