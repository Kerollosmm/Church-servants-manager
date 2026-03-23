import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_menu_field.dart';
import 'package:church_management_system/core/widgets/form/form_section_card.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_form_teams_cubit.dart';
import 'package:flutter/material.dart';

class StudentAcademicForm extends StatelessWidget {
  const StudentAcademicForm({
    super.key,
    required this.actorRole,
    required this.group,
    required this.educationStage,
    required this.grade,
    required this.teamsState,
    required this.onGroupChanged,
    required this.onTeamChanged,
    required this.onEducationStageChanged,
    required this.onGradeChanged,
  });

  final UserRole actorRole;
  final Group group;
  final EducationStage educationStage;
  final int grade;
  final StudentFormTeamsState teamsState;
  final ValueChanged<Group> onGroupChanged;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<EducationStage> onEducationStageChanged;
  final ValueChanged<int> onGradeChanged;

  bool get _isTeacher => actorRole == UserRole.servant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormSectionCard(
      title: 'البيانات الدراسية',
      titleStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
      children: [
        AppDropdownMenuField<Group>(
          initialSelection: group,
          enabled: !_isTeacher,
          dropdownMenuEntries: Group.values
              .map(
                (value) => DropdownMenuEntry(value: value, label: value.name),
              )
              .toList(growable: false),
          onSelected: (value) {
            if (value != null) {
              onGroupChanged(value);
            }
          },
          label: Text(_isTeacher ? 'المجموعة (مخصصة)' : 'المجموعة'),
          leadingIcon: Icons.school_outlined,
        ),
        AppSpacing.gapMd,
        if (teamsState.isLoading) ...[
          const LinearProgressIndicator(),
          AppSpacing.gapMd,
        ],
        if (teamsState.errorMessage != null) ...[
          Text(
            teamsState.errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
          AppSpacing.gapMd,
        ],
        AppDropdownField<String>(
          fieldKey: ValueKey(
            'team-field-${group.name}-${teamsState.selectedTeamId ?? 'none'}-${teamsState.teams.length}',
          ),
          initialValue: teamsState.selectedTeamId,
          labelText: 'الفريق',
          prefixIcon: Icons.group_outlined,
          items: teamsState.teams
              .map(
                (team) => DropdownMenuItem<String>(
                  value: team.id,
                  child: Text(team.name),
                ),
              )
              .toList(growable: false),
          onChanged: teamsState.isLoading || teamsState.teams.isEmpty
              ? null
              : onTeamChanged,
          validator: (value) {
            if (teamsState.isLoading) return null;
            if (teamsState.teams.isEmpty) {
              return 'لا توجد فرق متاحة لهذه المجموعة';
            }
            if (value == null || value.isEmpty) {
              return 'اختيار الفريق مطلوب';
            }
            return null;
          },
        ),
        AppSpacing.gapMd,
        AppDropdownMenuField<EducationStage>(
          initialSelection: educationStage,
          dropdownMenuEntries: EducationStage.values
              .map(
                (value) => DropdownMenuEntry(value: value, label: value.name),
              )
              .toList(growable: false),
          onSelected: (value) {
            if (value != null) {
              onEducationStageChanged(value);
            }
          },
          label: const Text('المرحلة التعليمية'),
          leadingIcon: Icons.badge_outlined,
        ),
        AppSpacing.gapMd,
        AppDropdownMenuField<int>(
          initialSelection: grade,
          dropdownMenuEntries: List.generate(
            12,
            (index) =>
                DropdownMenuEntry(value: index + 1, label: 'الصف ${index + 1}'),
          ),
          onSelected: (value) {
            if (value != null) {
              onGradeChanged(value);
            }
          },
          label: const Text('الصف'),
          leadingIcon: Icons.numbers_outlined,
        ),
      ],
    );
  }
}
