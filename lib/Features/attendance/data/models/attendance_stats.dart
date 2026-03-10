import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:equatable/equatable.dart';

class StudentAttendanceStats extends Equatable {
  const StudentAttendanceStats({
    required this.studentId,
    this.filterTeamId,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.totalSessions,
  });

  factory StudentAttendanceStats.fromHistory({
    required String studentId,
    String? filterTeamId,
    required List<StudentAttendanceHistoryItem> history,
  }) {
    var presentCount = 0;
    var lateCount = 0;
    var absentCount = 0;

    for (final item in history) {
      if (!item.isSessionClosed) continue;
      switch (item.effectiveStatus) {
        case AttendanceEffectiveStatus.present:
          presentCount += 1;
          break;
        case AttendanceEffectiveStatus.late:
          lateCount += 1;
          break;
        case AttendanceEffectiveStatus.absent:
          absentCount += 1;
          break;
        case AttendanceEffectiveStatus.unmarked:
          break;
      }
    }

    return StudentAttendanceStats(
      studentId: studentId,
      filterTeamId: filterTeamId,
      presentCount: presentCount,
      lateCount: lateCount,
      absentCount: absentCount,
      totalSessions: presentCount + lateCount + absentCount,
    );
  }

  final String studentId;
  final String? filterTeamId;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int totalSessions;

  int get attendedCount => presentCount + lateCount;

  double get attendancePercentage {
    if (totalSessions == 0) return 0.0;
    final percentage = attendedCount / totalSessions * 100;
    return percentage.clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
    studentId,
    filterTeamId,
    presentCount,
    lateCount,
    absentCount,
    totalSessions,
  ];
}

class TeamAttendanceStats extends Equatable {
  const TeamAttendanceStats({
    required this.teamId,
    required this.totalSessions,
    required this.uniqueStudentsCount,
    required this.totalRosterEntries,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  final String teamId;
  final int totalSessions;
  final int uniqueStudentsCount;
  final int totalRosterEntries;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  int get attendedCount => presentCount + lateCount;

  double get attendancePercentage {
    if (totalRosterEntries == 0) return 0.0;
    final percentage = attendedCount / totalRosterEntries * 100;
    return percentage.clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
    teamId,
    totalSessions,
    uniqueStudentsCount,
    totalRosterEntries,
    presentCount,
    lateCount,
    absentCount,
  ];
}
