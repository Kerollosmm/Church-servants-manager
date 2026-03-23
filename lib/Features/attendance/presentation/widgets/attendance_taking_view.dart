import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_session_header.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_student_row.dart';
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
                : 'تسجيل الحضور';

            return Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: [
                  if (loadedState != null &&
                      loadedState.session.isOpenAt(DateTime.now()))
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
                AttendanceTakingLoaded() => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          AppInfoBanner(
                            icon: state.session.isOpenAt(DateTime.now())
                                ? Icons.schedule
                                : Icons.lock_clock,
                            message: state.session.isOpenAt(DateTime.now())
                                ? 'الجلسة مفتوحة الآن. يمكنك تحديد حاضر أو متأخر فقط.'
                                : 'الجلسة مغلقة الآن. أي مخدوم غير محدد يظهر كغائب تلقائيا.',
                          ),
                          AppSpacing.gapSm,
                          AttendanceSessionHeader(session: state.session),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state.roster.isEmpty
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
                                final item = state.roster[index];
                                final isOpen = state.session.isOpenAt(
                                  DateTime.now(),
                                );
                                return AttendanceStudentRow(
                                  item: item,
                                  isSessionOpen: isOpen,
                                  isMutating: state.isMutating,
                                  onMarkPresent: () => _takingCubit.markPresent(
                                    actor: widget.args.actor,
                                    item: item,
                                  ),
                                  onMarkLate: () => _takingCubit.markLate(
                                    actor: widget.args.actor,
                                    item: item,
                                  ),
                                  onClear: () => _takingCubit.clearMark(
                                    actor: widget.args.actor,
                                    item: item,
                                  ),
                                );
                              },
                              separatorBuilder: (_, _) => AppSpacing.gapSm,
                              itemCount: state.roster.length,
                            ),
                    ),
                  ],
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
