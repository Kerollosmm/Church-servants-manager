import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/core/widgets/app_error_state.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
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

/// Screen displaying attendance session history for a team.
///
/// Shows team dropdown, active session card, and history cards.
/// Uses [AttendanceHistoryCubit], [AttendanceSessionAdminCubit],
/// and [TeamCubit].
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    final actor = _currentActor();
    _selectedTeamId =
        actor.role == UserRole.servant &&
            actor.effectiveAssignedTeamIds.length == 1
        ? actor.effectiveAssignedTeamIds.first
        : null;
  }

  AuthUser _currentActor() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    throw StateError('Unreachable');
  }

  void _ensureInitialTeamSelection(
    AuthUser actor,
    List<TeamModel> teams,
    BuildContext context,
  ) {
    if (_selectedTeamId != null || teams.isEmpty) return;
    final allowedTeamIds = actor.role == UserRole.servant
        ? actor.effectiveAssignedTeamIds.toSet()
        : null;

    TeamModel? candidate;
    try {
      candidate = teams.firstWhere(
        (team) => allowedTeamIds == null || allowedTeamIds.contains(team.id),
      );
    } on StateError {
      candidate = null;
    }

    if (allowedTeamIds != null && candidate == null) {
      return;
    }

    candidate ??= teams.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedTeamId = candidate!.id);
      context.read<AttendanceHistoryCubit>().loadForTeam(candidate!.id);
    });
  }

  String _teamName(List<TeamModel> teams, String? teamId) {
    for (final team in teams) {
      if (team.id == teamId) return team.name;
    }
    return 'الفريق';
  }

  Future<void> _openCreateScreen(BuildContext context) async {
    await Navigator.pushNamed(context, attendanceSessionCreate);
    if (!context.mounted) return;
    if (_selectedTeamId != null) {
      await context.read<AttendanceHistoryCubit>().loadForTeam(
        _selectedTeamId!,
      );
    }
  }

  Future<void> _closeActiveSession(
    AuthUser actor,
    AttendanceSession session,
    BuildContext context,
  ) {
    return context.read<AttendanceSessionAdminCubit>().closeSession(
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
            BlocProvider<TeamCubit>(
              create: (context) {
                final teamCubit = TeamCubit(
                  teamRepository: getIt<TeamRepository>(),
                  adminTeamService: getIt<AdminTeamService>(),
                );

                if (actor.role == UserRole.admin) {
                  teamCubit.loadAllTeams();
                } else {
                  final groupId = actor.groupId;
                  if (groupId != null && groupId.isNotEmpty) {
                    teamCubit.loadTeamsByGroup(
                      groupId,
                      defaultTeamId: actor.effectiveAssignedTeamIds.length == 1
                          ? actor.effectiveAssignedTeamIds.first
                          : null,
                    );
                  }
                }
                return teamCubit;
              },
            ),
            BlocProvider<AttendanceHistoryCubit>(
              create: (context) {
                final cubit = AttendanceHistoryCubit(
                  repository: getIt<AttendanceRepository>(),
                );
                if (_selectedTeamId != null) {
                  cubit.loadForTeam(_selectedTeamId!);
                }
                return cubit;
              },
            ),
            BlocProvider<AttendanceSessionAdminCubit>(
              create: (context) => AttendanceSessionAdminCubit(
                repository: getIt<AttendanceRepository>(),
              ),
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
                    context.read<AttendanceHistoryCubit>().loadForTeam(
                      state.session.teamId,
                    );
                  }
                },
              ),
            ],
            child: Builder(
              builder: (innerContext) => Scaffold(
                appBar: AppBar(
                  title: const Text('الحضور'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'تحديث',
                      onPressed: _selectedTeamId == null
                          ? null
                          : () => innerContext
                                .read<AttendanceHistoryCubit>()
                                .loadForTeam(_selectedTeamId!),
                    ),
                  ],
                ),
                floatingActionButton:
                    actor.role == UserRole.admin ||
                        actor.role == UserRole.servant
                    ? FloatingActionButton.extended(
                        onPressed: () => _openCreateScreen(innerContext),
                        icon: const Icon(Icons.add_task_outlined),
                        label: const Text('جلسة جديدة'),
                      )
                    : null,
                body: BlocBuilder<TeamCubit, TeamState>(
                  builder: (context, teamState) {
                    final teams = teamState is TeamLoaded
                        ? teamState.teams
                        : const <TeamModel>[];
                    _ensureInitialTeamSelection(actor, teams, context);

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
                            isLoading: teamState is TeamLoading,
                            errorMessage: teamState is TeamError
                                ? teamState.message
                                : null,
                            restrictToTeamIds:
                                actor.role == UserRole.servant &&
                                    actor.effectiveAssignedTeamIds.isNotEmpty
                                ? actor.effectiveAssignedTeamIds
                                : null,
                            label: 'الفريق',
                            onChanged: (teamId) {
                              if (teamId == null || teamId.isEmpty) return;
                              setState(() => _selectedTeamId = teamId);
                              context
                                  .read<AttendanceHistoryCubit>()
                                  .loadForTeam(teamId);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: AppInfoBanner(
                            message:
                                'الخدام يسجلون حاضر أو متأخر فقط، والغياب يتم اشتقاقه تلقائيا بعد إغلاق الجلسة.',
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
                                    return AppErrorState(
                                      message: state.message,
                                      title: 'تعذر تحميل الحضور',
                                      onRetry: () => innerContext
                                          .read<AttendanceHistoryCubit>()
                                          .loadForTeam(_selectedTeamId!),
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
                                      onRefresh: () => context
                                          .read<AttendanceHistoryCubit>()
                                          .loadForTeam(_selectedTeamId!),
                                    );
                                  }

                                  final historySessions = sessions
                                      .where(
                                        (session) =>
                                            activeSession == null ||
                                            session.id != activeSession.id,
                                      )
                                      .toList(growable: false);

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    itemCount:
                                        (activeSession != null ? 1 : 0) +
                                        historySessions.length,
                                    itemBuilder: (context, index) {
                                      if (activeSession != null && index == 0) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.md,
                                          ),
                                          child: _ActiveSessionCard(
                                            teamName: _teamName(
                                              teams,
                                              _selectedTeamId,
                                            ),
                                            session: activeSession,
                                            canClose:
                                                actor.role == UserRole.admin,
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
                                            onClose:
                                                actor.role == UserRole.admin
                                                ? () => _closeActiveSession(
                                                    actor,
                                                    activeSession,
                                                    context,
                                                  )
                                                : null,
                                          ),
                                        );
                                      }

                                      final sessionIndex = activeSession != null
                                          ? index - 1
                                          : index;
                                      final session =
                                          historySessions[sessionIndex];

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md,
                                        ),
                                        child: _SessionHistoryCard(
                                          session: session,
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
                                      );
                                    },
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
  const _SessionHistoryCard({required this.session, required this.onTap});

  final AttendanceSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF3F4F6),
          child: Icon(Icons.history, color: AppColors.primary),
        ),
        title: Text(
          session.title?.isNotEmpty == true ? session.title! : 'جلسة حضور',
        ),
        subtitle: Text(
          '${_formatDateTime(session.startsAt)} - ${_formatTime(session.endsAt)}',
        ),
        trailing: const Chip(label: Text('مغلقة')),
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
