import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:flutter/material.dart';

/// Pure dropdown widget for selecting a team.
class TeamDropdown extends StatelessWidget {
  final List<TeamModel> teams;
  final String? selectedTeamId;
  final bool isLoading;
  final String? errorMessage;
  final bool showAllOption;
  final ValueChanged<String?> onChanged;
  final String? restrictToTeamId;
  final List<String>? restrictToTeamIds;
  final String? label;

  const TeamDropdown({
    super.key,
    required this.teams,
    this.selectedTeamId,
    this.isLoading = false,
    this.errorMessage,
    required this.onChanged,
    this.showAllOption = false,
    this.label,
    this.restrictToTeamId,
    this.restrictToTeamIds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          errorMessage!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.error,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final restrictedTeamIds = <String>{};
    if (restrictToTeamId != null && restrictToTeamId!.isNotEmpty) {
      restrictedTeamIds.add(restrictToTeamId!);
    }
    for (final id in restrictToTeamIds ?? const <String>[]) {
      if (id.isNotEmpty) {
        restrictedTeamIds.add(id);
      }
    }

    final visibleTeams = restrictedTeamIds.isEmpty
        ? teams
        : teams.where((t) => restrictedTeamIds.contains(t.id)).toList();

    if (visibleTeams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا توجد فرق متاحة.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final items = <DropdownMenuItem<String?>>[];

    if (showAllOption) {
      items.add(
        DropdownMenuItem<String?>(
          value: null,
          child: SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text('كل الفرق'),
            ),
          ),
        ),
      );
    }

    items.addAll(
      visibleTeams.map((team) {
        return DropdownMenuItem<String?>(
          value: team.id,
          child: SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(team.name),
            ),
          ),
        );
      }),
    );

    final validIds = visibleTeams.map((t) => t.id).toSet();
    final effectiveValue =
        (selectedTeamId != null && validIds.contains(selectedTeamId))
        ? selectedTeamId
        : (showAllOption ? null : visibleTeams.first.id);

    return AppDropdownField<String?>(
      initialValue: effectiveValue,
      labelText: label ?? 'الفريق',
      prefixIcon: Icons.group,
      items: items,
      onChanged: onChanged,
    );
  }
}
