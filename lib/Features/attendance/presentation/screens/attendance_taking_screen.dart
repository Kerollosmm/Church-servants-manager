import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
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
    )
      ..initialize(teamId: widget.args.teamId, sessionId: widget.args.sessionId);
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

  Future<void> _closeSession(AttendanceTakingLoaded state) {
    return _sessionAdminCubit.closeSession(
      actor: widget.args.actor,
      teamId: state.session.teamId,
      sessionId: state.session.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AttendanceTakingCubit>.value(value: _takingCubit),
        BlocProvider<AttendanceSessionAdminCubit>.value(value: _sessionAdminCubit),
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
              if (state is AttendanceTakingLoaded && state.mutationError != null) {
                AppSnackbars.showError(context, state.mutationError!);
              }
              if (state is AttendanceTakingError) {
                AppSnackbars.showError(context, state.message);
              }
            },
          ),
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
              }
            },
          ),
        ],
        child: BlocBuilder<AttendanceTakingCubit, AttendanceTakingState>(
          builder: (context, state) {
            final loadedState = state is AttendanceTakingLoaded ? state : null;
            final title = loadedState != null &&
                    loadedState.session.title?.isNotEmpty == true
                ? loadedState.session.title!
                : 'تسجيل الحضور';

            return Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: [
                  if (loadedState != null && loadedState.session.isOpenAt(DateTime.now()))
                    IconButton(
                      tooltip: 'تحديد الباقي حاضر',
                      icon: const Icon(Icons.done_all_outlined),
                      onPressed: loadedState.isMutating
                          ? null
                          : () => _takingCubit.markAllRemainingPresent(
                              actor: widget.args.actor,
                            ),
                    ),
                  if (widget.args.actor.role == UserRole.admin &&
                      loadedState != null &&
                      loadedState.session.isOpenAt(DateTime.now()))
                    IconButton(
                      tooltip: 'إغلاق الجلسة',
                      icon: const Icon(Icons.lock_outline),
                      onPressed: () => _closeSession(loadedState),
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
                      return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            AppInfoBanner(
                              icon: loaded.session.isOpenAt(DateTime.now())
                                  ? Icons.schedule
                                  : Icons.lock_clock,
                              message: loaded.session.isOpenAt(DateTime.now())
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
                                child: Text('لا يوجد مخدومون ضمن هذه الجلسة.'),
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
                                  final isOpen = loaded.session.isOpenAt(
                                    DateTime.now(),
                                  );
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
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              Chip(
                                                label: Text(
                                                  _statusLabel(item.effectiveStatus),
                                                ),
                                                backgroundColor: _statusColor(
                                                  item.effectiveStatus,
                                                ).withValues(alpha: 0.14),
                                                labelStyle: TextStyle(
                                                  color: _statusColor(
                                                    item.effectiveStatus,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item.markedByName != null) ...[
                                            AppSpacing.gapXs,
                                            Text(
                                              'تم التسجيل بواسطة ${item.markedByName}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                          AppSpacing.gapMd,
                                          Wrap(
                                            spacing: AppSpacing.sm,
                                            runSpacing: AppSpacing.sm,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: !isOpen || loaded.isMutating
                                                    ? null
                                                    : () => _takingCubit.markPresent(
                                                        actor: widget.args.actor,
                                                        item: item,
                                                      ),
                                                icon: const Icon(Icons.check_circle_outline),
                                                label: const Text('حاضر'),
                                              ),
                                              OutlinedButton.icon(
                                                onPressed: !isOpen || loaded.isMutating
                                                    ? null
                                                    : () => _takingCubit.markLate(
                                                        actor: widget.args.actor,
                                                        item: item,
                                                      ),
                                                icon: const Icon(Icons.alarm_on_outlined),
                                                label: const Text('متأخر'),
                                              ),
                                              if (item.isMarked)
                                                TextButton.icon(
                                                  onPressed: !isOpen || loaded.isMutating
                                                      ? null
                                                      : () => _takingCubit.clearMark(
                                                          actor: widget.args.actor,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
