import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/student_attendance_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentAttendanceView extends StatefulWidget {
  const StudentAttendanceView({super.key, required this.args});

  final StudentAttendanceArgs args;

  @override
  State<StudentAttendanceView> createState() => _StudentAttendanceViewState();
}

class _StudentAttendanceViewState extends State<StudentAttendanceView> {
  late final StudentAttendanceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit =
        StudentAttendanceCubit(
          repository: context.read<IAttendanceRepository>(),
        )..loadForStudent(
          studentId: widget.args.studentId,
          teamId: widget.args.filterTeamId,
        );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentAttendanceCubit>.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text('سجل حضور ${widget.args.studentName}')),
        body: BlocBuilder<StudentAttendanceCubit, StudentAttendanceState>(
          builder: (context, state) {
            return switch (state) {
              StudentAttendanceLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              StudentAttendanceError() => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              ),
              StudentAttendanceLoaded() => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  StudentAttendanceChart(stats: state.stats),
                  AppSpacing.gapMd,
                  if (state.history.isEmpty)
                    const Center(child: Text('لا يوجد سجل حضور لهذا المخدوم.'))
                  else
                    ...state.history.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _StudentAttendanceHistoryCard(item: item),
                      ),
                    ),
                ],
              ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}

class _StudentAttendanceHistoryCard extends StatelessWidget {
  const _StudentAttendanceHistoryCard({required this.item});

  final StudentAttendanceHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.effectiveStatus);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Icon(Icons.history, color: statusColor),
        ),
        title: Text(
          item.title?.isNotEmpty == true
              ? item.title!
              : (item.teamNameSnapshot ?? 'جلسة حضور'),
        ),
        subtitle: Text(
          '${_formatDate(item.sessionStartsAt)} • ${item.markedByName ?? 'بدون تسجيل يدوي'}',
        ),
        trailing: Chip(
          label: Text(_statusLabel(item.effectiveStatus)),
          backgroundColor: statusColor.withValues(alpha: 0.14),
          labelStyle: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
