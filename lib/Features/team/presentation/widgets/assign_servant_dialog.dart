import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/widgets/assign_servant_dialog_content.dart';
import 'package:flutter/material.dart';

class AssignServantDialog extends StatelessWidget {
  final AuthUser actor;
  final TeamModel team;

  const AssignServantDialog({
    super.key,
    required this.actor,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    return AssignServantDialogContent(actor: actor, team: team);
  }
}
