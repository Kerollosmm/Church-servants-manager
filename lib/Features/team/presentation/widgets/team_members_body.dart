import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_cubit.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_member_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamMembersBody extends StatelessWidget {
  const TeamMembersBody({
    super.key,
    required this.groupId,
    required this.teamId,
    required this.searchController,
  });

  final String groupId;
  final String teamId;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamMembersCubit, TeamMembersState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  AppSpacing.gapMd,
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  AppSpacing.gapMd,
                  FilledButton.icon(
                    onPressed: () => context.read<TeamMembersCubit>().load(
                      groupId: groupId,
                      teamId: teamId,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (state.loadedFromCache)
              const AppInfoBanner(
                message: 'وضع عدم الاتصال: يتم عرض البيانات المخزنة مؤقتا.',
                icon: Icons.cloud_off_outlined,
                margin: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: searchController,
                onChanged: context.read<TeamMembersCubit>().search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'ابحث عن مخدوم...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: state.visibleStudents.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = state.visibleStudents[index];
                  final isChecked = state.selectedStudentIds.contains(
                    student.docID,
                  );

                  return TeamMemberTile(
                    student: student,
                    isChecked: isChecked,
                    isEnabled: !state.isSaving,
                    onChanged: (value) => context
                        .read<TeamMembersCubit>()
                        .toggleSelection(student.docID, value),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
