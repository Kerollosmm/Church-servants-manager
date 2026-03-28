import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:equatable/equatable.dart';

sealed class StudentAttendanceState extends Equatable {
  const StudentAttendanceState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class StudentAttendanceInitial extends StudentAttendanceState {
  const StudentAttendanceInitial();
}

final class StudentAttendanceLoading extends StudentAttendanceState {
  const StudentAttendanceLoading();
}

final class StudentAttendanceLoaded extends StudentAttendanceState {
  const StudentAttendanceLoaded({required this.history, required this.stats});

  final List<StudentAttendanceHistoryItem> history;
  final StudentAttendanceStats stats;

  // FIX [013-P4]: Expose phase-4 summary values directly from the loaded state.
  List<StudentAttendanceHistoryItem> get items => history;
  int get total => stats.totalSessions;
  int get attended => stats.attendedCount;
  double get percentage => stats.attendancePercentage;

  @override
  List<Object?> get props => [history, stats];
}

final class StudentAttendanceError extends StudentAttendanceState {
  const StudentAttendanceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
