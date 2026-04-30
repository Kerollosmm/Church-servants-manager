import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceTakingScreen extends StatefulWidget {
  const AttendanceTakingScreen({super.key, required this.args});

  final AttendanceTakingArgs args;

  @override
  State<AttendanceTakingScreen> createState() => _AttendanceTakingScreenState();
}

class _AttendanceTakingScreenState extends State<AttendanceTakingScreen> {
  Future<void> _closeSession(
    AttendanceTakingLoaded state,
    BuildContext context,
  ) {
    return context.read<AttendanceSessionAdminCubit>().closeSession(
      actor: widget.args.actor,
      teamId: state.session.teamId,
      sessionId: state.session.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AttendanceTakingCubit>(
          create: (context) =>
              AttendanceTakingCubit(repository: getIt<AttendanceRepository>())
                ..initialize(
                  teamId: widget.args.teamId,
                  sessionId: widget.args.sessionId,
                  actor: widget.args.actor,
                ),
        ),
        BlocProvider<AttendanceSessionAdminCubit>(
          create: (context) => AttendanceSessionAdminCubit(
            repository: getIt<AttendanceRepository>(),
          ),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AttendanceTakingCubit, AttendanceTakingState>(
            listenWhen: (previous, current) {
              final prevMessage = previous is AttendanceTakingLoaded
                  ? previous.errorMessage
                  : null;
              final currentMessage = current is AttendanceTakingLoaded
                  ? current.errorMessage
                  : null;
              return prevMessage != currentMessage ||
                  current is AttendanceTakingError;
            },
            listener: (context, state) {
              if (state is AttendanceTakingLoaded) {
                if (state.errorMessage != null) {
                  AppSnackbars.showError(context, state.errorMessage!);
                }
                if (state.mutationStatus == MutationStatus.success &&
                    state.pendingLocalMarks.isEmpty) {
                  AppSnackbars.showSuccess(
                    context,
                    'تم تسجيل الحضور بنجاح ✓',
                    backgroundColor: AppColors.secondary,
                  );
                }
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
            final now = DateTime.now();
            final loadedState = state is AttendanceTakingLoaded ? state : null;
            final title =
                loadedState != null &&
                    loadedState.session.title?.isNotEmpty == true
                ? loadedState.session.title!
                : 'تسجيل الحضور';

            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    if (loadedState != null &&
                        loadedState.pendingLocalMarks.isNotEmpty)
                      Text(
                        '${loadedState.pendingLocalMarks.length} في الانتظار',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                bottom:
                    loadedState != null &&
                        loadedState.mutationStatus == MutationStatus.inProgress
                    ? const PreferredSize(
                        preferredSize: Size.fromHeight(4),
                        child: LinearProgressIndicator(),
                      )
                    : null,
                actions: [
                  if (loadedState != null && loadedState.isSessionOpen)
                    IconButton(
                      tooltip: 'تحديد الباقي حاضر',
                      icon: const Icon(Icons.done_all_outlined),
                      onPressed:
                          loadedState.mutationStatus ==
                              MutationStatus.inProgress
                          ? null
                          : () => context
                                .read<AttendanceTakingCubit>()
                                .markAllRemainingPresent(
                                  actor: widget.args.actor,
                                ),
                    ),
                  if (widget.args.actor.role == UserRole.admin &&
                      loadedState != null &&
                      loadedState.isSessionOpen)
                    IconButton(
                      tooltip: 'إغلاق الجلسة',
                      icon: const Icon(Icons.lock_outline),
                      onPressed:
                          loadedState.mutationStatus ==
                              MutationStatus.inProgress
                          ? null
                          : () => _closeSession(loadedState, context),
                    ),
                ],
              ),
              bottomNavigationBar:
                  loadedState != null &&
                      loadedState.pendingLocalMarks.isNotEmpty
                  ? SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          onPressed:
                              loadedState.mutationStatus ==
                                  MutationStatus.inProgress
                              ? null
                              : () => context
                                    .read<AttendanceTakingCubit>()
                                    .submitAllPendingMarks(
                                      actor: widget.args.actor,
                                    ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            'تأكيد الحضور (${loadedState.pendingLocalMarks.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
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
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              AppInfoBanner(
                                icon: loaded.session.isOpenAt(now)
                                    ? Icons.schedule
                                    : Icons.lock_clock,
                                message: loaded.session.isOpenAt(now)
                                    ? 'الجلسة مفتوحة الآن. يمكنك تحديد حاضر أو متأخر فقط.'
                                    : 'الجلسة مغلقة الآن. أي مخدوم غير محدد يظهر كغائب تلقائيا.',
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
                                    'لا يوجد مخدومون ضمن هذه الجلسة.',
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
                                    return _RosterItemCard(
                                      item: item,
                                      actor: widget.args.actor,
                                      isMutationInProgress:
                                          loaded.mutationStatus ==
                                          MutationStatus.inProgress,
                                      isSessionOpen: loaded.isSessionOpen,
                                      effectivePendingMark: loaded
                                          .effectiveMarksMap[item.studentId],
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

class _RosterItemCard extends StatelessWidget {
  final AttendanceRosterItem item;
  final AuthUser actor;
  final bool isMutationInProgress;
  final bool isSessionOpen;
  final AttendanceMarkStatus? effectivePendingMark;

  const _RosterItemCard({
    required this.item,
    required this.actor,
    required this.isMutationInProgress,
    required this.isSessionOpen,
    this.effectivePendingMark,
  });

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
        return 'حاضر';
      case AttendanceEffectiveStatus.late:
        return 'متأخر';
      case AttendanceEffectiveStatus.absent:
        return 'غائب';
      case AttendanceEffectiveStatus.unmarked:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending =
        effectivePendingMark != null &&
        item.manualStatus != effectivePendingMark;

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
                if (isPending) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  AppSpacing.gapSm,
                ],
                Chip(
                  label: Text(_statusLabel(item.effectiveStatus)),
                  backgroundColor: _statusColor(
                    item.effectiveStatus,
                  ).withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: _statusColor(item.effectiveStatus),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (item.markedByName != null) ...[
              AppSpacing.gapXs,
              Text(
                'تم التسجيل بواسطة ${item.markedByName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      !isSessionOpen ||
                          isMutationInProgress ||
                          effectivePendingMark == AttendanceMarkStatus.present
                      ? null
                      : () => context.read<AttendanceTakingCubit>().markPresent(
                          actor: actor,
                          item: item,
                        ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('حاضر'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      !isSessionOpen ||
                          isMutationInProgress ||
                          effectivePendingMark == AttendanceMarkStatus.late
                      ? null
                      : () => context.read<AttendanceTakingCubit>().markLate(
                          actor: actor,
                          item: item,
                        ),
                  icon: const Icon(Icons.alarm_on_outlined),
                  label: const Text('متأخر'),
                ),
                if (item.isMarked || effectivePendingMark != null)
                  TextButton.icon(
                    onPressed: !isSessionOpen || isMutationInProgress
                        ? null
                        : () => context.read<AttendanceTakingCubit>().clearMark(
                            actor: actor,
                            item: item,
                          ),
                    icon: const Icon(Icons.clear),
                    label: const Text('مسح التحديد'),
                  ),
              ],
            ),
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
              session.teamNameSnapshot ?? 'الفريق',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.gapXs,
            Text('البداية: ${_formatDateTime(session.startsAt)}'),
            Text('النهاية: ${_formatDateTime(session.endsAt)}'),
            Text('المدة: ${session.durationMinutes} دقيقة'),
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
