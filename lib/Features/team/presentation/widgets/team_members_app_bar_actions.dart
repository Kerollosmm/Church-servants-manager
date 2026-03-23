import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamMembersAppBarActions extends StatelessWidget {
  const TeamMembersAppBarActions({super.key, required this.onSave});

  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Center(
            child: BlocBuilder<TeamMembersCubit, TeamMembersState>(
              builder: (context, state) {
                return Text(
                  '${state.selectedCount}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                );
              },
            ),
          ),
        ),
        BlocBuilder<TeamMembersCubit, TeamMembersState>(
          builder: (context, state) {
            return TextButton.icon(
              onPressed: state.isSaving ? null : onSave,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
            );
          },
        ),
      ],
    );
  }
}
