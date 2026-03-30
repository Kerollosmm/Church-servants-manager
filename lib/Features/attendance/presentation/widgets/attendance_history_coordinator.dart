import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/accessible_teams/accessible_teams_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_empty_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_filter_bar.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/session_list_tile.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceHistoryCoordinator extends StatefulWidget {
  const AttendanceHistoryCoordinator({super.key, required this.actor});

  final AuthUser actor;

  @override
  State<AttendanceHistoryCoordinator> createState() =>
      _AttendanceHistoryCoordinatorState();
}

class _AttendanceHistoryCoordinatorState
    extends State<AttendanceHistoryCoordinator> {
  String? _selectedTeamId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AccessibleTeamsCubit(teamRepository: context.read<TeamRepository>())
            ..load(widget.actor),
      child: BlocBuilder<AccessibleTeamsCubit, AccessibleTeamsState>(
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
              message: 'لا يوجد أي فريق متاح لعرض سجل الحضور حالياً.',
            );
          }

          _selectedTeamId ??= teams.first.id;
          final historyCubit = context.read<AttendanceHistoryCubit>();
          final historyState = historyCubit.state;
          if (historyState is! AttendanceHistoryLoaded ||
              historyState.teamId != _selectedTeamId) {
            historyCubit.loadForTeam(_selectedTeamId!);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AttendanceFilterBar(
                  teams: teams,
                  selectedTeamId: _selectedTeamId,
                  onChanged: (value) {
                    if (value == null || value == _selectedTeamId) return;
                    setState(() => _selectedTeamId = value);
                    context.read<AttendanceHistoryCubit>().loadForTeam(value);
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      BlocBuilder<
                        AttendanceHistoryCubit,
                        AttendanceHistoryState
                      >(
                        builder: (context, historyState) {
                          if (historyState is AttendanceHistoryLoading ||
                              historyState is AttendanceHistoryInitial) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (historyState is AttendanceHistoryError) {
                            return AttendanceEmptyState(
                              icon: Icons.error_outline,
                              title: 'تعذر تحميل السجل',
                              message: historyState.message,
                            );
                          }

                          final loaded =
                              historyState as AttendanceHistoryLoaded;
                          final TeamModel currentTeam = teams.firstWhere(
                            (team) => team.id == loaded.teamId,
                            orElse: () => teams.first,
                          );

                          return ListView(
                            children: [
                              if (loaded.activeSession != null)
                                Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.play_circle_outline,
                                    ),
                                    title: const Text('جلسة نشطة الآن'),
                                    subtitle: Text(
                                      loaded.activeSession!.title
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true
                                          ? loaded.activeSession!.title!
                                          : loaded.activeSession!.dateKey,
                                    ),
                                    trailing: FilledButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                          attendanceTaking,
                                          arguments: AttendanceTakingArgs(
                                            actor: widget.actor,
                                            teamId:
                                                loaded.activeSession!.teamId,
                                            sessionId: loaded.activeSession!.id,
                                          ),
                                        );
                                      },
                                      child: const Text('فتح'),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(attendanceSessionCreate),
                                icon: const Icon(Icons.add),
                                label: Text(
                                  'إنشاء جلسة جديدة لـ ${currentTeam.name}',
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (loaded.sessions.isEmpty)
                                const AttendanceEmptyState(
                                  icon: Icons.history_outlined,
                                  title: 'لا توجد جلسات بعد',
                                  message:
                                      'ابدأ بإنشاء أول جلسة حضور لهذا الفريق.',
                                )
                              else
                                ...loaded.sessions.map(
                                  (session) => SessionListTile(
                                    session: session,
                                    onTap: session.isClosed
                                        ? null
                                        : () {
                                            Navigator.of(context).pushNamed(
                                              attendanceTaking,
                                              arguments: AttendanceTakingArgs(
                                                actor: widget.actor,
                                                teamId: session.teamId,
                                                sessionId: session.id,
                                              ),
                                            );
                                          },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
