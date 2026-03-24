import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/timer/attendance_session_timer_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/timer/attendance_session_timer_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_session_header.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_student_row.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/session_expiry_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceTakingView extends StatefulWidget {
  const AttendanceTakingView({super.key, required this.args});

  final AttendanceTakingArgs args;

  @override
  State<AttendanceTakingView> createState() => _AttendanceTakingViewState();
}

class _AttendanceTakingViewState extends State<AttendanceTakingView> {
  late final AttendanceTakingCubit _takingCubit;
  late final AttendanceSessionAdminCubit _sessionAdminCubit;
  // FIX [008]: Dedicated timer cubit to avoid roster rebuilds every second. (T016/T018)
  late final AttendanceSessionTimerCubit _timerCubit;

  @override
  void initState() {
    super.initState();
    _takingCubit = AttendanceTakingCubit(
      repository: context.read<IAttendanceRepository>(),
    )..initialize(teamId: widget.args.teamId, sessionId: widget.args.sessionId);
    _sessionAdminCubit = AttendanceSessionAdminCubit(
      repository: context.read<IAttendanceRepository>(),
    );
    _timerCubit =
        AttendanceSessionTimerCubit(); // FIX [008]: started once session loads (T018)
  }

  @override
  void dispose() {
    _takingCubit.close();
    _sessionAdminCubit.close();
    _timerCubit.close(); // FIX [008]: cancel periodic timer on dispose (T018)
    super.dispose();
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
        BlocProvider<AttendanceSessionAdminCubit>.value(
          value: _sessionAdminCubit,
        ),
        // FIX [008]: Provide timer cubit scoped to this screen. (T018)
        BlocProvider<AttendanceSessionTimerCubit>.value(value: _timerCubit),
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
            return BlocBuilder<
              AttendanceSessionTimerCubit,
              AttendanceSessionTimerState
            >(
              builder: (context, timerState) {
                final loadedState = state is AttendanceTakingLoaded
                    ? state
                    : null;
                final title =
                    loadedState != null &&
                        loadedState.session.title?.isNotEmpty == true
                    ? loadedState.session.title!
                    : 'تسجيل الحضور';
                // FIX [009-A1]: derive every attendance action from timer-driven state so expiry disables UI immediately.
                final isSessionOpen =
                    loadedState != null &&
                    !timerState.isExpired &&
                    loadedState.session.isOpenAt(DateTime.now());

                return Scaffold(
                  appBar: AppBar(
                    title: Text(title),
                    actions: [
                      if (loadedState != null && isSessionOpen)
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
                          isSessionOpen)
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
                    // FIX [008]: Extracted to _AttendanceTakingLoadedBody for
                    // timer integration without a God Widget violation. (T018)
                    AttendanceTakingLoaded() => _AttendanceTakingLoadedBody(
                      state: state,
                      timerCubit: _timerCubit,
                      actor: widget.args.actor,
                      takingCubit: _takingCubit,
                      isSessionOpen: isSessionOpen,
                      onCloseSession: () => _closeSession(state),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// FIX [008]: Private body widget extracted to keep AttendanceTakingView under
// 150 lines and to scope timer starts to the loaded state. (T018)
class _AttendanceTakingLoadedBody extends StatefulWidget {
  const _AttendanceTakingLoadedBody({
    required this.state,
    required this.timerCubit,
    required this.actor,
    required this.takingCubit,
    required this.isSessionOpen,
    required this.onCloseSession,
  });

  final AttendanceTakingLoaded state;
  final AttendanceSessionTimerCubit timerCubit;
  final AuthUser actor;
  final AttendanceTakingCubit takingCubit;
  final bool isSessionOpen;
  final VoidCallback onCloseSession;

  @override
  State<_AttendanceTakingLoadedBody> createState() =>
      _AttendanceTakingLoadedBodyState();
}

class _AttendanceTakingLoadedBodyState
    extends State<_AttendanceTakingLoadedBody> {
  @override
  void initState() {
    super.initState();
    // FIX [008]: Start timer countdown when session data is first available. (T018)
    widget.timerCubit.start(widget.state.session.endsAt);
  }

  @override
  void didUpdateWidget(_AttendanceTakingLoadedBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.session.endsAt != widget.state.session.endsAt) {
      widget.timerCubit.start(widget.state.session.endsAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              AppInfoBanner(
                icon: widget.isSessionOpen ? Icons.schedule : Icons.lock_clock,
                message: widget.isSessionOpen
                    ? 'الجلسة مفتوحة الآن. يمكنك تحديد حاضر أو متأخر فقط.'
                    : 'الجلسة مغلقة الآن. أي مخدوم غير محدد يظهر كغائب تلقائيا.',
              ),
              AppSpacing.gapSm,
              AttendanceSessionHeader(session: state.session),
            ],
          ),
        ),
        // FIX [008]: Session expiry banner shown when ≤ 10 mins remain. (T018)
        const SessionExpiryBanner(),
        Expanded(
          child: state.roster.isEmpty
              ? const Center(child: Text('لا يوجد مخدومون ضمن هذه الجلسة.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: state.roster.length,
                  separatorBuilder: (context, index) => AppSpacing.gapSm,
                  itemBuilder: (context, index) {
                    final item = state.roster[index];
                    return AttendanceStudentRow(
                      item: item,
                      isSessionOpen: widget.isSessionOpen,
                      isMutating: state.isMutating,
                      onMarkPresent: () => widget.takingCubit.markPresent(
                        actor: widget.actor,
                        item: item,
                      ),
                      onMarkLate: () => widget.takingCubit.markLate(
                        actor: widget.actor,
                        item: item,
                      ),
                      onClear: () => widget.takingCubit.clearMark(
                        actor: widget.actor,
                        item: item,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
