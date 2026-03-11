import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceTakingScreen extends StatefulWidget {
  const AttendanceTakingScreen({super.key, required this.args});

  final AttendanceTakingArgs args;

  @override
  State<AttendanceTakingScreen> createState() => _AttendanceTakingScreenState();
}

class _AttendanceTakingScreenState extends State<AttendanceTakingScreen> {
  late final AttendanceTakingCubit _takingCubit;
  late final AttendanceSessionAdminCubit _sessionAdminCubit;

  @override
  void initState() {
    super.initState();
    _takingCubit = AttendanceTakingCubit(
      repository: context.read<IAttendanceRepository>(),
    )..initialize(teamId: widget.args.teamId, sessionId: widget.args.sessionId);
    _sessionAdminCubit = AttendanceSessionAdminCubit(
      repository: context.read<IAttendanceRepository>(),
    );
  }

  @override
  void dispose() {
    _takingCubit.close();
    _sessionAdminCubit.close();
    super.dispose();
  }

  bool get _isAdmin => widget.args.actor.role == UserRole.admin;

  bool _canEditSession(AttendanceSession session) {
    return session.canRoleEdit(
      role: widget.args.actor.role,
      now: DateTime.now(),
    );
  }

  bool _canReopenSession(AttendanceSession session) {
    return _isAdmin &&
        session.isEffectivelyClosedAt(DateTime.now()) &&
        !session.isReopenedForAdminEdit;
  }

