import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/student_attendance_history_item.dart';

class StudentAttendanceStats {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAttendanceStats &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          presentCount == other.presentCount &&
          lateCount == other.lateCount &&
          absentCount == other.absentCount &&
          totalSessions == other.totalSessions;

  @override
  int get hashCode =>
      studentId.hashCode ^
      presentCount.hashCode ^
      lateCount.hashCode ^
      absentCount.hashCode ^
      totalSessions.hashCode;
}

class TeamAttendanceStats {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamAttendanceStats &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          totalSessions == other.totalSessions &&
          uniqueStudentsCount == other.uniqueStudentsCount &&
          totalRosterEntries == other.totalRosterEntries &&
          presentCount == other.presentCount &&
          lateCount == other.lateCount &&
          absentCount == other.absentCount;

  @override
  int get hashCode =>
      teamId.hashCode ^
      totalSessions.hashCode ^
      uniqueStudentsCount.hashCode ^
      totalRosterEntries.hashCode ^
      presentCount.hashCode ^
      lateCount.hashCode ^
      absentCount.hashCode;
}
