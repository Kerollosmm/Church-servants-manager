import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_dropdown.dart';
import 'package:flutter/material.dart';

class AttendanceFilterBar extends StatelessWidget {
  const AttendanceFilterBar({
    super.key,
    required this.teams,
    required this.actorRole,
    required this.assignedTeamIds,
    required this.onChanged,
    this.selectedTeamId,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<TeamModel> teams;
  final UserRole actorRole;
  final List<String> assignedTeamIds;
  final ValueChanged<String?> onChanged;
  final String? selectedTeamId;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamDropdown(
          teams: teams,
          selectedTeamId: selectedTeamId,
          isLoading: isLoading,
          errorMessage: errorMessage,
          showAllOption: false,
          restrictToTeamIds:
              actorRole == UserRole.servant && assignedTeamIds.isNotEmpty
              ? assignedTeamIds
              : null,
          label: 'الفريق',
          onChanged: onChanged,
        ),
        AppSpacing.gapSm,
        const AppInfoBanner(
          icon: Icons.info_outline,
          message:
              'الخدام يسجلون حاضر أو متأخر فقط، والغياب يتم اشتقاقه تلقائيا بعد إغلاق الجلسة.',
        ),
      ],
    );
  }
}
