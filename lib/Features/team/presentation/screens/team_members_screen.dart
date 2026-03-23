import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_cubit.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_members_app_bar_actions.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_members_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamMembersScreen extends StatefulWidget {
  final TeamMembersArgs args;

  const TeamMembersScreen({super.key, required this.args});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final membersCubit = context.read<TeamMembersCubit>();
    if (membersCubit.state.isSaving) return;

    await membersCubit.saveMembers(
      actor: widget.args.actor,
      team: widget.args.team,
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.args.team;

    return BlocProvider(
      create: (context) => TeamMembersCubit(
        studentRepository: context.read<StudentDataRepository>(),
        adminTeamService: context.read<AdminTeamService>(),
      )..load(groupId: team.groupId, teamId: team.id),
      child: BlocListener<TeamMembersCubit, TeamMembersState>(
        listener: (context, state) {
          if (state.feedbackMessage != null &&
              state.mutationStatus == TeamMembersMutationStatus.failure) {
            AppSnackbars.showError(context, state.feedbackMessage!);
          }
          if (state.feedbackMessage != null &&
              state.mutationStatus == TeamMembersMutationStatus.success) {
            AppSnackbars.showSuccess(
              context,
              state.feedbackMessage!,
              backgroundColor: AppColors.secondary,
            );
            Navigator.of(context).pop(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('الأعضاء • ${team.name}'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            actions: [TeamMembersAppBarActions(onSave: _save)],
          ),
          body: TeamMembersBody(
            groupId: team.groupId,
            teamId: team.id,
            searchController: _searchController,
          ),
        ),
      ),
    );
  }
}
