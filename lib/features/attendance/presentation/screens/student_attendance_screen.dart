import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key, required this.args});

  final StudentAttendanceArgs args;

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  late final StudentAttendanceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = StudentAttendanceCubit(repository: getIt<AttendanceRepository>())
      ..loadForStudent(
        studentId: widget.args.studentId,
        teamId: widget.args.filterTeamId,
      );
  }

  @override
  void dispose() {
    _cubit.close();
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إحصاءات الجلسات المكتملة',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.gapMd,
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              _StatTile(
                                label: 'نسبة الحضور',
                                value:
                                    '${state.stats.attendancePercentage.toStringAsFixed(1)}%',
                              ),
                              _StatTile(
                                label: 'حاضر',
                                value: '${state.stats.presentCount}',
                              ),
                              _StatTile(
                                label: 'متأخر',
                                value: '${state.stats.lateCount}',
                              ),
                              _StatTile(
                                label: 'غائب',
                                value: '${state.stats.absentCount}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,
                  if (state.history.isEmpty)
                    const Center(child: Text('لا يوجد سجل حضور لهذا المخدوم.'))
                  else
                    ...state.history.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(
                                item.effectiveStatus,
                              ).withValues(alpha: 0.14),
                              child: Icon(
                                Icons.history,
                                color: _statusColor(item.effectiveStatus),
                              ),
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
                              backgroundColor: _statusColor(
                                item.effectiveStatus,
                              ).withValues(alpha: 0.14),
                              labelStyle: TextStyle(
                                color: _statusColor(item.effectiveStatus),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.gapXs,
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
