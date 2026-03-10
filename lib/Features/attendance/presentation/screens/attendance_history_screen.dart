import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
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
    );
    final actor = _currentActorOrNull();
    if (actor != null) {
      _selectedTeamId = actor.role == UserRole.servant &&
              actor.effectiveAssignedTeamIds.length == 1
          ? actor.effectiveAssignedTeamIds.first
          : null;
      _loadTeamsForActor(actor);
      if (_selectedTeamId != null) {
        _historyCubit.loadForTeam(_selectedTeamId!);
      }
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
    if (_selectedTeamId != null || teams.isEmpty) return;
    final allowedTeamIds = actor.role == UserRole.servant
        ? actor.effectiveAssignedTeamIds.toSet()
        : null;
    final candidate = teams.firstWhere(
      (team) => allowedTeamIds == null || allowedTeamIds.contains(team.id),
      orElse: () => teams.first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedTeamId = candidate.id);
      _historyCubit.loadForTeam(candidate.id);
    });
  }

  String _teamName(List<TeamModel> teams, String? teamId) {
    for (final team in teams) {
      if (team.id == teamId) return team.name;
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
              BlocListener<AttendanceSessionAdminCubit, AttendanceSessionAdminState>(
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
              floatingActionButton: actor.role == UserRole.admin
                  || actor.role == UserRole.servant
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
                        child: TeamDropdown(
                          teams: teams,
                          selectedTeamId: _selectedTeamId,
                          isLoading: teamState is TeamLoading ||
                              teamState is TeamInitial,
                          errorMessage: teamState is TeamError
                              ? teamState.message
                              : null,
                          showAllOption: false,
                          restrictToTeamIds: actor.role == UserRole.servant &&
                                  actor.effectiveAssignedTeamIds.isNotEmpty
                              ? actor.effectiveAssignedTeamIds
                              : null,
                          label: 'الفريق',
                          onChanged: (teamId) {
                            if (teamId == null || teamId.isEmpty) return;
                            setState(() => _selectedTeamId = teamId);
                            _historyCubit.loadForTeam(teamId);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: AppInfoBanner(
                          icon: Icons.info_outline,
                          message:
                              'الخدام يسجلون حاضر أو متأخر فقط، والغياب يتم اشتقاقه تلقائيا بعد إغلاق الجلسة.',
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
                          builder: (context, state) {
                            if (_selectedTeamId == null) {
                              return const Center(
                                child: Text('اختر فريقا لعرض جلسات الحضور.'),
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
                                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                              return AppEmptyState(
                                title: 'لا توجد جلسات حضور',
                                subtitle:
                                    'أنشئ جلسة جديدة لبدء تسجيل الحضور لهذا الفريق.',
                                onRefresh: () async {
                                  _historyCubit.loadForTeam(_selectedTeamId!);
                                },
                              );
                            }

                            return ListView(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              children: [
                                if (activeSession != null)
                                  _ActiveSessionCard(
                                    teamName: _teamName(teams, _selectedTeamId),
                                    session: activeSession,
                                    canClose: actor.role == UserRole.admin,
                                    onOpen: () {
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
                                    child: _SessionHistoryCard(
                                      session: session,
                                      isActive: activeSession?.id == session.id,
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

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.teamName,
    required this.session,
    required this.onOpen,
    this.canClose = false,
    this.onClose,
  });

  final String teamName;
  final AttendanceSession session;
  final VoidCallback onOpen;
  final bool canClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF4FBF2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.secondary),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    session.title?.isNotEmpty == true
                        ? session.title!
                        : 'جلسة مفتوحة - $teamName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Chip(label: Text('مفتوحة')),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              '${_formatDateTime(session.startsAt)} - ${_formatTime(session.endsAt)}',
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('فتح الجلسة'),
                  ),
                ),
                if (canClose && onClose != null) ...[
                  AppSpacing.gapSm,
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('إغلاق'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({
    required this.session,
    required this.isActive,
    required this.onTap,
  });

  final AttendanceSession session;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              isActive ? const Color(0xFFE9F7EF) : const Color(0xFFF3F4F6),
          child: Icon(
            isActive ? Icons.schedule : Icons.history,
            color: isActive ? AppColors.secondary : AppColors.primary,
          ),
        ),
        title: Text(session.title?.isNotEmpty == true ? session.title! : 'جلسة حضور'),
        subtitle: Text(
          '${_formatDateTime(session.startsAt)} - ${_formatTime(session.endsAt)}',
        ),
        trailing: Chip(label: Text(isActive ? 'مفتوحة' : 'مغلقة')),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day ${_formatTime(value)}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
