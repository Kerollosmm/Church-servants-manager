import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_members_cubit.dart';
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
            actions: [
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
                    onPressed: state.isSaving ? null : _save,
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<TeamMembersCubit, TeamMembersState>(
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
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        AppSpacing.gapMd,
                        Text(state.errorMessage!, textAlign: TextAlign.center),
                        AppSpacing.gapMd,
                        FilledButton.icon(
                          onPressed: () => context
                              .read<TeamMembersCubit>()
                              .load(groupId: team.groupId, teamId: team.id),
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
                      message:
                          'وضع عدم الاتصال: يتم عرض البيانات المخزنة مؤقتا.',
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
                      controller: _searchController,
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

                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: state.isSaving
                              ? null
                              : (value) => context
                                    .read<TeamMembersCubit>()
                                    .toggleSelection(
                                      student.docID,
                                      value ?? false,
                                    ),
                          title: Text(student.name),
                          subtitle: Text('الصف ${student.grade}'),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
