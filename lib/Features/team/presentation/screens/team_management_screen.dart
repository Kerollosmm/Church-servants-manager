import 'package:church_management_system/features/team/presentation/widgets/team_management_coordinator.dart';
import 'package:flutter/material.dart';

/// Admin screen for managing teams/classes within each year/group.
class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeamManagementCoordinator();
  }
}
