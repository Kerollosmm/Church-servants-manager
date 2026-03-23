import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_state_message.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_empty_state.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamManagementBody extends StatelessWidget {
  const TeamManagementBody({
    super.key,
    required this.showArchived,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onAssignServant,
    required this.onManageMembers,
  });

  final bool showArchived;
  final Future<void> Function() onRefresh;
  final ValueChanged<TeamModel> onEdit;
  final ValueChanged<TeamModel> onDelete;
  final ValueChanged<TeamModel> onRestore;
  final ValueChanged<TeamModel> onAssignServant;
  final ValueChanged<TeamModel> onManageMembers;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamError) {
          AppSnackbars.showError(context, state.message);
        }
        if (state is TeamLoaded &&
            state.feedbackMessage != null &&
            state.mutationStatus == TeamMutationStatus.success) {
          AppSnackbars.showSuccess(
            context,
            state.feedbackMessage!,
            backgroundColor: AppColors.secondary,
          );
        }
        if (state is TeamLoaded &&
            state.feedbackMessage != null &&
            state.mutationStatus == TeamMutationStatus.failure) {
          AppSnackbars.showError(context, state.feedbackMessage!);
        }
      },
      builder: (context, state) {
        if (state is TeamLoading || state is TeamInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TeamError) {
          return AppStateMessage(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            title: 'تعذر تحميل الفرق',
            message: state.message,
            onRetry: onRefresh,
          );
        }

        if (state is! TeamLoaded) {
          return const SizedBox.shrink();
        }

        if (state.teams.isEmpty) {
          return TeamEmptyState(showArchived: showArchived);
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.teams.length,
            separatorBuilder: (_, _) => AppSpacing.gapSm,
            itemBuilder: (context, index) {
              final team = state.teams[index];
              return TeamListTile(
                team: team,
                onEdit: () => onEdit(team),
                onDelete: () => onDelete(team),
                onRestore: () => onRestore(team),
                onAssignServant: () => onAssignServant(team),
                onManageMembers: () => onManageMembers(team),
              );
            },
          ),
        );
      },
    );
  }
}
