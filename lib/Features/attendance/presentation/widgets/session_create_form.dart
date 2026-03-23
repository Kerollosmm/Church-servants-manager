import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_dropdown.dart';
import 'package:flutter/material.dart';

class SessionCreateForm extends StatelessWidget {
  const SessionCreateForm({
    super.key,
    required this.actor,
    required this.teams,
    required this.titleController,
    required this.durationController,
    required this.startsAt,
    required this.onTeamChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSubmit,
    this.selectedTeamId,
    this.isTeamsLoading = false,
    this.isSubmitting = false,
    this.teamsErrorMessage,
  });

  final UserRole actor;
  final List<TeamModel> teams;
  final TextEditingController titleController;
  final TextEditingController durationController;
  final DateTime startsAt;
  final ValueChanged<String?> onTeamChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onSubmit;
  final String? selectedTeamId;
  final bool isTeamsLoading;
  final bool isSubmitting;
  final String? teamsErrorMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const AppInfoBanner(
          icon: Icons.auto_awesome,
          message:
              'الغياب لا يتم تسجيله يدويا. أي مخدوم غير محدد عند نهاية الجلسة يصبح غائبا تلقائيا.',
        ),
        AppSpacing.gapMd,
        TeamDropdown(
          teams: teams,
          selectedTeamId: selectedTeamId,
          isLoading: isTeamsLoading,
          errorMessage: teamsErrorMessage,
          showAllOption: actor == UserRole.admin,
          restrictToTeamIds: actor == UserRole.servant
              ? teams.map((team) => team.id).toList(growable: false)
              : null,
          label: 'الفريق',
          onChanged: onTeamChanged,
        ),
        AppSpacing.gapMd,
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'عنوان الجلسة (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        AppSpacing.gapMd,
        TextField(
          controller: durationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المدة بالدقائق',
            border: OutlineInputBorder(),
          ),
        ),
        AppSpacing.gapMd,
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بداية الجلسة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AppSpacing.gapSm,
                Text(_formatDateTime(startsAt)),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('اختيار التاريخ'),
                      ),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPickTime,
                        icon: const Icon(Icons.access_time),
                        label: const Text('اختيار الوقت'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapLg,
        FilledButton.icon(
          onPressed: isSubmitting ? null : onSubmit,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.playlist_add_check),
          label: const Text('إنشاء الجلسة'),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
