import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_empty_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/student_attendance_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentAttendanceView extends StatelessWidget {
  const StudentAttendanceView({super.key, required this.args});

  final StudentAttendanceArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentAttendanceCubit, StudentAttendanceState>(
      builder: (context, state) {
        return switch (state) {
          StudentAttendanceInitial() || StudentAttendanceLoading() =>
            const Center(child: CircularProgressIndicator()),
          StudentAttendanceError(:final message) => AttendanceEmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل سجل الطالب',
            message: message,
          ),
          StudentAttendanceLoaded() => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StudentAttendanceChart(
                percentage: state.stats.attendancePercentage,
                attended: state.stats.attendedCount,
                total: state.stats.totalSessions,
              ),
              const SizedBox(height: 12),
              if (state.history.isEmpty)
                const AttendanceEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'لا توجد بيانات حضور',
                  message: 'لم يتم العثور على جلسات حضور ضمن هذا النطاق.',
                )
              else
                ...state.history.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(
                        item.title?.trim().isNotEmpty == true
                            ? item.title!
                            : item.dateKey,
                      ),
                      subtitle: Text(item.teamNameSnapshot ?? item.teamId),
                      trailing: Chip(label: Text(item.effectiveStatus.name)),
                    ),
                  ),
                ),
            ],
          ),
        };
      },
    );
  }
}
