import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/widgets/common/app_key_value_row.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_dashboard_cubit.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_stat_card.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantAccountSummaryCard extends StatelessWidget {
  const ServantAccountSummaryCard({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.role == UserRole.servant ? 'خادم' : user.role.name;

    return ServantStatCard(
      title: 'ملخص الحساب',
      child: BlocProvider(
        create: (context) => ServantDashboardCubit(
          teamRepository: context.read<TeamRepository>(),
          studentRepository: context.read<StudentDataRepository>(),
          attendanceRepository: context.read<IAttendanceRepository>(),
        )..loadAssignedTeamNames(user.effectiveAssignedTeamIds),
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppKeyValueRow(label: 'البريد الإلكتروني', value: user.email),
              AppKeyValueRow(label: 'الدور', value: roleLabel),
              if (user.role == UserRole.servant) ...[
                AppKeyValueRow(label: 'المجموعة', value: user.groupId ?? '--'),
                _AssignedTeamsRow(user: user),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignedTeamsRow extends StatelessWidget {
  const _AssignedTeamsRow({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final assignedTeamIds = user.effectiveAssignedTeamIds;
    if (assignedTeamIds.isEmpty) {
      return const AppKeyValueRow(label: 'الفريق المكلف به', value: 'غير محدد');
    }

    return BlocBuilder<ServantDashboardCubit, ServantDashboardState>(
      builder: (context, state) {
        final teamNames = state.isLoading
            ? 'جار التحميل...'
            : state.teamNames.isNotEmpty
            ? state.teamNames.join('، ')
            : (state.errorMessage ?? 'تعذر تحديد الفريق');
        final label = assignedTeamIds.length > 1
            ? 'الفرق المكلف بها'
            : 'الفريق المكلف به';
        return AppKeyValueRow(label: label, value: teamNames);
      },
    );
  }
}