  Color _statusColor(AttendanceEffectiveStatus status) {
    switch (status) {
      case AttendanceEffectiveStatus.present:
        return AppColors.secondary;
      case AttendanceEffectiveStatus.late:
        return Colors.orange;
      case AttendanceEffectiveStatus.absent:
        return AppColors.error;
      case AttendanceEffectiveStatus.unmarked:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(AttendanceEffectiveStatus status) {
    switch (status) {
      case AttendanceEffectiveStatus.present:
        return 'Present';
      case AttendanceEffectiveStatus.late:
        return 'Late';
      case AttendanceEffectiveStatus.absent:
        return 'Absent';
      case AttendanceEffectiveStatus.unmarked:
        return 'Unmarked';
    }
  }

  Future<void> _closeSession(AttendanceSession session) {
    return _sessionAdminCubit.closeSession(
      actor: widget.args.actor,
      teamId: session.teamId,
      sessionId: session.id,
    );
  }

  Future<void> _reopenSession(AttendanceSession session) {
    return _sessionAdminCubit.reopenSession(
      actor: widget.args.actor,
      teamId: session.teamId,
      sessionId: session.id,
    );
  }

  String _bannerMessage(AttendanceSession session) {
    if (session.isReopenedForAdminEdit) {
      return _isAdmin
          ? 'Admin correction mode is active. You can update marks and notes for exceptions.'
          : 'This session was reopened for admin correction. Servants can view it, but cannot edit it.';
    }
    if (session.isOpenAt(DateTime.now())) {
      return 'This session is open. You can mark students as present or late.';
    }
    return 'This session is closed. Any unmarked student is counted as absent.';
  }

  IconData _bannerIcon(AttendanceSession session) {
    if (session.isReopenedForAdminEdit) {
      return Icons.lock_open_outlined;
    }
    if (session.isOpenAt(DateTime.now())) {
      return Icons.schedule;
    }
    return Icons.lock_clock;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AttendanceTakingCubit>.value(value: _takingCubit),
        BlocProvider<AttendanceSessionAdminCubit>.value(
          value: _sessionAdminCubit,
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AttendanceTakingCubit, AttendanceTakingState>(
            listenWhen: (previous, current) {
              final prevMessage = previous is AttendanceTakingLoaded
                  ? previous.mutationError
                  : null;
              final currentMessage = current is AttendanceTakingLoaded
                  ? current.mutationError
                  : null;
              return prevMessage != currentMessage && currentMessage != null;
            },
            listener: (context, state) {
              if (state is AttendanceTakingLoaded &&
                  state.mutationError != null) {
                AppSnackbars.showError(context, state.mutationError!);
              }
              if (state is AttendanceTakingError) {
                AppSnackbars.showError(context, state.message);
              }
            },
          ),
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
              }
            },
          ),
        ],
        child: BlocBuilder<AttendanceTakingCubit, AttendanceTakingState>(
          builder: (context, state) {
            final loadedState = state is AttendanceTakingLoaded ? state : null;
            final title =
                loadedState != null &&
                    loadedState.session.title?.isNotEmpty == true
                ? loadedState.session.title!
                : 'Attendance';

            return Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: [
                  if (loadedState != null &&
                      _canEditSession(loadedState.session))
                    IconButton(
                      tooltip: 'Mark remaining present',
                      icon: const Icon(Icons.done_all_outlined),
                      onPressed: loadedState.isMutating
                          ? null
                          : () => _takingCubit.markAllRemainingPresent(
                              actor: widget.args.actor,
                            ),
                    ),
                  if (_isAdmin &&
                      loadedState != null &&
                      _canReopenSession(loadedState.session))
                    IconButton(
                      tooltip: 'Reopen for correction',
                      icon: const Icon(Icons.lock_open_outlined),
                      onPressed: () => _reopenSession(loadedState.session),
                    ),
                  if (_isAdmin &&
                      loadedState != null &&
                      (loadedState.session.isOpenAt(DateTime.now()) ||
                          loadedState.session.isReopenedForAdminEdit))
                    IconButton(
                      tooltip: loadedState.session.isReopenedForAdminEdit
                          ? 'Close correction mode'
                          : 'Close session',
                      icon: const Icon(Icons.lock_outline),
                      onPressed: () => _closeSession(loadedState.session),
                    ),
                ],
              ),
              body: switch (state) {
                AttendanceTakingLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AttendanceTakingError() => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(state.message, textAlign: TextAlign.center),
                  ),
                ),
                AttendanceTakingLoaded() => Builder(
                  builder: (context) {
                    final loaded = state;
                    final canEditSession = _canEditSession(loaded.session);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              AppInfoBanner(
                                icon: _bannerIcon(loaded.session),
                                message: _bannerMessage(loaded.session),
                              ),
                              AppSpacing.gapSm,
                              _SessionHeaderCard(session: loaded.session),
                            ],
                          ),
                        ),
                        Expanded(
                          child: loaded.roster.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No students are included in this session.',
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    0,
                                    AppSpacing.md,
                                    AppSpacing.md,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = loaded.roster[index];
                                    return _AttendanceRosterCard(
                                      item: item,
                                      isMutating: loaded.isMutating,
                                      canEditSession: canEditSession,
                                      statusColor: _statusColor(
                                        item.effectiveStatus,
                                      ),
                                      statusLabel: _statusLabel(
                                        item.effectiveStatus,
                                      ),
                                      onMarkPresent: () =>
                                          _takingCubit.markPresent(
                                            actor: widget.args.actor,
                                            item: item,
                                          ),
                                      onMarkLate: () => _takingCubit.markLate(
                                        actor: widget.args.actor,
                                        item: item,
                                      ),
                                      onClear: item.isMarked
                                          ? () => _takingCubit.clearMark(
                                              actor: widget.args.actor,
                                              item: item,
                                            )
                                          : null,
                                    );
                                  },
                                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                                  itemCount: loaded.roster.length,
                                ),
                        ),
                      ],
                    );
                  },
                ),
                _ => const SizedBox.shrink(),
              },
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceRosterCard extends StatelessWidget {
  const _AttendanceRosterCard({
    required this.item,
    required this.isMutating,
    required this.canEditSession,
    required this.statusColor,
    required this.statusLabel,
    required this.onMarkPresent,
    required this.onMarkLate,
    this.onClear,
  });

  final AttendanceRosterItem item;
  final bool isMutating;
  final bool canEditSession;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkLate;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final note = item.note?.trim();
    final hasNote = note != null && note.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.studentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (item.markedByName != null && item.markedByName!.isNotEmpty) ...[
              AppSpacing.gapXs,
              Text(
                'Marked by ${item.markedByName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (hasNote) ...[
              AppSpacing.gapSm,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            if (canEditSession) ...[
              AppSpacing.gapMd,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: isMutating ? null : onMarkPresent,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Present'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isMutating ? null : onMarkLate,
                    icon: const Icon(Icons.alarm_on_outlined),
                    label: const Text('Late'),
                  ),
                  if (item.isMarked && onClear != null)
                    TextButton.icon(
                      onPressed: isMutating ? null : onClear,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionHeaderCard extends StatelessWidget {
  const _SessionHeaderCard({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.teamNameSnapshot ?? 'Team',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.gapXs,
            Text('Starts: ${_formatDateTime(session.startsAt)}'),
            Text('Ends: ${_formatDateTime(session.endsAt)}'),
            Text('Duration: ${session.durationMinutes} minutes'),
            if (session.isReopenedForAdminEdit) ...[
              AppSpacing.gapXs,
              Text(
                'Correction mode reopened by ${session.reopenedByName ?? 'Admin'}'
                '${session.reopenedAt == null ? '' : ' at ${_formatDateTime(session.reopenedAt!)}'}',
              ),
            ],
          ],
        ),
      ),
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
