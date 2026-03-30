import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_empty_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_session_header.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_stats_header.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_student_row.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/session_expiry_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceTakingView extends StatelessWidget {
  const AttendanceTakingView({super.key, required this.args});

  final AttendanceTakingArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      AttendanceSessionAdminCubit,
      AttendanceSessionAdminState
    >(
      listener: (context, state) {
        if (state is AttendanceSessionAdminSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is AttendanceSessionAdminError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<AttendanceTakingCubit, AttendanceTakingState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('تسجيل الحضور'),
              actions: [
                if (state is AttendanceTakingLoaded &&
                    args.actor.role == UserRole.admin &&
                    !state.session.isClosed)
                  IconButton(
                    tooltip: 'إغلاق الجلسة',
                    onPressed: () {
                      context.read<AttendanceSessionAdminCubit>().closeSession(
                        actor: args.actor,
                        teamId: state.session.teamId,
                        sessionId: state.session.id,
                      );
                    },
                    icon: const Icon(Icons.lock_clock_outlined),
                  ),
              ],
            ),
            body: switch (state) {
              AttendanceTakingInitial() || AttendanceTakingLoading() =>
                const Center(child: CircularProgressIndicator()),
              AttendanceTakingError(:final message) => AttendanceEmptyState(
                icon: Icons.error_outline,
                title: 'تعذر تحميل الجلسة',
                message: message,
              ),
              AttendanceTakingLoaded() => _AttendanceTakingLoadedBody(
                state: state,
                args: args,
              ),
            },
          );
        },
      ),
    );
  }
}

class _AttendanceTakingLoadedBody extends StatelessWidget {
  const _AttendanceTakingLoadedBody({required this.state, required this.args});

  final AttendanceTakingLoaded state;
  final AttendanceTakingArgs args;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AttendanceSessionHeader(session: state.session),
        const SizedBox(height: 12),
        SessionExpiryBanner(
          isSessionOpen: state.session.isOpenAt(DateTime.now()),
          isClosed: state.session.isClosed,
        ),
        const SizedBox(height: 12),
        AttendanceStatsHeader(roster: state.roster),
        if (state.mutationError?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(
            state.mutationError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: state.isMutating || state.session.isClosed
                ? null
                : () => context.read<AttendanceTakingCubit>().markAllPresent(
                    actor: args.actor,
                  ),
            icon: const Icon(Icons.done_all),
            label: const Text('تحديد الباقي حاضر'),
          ),
        ),
        const SizedBox(height: 12),
        if (state.roster.isEmpty)
          const AttendanceEmptyState(
            icon: Icons.group_off_outlined,
            title: 'لا يوجد مخدومون في هذه الجلسة',
            message:
                'تحقق من أعضاء الفريق أو أنشئ جلسة جديدة بعد تحديث الفريق.',
          )
        else
          ...state.roster.map(
            (item) => AttendanceStudentRow(
              item: item,
              isBusy: false,
              onPresent: () => context
                  .read<AttendanceTakingCubit>()
                  .markPresent(actor: args.actor, item: item),
              onLate: () => context.read<AttendanceTakingCubit>().markLate(
                actor: args.actor,
                item: item,
              ),
              onClear: () => context.read<AttendanceTakingCubit>().clearMark(
                actor: args.actor,
                item: item,
              ),
              onOpenHistory: () {
                Navigator.of(context).pushNamed(
                  studentAttendance,
                  arguments: StudentAttendanceArgs(
                    actor: args.actor,
                    studentId: item.studentId,
                    studentName: item.studentName,
                    filterTeamId: item.teamId,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
