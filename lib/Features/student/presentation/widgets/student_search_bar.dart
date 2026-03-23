import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/search/live_search_panel.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_dropdown.dart';
import 'package:flutter/material.dart';

class StudentSearchBar extends StatelessWidget {
  const StudentSearchBar({
    super.key,
    required this.controller,
    required this.actorRole,
    required this.assignedTeamIds,
    required this.isLoading,
    required this.teams,
    required this.teamsLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onTeamChanged,
    this.actorGroupId,
    this.selectedTeamId,
    this.teamsErrorMessage,
  });

  final TextEditingController controller;
  final UserRole actorRole;
  final List<String> assignedTeamIds;
  final bool isLoading;
  final List<TeamModel> teams;
  final bool teamsLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<String?> onTeamChanged;
  final String? actorGroupId;
  final String? selectedTeamId;
  final String? teamsErrorMessage;

  bool get _showAllOption =>
      actorRole == UserRole.admin ||
      (actorRole == UserRole.servant && assignedTeamIds.length > 1);

  List<String>? get _restrictToTeamIds =>
      actorRole == UserRole.servant && assignedTeamIds.isNotEmpty
      ? assignedTeamIds
      : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiveSearchPanel(
      controller: controller,
      label: 'ابحث باسم المخدوم',
      hint: 'ابحث بالاسم',
      clearTooltip: 'مسح',
      liveLabel: 'متصل بـ Firestore',
      isLoading: isLoading,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (actorRole == UserRole.servant)
            Text(
              assignedTeamIds.isNotEmpty
                  ? 'نطاق الخادم: ${assignedTeamIds.length} فريق'
                  : actorGroupId == null
                  ? 'نطاق الخادم: غير مخصص'
                  : 'نطاق الخادم: $actorGroupId',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          AppSpacing.gapSm,
          TeamDropdown(
            teams: teams,
            selectedTeamId: selectedTeamId,
            isLoading: teamsLoading,
            errorMessage: teamsErrorMessage,
            showAllOption: _showAllOption,
            restrictToTeamIds: _restrictToTeamIds,
            label: 'تصفية حسب الفريق',
            onChanged: onTeamChanged,
          ),
        ],
      ),
    );
  }
}
