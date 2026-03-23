import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_empty_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_filter_bar.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_stats_header.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/session_list_tile.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/usecases/assign_servant_to_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/create_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/get_teams_usecase.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceHistoryCoordinator extends StatefulWidget {
  const AttendanceHistoryCoordinator({super.key});

  @override
  State<AttendanceHistoryCoordinator> createState() =>
      _AttendanceHistoryCoordinatorState();
}

class _AttendanceHistoryCoordinatorState
    extends State<AttendanceHistoryCoordinator> {
  late final AttendanceHistoryCubit _historyCubit;
  late final AttendanceSessionAdminCubit _sessionAdminCubit;
  late final TeamCubit _teamCubit;
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _historyCubit = AttendanceHistoryCubit(
      repository: context.read<IAttendanceRepository>(),
    );
    _sessionAdminCubit = AttendanceSessionAdminCubit(
      repository: context.read<IAttendanceRepository>(),
    );
    _teamCubit = TeamCubit(
      teamRepository: context.read<TeamRepository>(),
      adminTeamService: context.read<AdminTeamService>(),
      getTeamsUseCase: getIt<GetTeamsUseCase>(),
      createTeamUseCase: getIt<CreateTeamUseCase>(),
      assignServantToTeamUseCase: getIt<AssignServantToTeamUseCase>(),
    );

    final actor = _currentActorOrNull();
    if (actor == null) {
      return;
    }

    _selectedTeamId =
        actor.role == UserRole.servant &&
            actor.effectiveAssignedTeamIds.length == 1
        ? actor.effectiveAssignedTeamIds.first
        : null;
    _loadTeamsForActor(actor);
    if (_selectedTeamId != null) {
      _historyCubit.loadForTeam(_selectedTeamId!);
    }
  }

  @override
  void dispose() {
    _historyCubit.close();
    _sessionAdminCubit.close();
    _teamCubit.close();
    super.dispose();
  }

  AuthUser? _currentActorOrNull() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    return null;
  }

  void _loadTeamsForActor(AuthUser actor) {
    if (actor.role == UserRole.admin) {
      _teamCubit.loadAllTeams();
      return;
    }

    final groupId = actor.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      _teamCubit.loadTeamsByGroup(
        groupId,
        defaultTeamId: actor.effectiveAssignedTeamIds.length == 1
            ? actor.effectiveAssignedTeamIds.first
            : null,
      );
    }
  }

  void _ensureInitialTeamSelection(AuthUser actor, List<TeamModel> teams) {
    if (_selectedTeamId != null || teams.isEmpty) {
      return;
    }

    final allowedTeamIds = actor.role == UserRole.servant
        ? actor.effectiveAssignedTeamIds.toSet()
        : null;
    final candidate = teams.firstWhere(
      (team) => allowedTeamIds == null || allowedTeamIds.contains(team.id),
      orElse: () => teams.first,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedTeamId = candidate.id);
      _historyCubit.loadForTeam(candidate.id);
    });
  }

  String _teamName(List<TeamModel> teams, String? teamId) {
    for (final team in teams) {
      if (team.id == teamId) {
        return team.name;
      }
    }
    return 'الفريق';
  }

  Future<void> _openCreateScreen() async {
    await Navigator.pushNamed(context, attendanceSessionCreate);
    if (_selectedTeamId != null) {
      _historyCubit.loadForTeam(_selectedTeamId!);
    }
  }

  Future<void> _closeActiveSession(AuthUser actor, AttendanceSession session) {
    return _sessionAdminCubit.closeSession(
      actor: actor,
      teamId: session.teamId,
      sessionId: session.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final actor = switch (authState) {
          AuthAuthenticated() => authState.user,
          AuthDegraded() => authState.user,
          _ => null,
        };

        if (actor == null) {
          return const Scaffold(
            body: Center(child: Text('لم يتم تسجيل الدخول.')),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider<TeamCubit>.value(value: _teamCubit),
            BlocProvider<AttendanceHistoryCubit>.value(value: _historyCubit),
            BlocProvider<AttendanceSessionAdminCubit>.value(
              value: _sessionAdminCubit,
            ),
          ],
          child: MultiBlocListener(
            listeners: [
              BlocListener<
                AttendanceSessionAdminCubit,
                AttendanceSessionAdminState
              >(
                listener: (context, state) {
                  if (state is AttendanceSessionAdminError) {
                    AppSnackbars.showError(context, state.message);
                    return;
                  }
                  if (state is AttendanceSessionAdminSuccess) {
                    AppSnackbars.showSuccess(
                      context,
                      state.message,
                      backgroundColor: AppColors.secondary,
                    );
                    _historyCubit.loadForTeam(state.session.teamId);
                  }
                },
              ),
            ],
            child: Scaffold(
              appBar: AppBar(
                title: const Text('الحضور'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث',
                    onPressed: _selectedTeamId == null
                        ? null
                        : () => _historyCubit.loadForTeam(_selectedTeamId!),
                  ),
                ],
              ),
              floatingActionButton:
                  actor.role == UserRole.admin || actor.role == UserRole.servant
                  ? FloatingActionButton.extended(
                      onPressed: _openCreateScreen,
                      icon: const Icon(Icons.add_task_outlined),
                      label: const Text('جلسة جديدة'),
                    )
                  : null,
              body: BlocBuilder<TeamCubit, TeamState>(
                builder: (context, teamState) {
                  final teams = teamState is TeamLoaded
                      ? teamState.teams
                      : const <TeamModel>[];
                  _ensureInitialTeamSelection(actor, teams);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: AttendanceFilterBar(
                          teams: teams,
                          selectedTeamId: _selectedTeamId,
                          isLoading:
                              teamState is TeamLoading ||
                              teamState is TeamInitial,
                          errorMessage: teamState is TeamError
                              ? teamState.message
                              : null,
                          actorRole: actor.role,
                          assignedTeamIds: actor.effectiveAssignedTeamIds,
                          onChanged: (teamId) {
                            if (teamId == null || teamId.isEmpty) {
                              return;
                            }
                            setState(() => _selectedTeamId = teamId);
                            _historyCubit.loadForTeam(teamId);
                          },
                        ),
                      ),
                      Expanded(
                        child:
                            BlocBuilder<
                              AttendanceHistoryCubit,
                              AttendanceHistoryState
                            >(
                              builder: (context, state) {
                                if (_selectedTeamId == null) {
                                  return const Center(
                                    child: Text(
                                      'اختر فريقا لعرض جلسات الحضور.',
                                    ),
                                  );
                                }

                                if (state is AttendanceHistoryLoading) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (state is AttendanceHistoryError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.lg,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: AppColors.error,
                                          ),
                                          AppSpacing.gapMd,
                                          Text(
                                            state.message,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (state is! AttendanceHistoryLoaded) {
                                  return const SizedBox.shrink();
                                }

                                final activeSession = state.activeSession;
                                final sessions = state.sessions;

                                if (sessions.isEmpty) {
                                  return AttendanceEmptyState(
                                    onRefresh: () async {
                                      _historyCubit.loadForTeam(
                                        _selectedTeamId!,
                                      );
                                    },
                                  );
                                }

                                final teamName = _teamName(
                                  teams,
                                  _selectedTeamId,
                                );

                                return ListView(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  children: [
                                    AttendanceStatsHeader(
                                      teamName: teamName,
                                      totalSessions: sessions.length,
                                      activeSessions: activeSession == null
                                          ? 0
                                          : 1,
                                    ),
                                    AppSpacing.gapMd,
                                    if (activeSession != null)
                                      SessionListTile(
                                        teamName: teamName,
                                        session: activeSession,
                                        isActive: true,
                                        canClose: actor.role == UserRole.admin,
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            attendanceTaking,
                                            arguments: AttendanceTakingArgs(
                                              actor: actor,
                                              teamId: activeSession.teamId,
                                              sessionId: activeSession.id,
                                            ),
                                          );
                                        },
                                        onClose: actor.role == UserRole.admin
                                            ? () => _closeActiveSession(
                                                actor,
                                                activeSession,
                                              )
                                            : null,
                                      ),
                                    if (activeSession != null) AppSpacing.gapMd,
                                    ...sessions.map(
                                      (session) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md,
                                        ),
                                        child: SessionListTile(
                                          session: session,
                                          teamName: teamName,
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              attendanceTaking,
                                              arguments: AttendanceTakingArgs(
                                                actor: actor,
                                                teamId: session.teamId,
                                                sessionId: session.id,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
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
      },
    );
  }
}
