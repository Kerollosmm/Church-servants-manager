import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/accessible_teams/accessible_teams_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_empty_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/session_create_form.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceSessionCreateCoordinator extends StatelessWidget {
  const AttendanceSessionCreateCoordinator({super.key, required this.actor});

  final AuthUser actor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AccessibleTeamsCubit(teamRepository: context.read<TeamRepository>())
            ..load(actor),
      child:
          BlocConsumer<
            AttendanceSessionAdminCubit,
            AttendanceSessionAdminState
          >(
            listener: (context, state) {
              if (state is AttendanceSessionAdminSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
                Navigator.of(context).pushReplacementNamed(
                  attendanceTaking,
                  arguments: AttendanceTakingArgs(
                    actor: actor,
                    teamId: state.session.teamId,
                    sessionId: state.session.id,
                  ),
                );
              }
              if (state is AttendanceSessionAdminError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, adminState) {
              return BlocBuilder<AccessibleTeamsCubit, AccessibleTeamsState>(
                builder: (context, teamsState) {
                  if (teamsState is AccessibleTeamsLoading ||
                      teamsState is AccessibleTeamsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (teamsState is AccessibleTeamsError) {
                    return AttendanceEmptyState(
                      icon: Icons.error_outline,
                      title: 'تعذر تحميل الفرق',
                      message: teamsState.message,
                    );
                  }

                  final teams = (teamsState as AccessibleTeamsLoaded).teams;
                  if (teams.isEmpty) {
                    return const AttendanceEmptyState(
                      icon: Icons.groups_outlined,
                      title: 'لا توجد فرق متاحة',
                      message:
                          'لا يوجد أي فريق متاح لك لإنشاء جلسة حضور حالياً.',
                    );
                  }

                  return SessionCreateForm(
                    teams: teams,
                    isSubmitting: adminState is AttendanceSessionAdminLoading,
                    onSubmit: (draft) {
                      context.read<AttendanceSessionAdminCubit>().createSession(
                        actor: actor,
                        teamId: draft.team.id,
                        teamNameSnapshot: draft.team.name,
                        startsAt: draft.startsAt,
                        durationMinutes: draft.durationMinutes,
                        title: draft.title,
                      );
                    },
                  );
                },
              );
            },
          ),
    );
  }
}
