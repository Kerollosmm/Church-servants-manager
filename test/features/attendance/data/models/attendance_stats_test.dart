import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_stats.dart';
import 'package:church_management_system/features/attendance/domain/entities/student_attendance_history_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'StudentAttendanceStats counts only completed sessions and late as attended',
    () {
      final stats = StudentAttendanceStats.fromHistory(
        studentId: 'student-1',
        history: [
          StudentAttendanceHistoryItem(
            sessionId: '1',
            teamId: 'team-1',
            teamNameSnapshot: 'Team',
            title: null,
            dateKey: '2026-03-09',
            sessionStartsAt: DateTime(2026, 3, 9, 18),
            sessionEndsAt: DateTime(2026, 3, 9, 18, 30),
            effectiveStatus: AttendanceEffectiveStatus.present,
            isSessionClosed: true,
          ),
          StudentAttendanceHistoryItem(
            sessionId: '2',
            teamId: 'team-1',
            teamNameSnapshot: 'Team',
            title: null,
            dateKey: '2026-03-10',
            sessionStartsAt: DateTime(2026, 3, 10, 18),
            sessionEndsAt: DateTime(2026, 3, 10, 18, 30),
            effectiveStatus: AttendanceEffectiveStatus.late,
            isSessionClosed: true,
          ),
          StudentAttendanceHistoryItem(
            sessionId: '3',
            teamId: 'team-1',
            teamNameSnapshot: 'Team',
            title: null,
            dateKey: '2026-03-11',
            sessionStartsAt: DateTime(2026, 3, 11, 18),
            sessionEndsAt: DateTime(2026, 3, 11, 18, 30),
            effectiveStatus: AttendanceEffectiveStatus.absent,
            isSessionClosed: true,
          ),
          StudentAttendanceHistoryItem(
            sessionId: '4',
            teamId: 'team-1',
            teamNameSnapshot: 'Team',
            title: null,
            dateKey: '2026-03-12',
            sessionStartsAt: DateTime(2026, 3, 12, 18),
            sessionEndsAt: DateTime(2026, 3, 12, 18, 30),
            effectiveStatus: AttendanceEffectiveStatus.unmarked,
            isSessionClosed: false,
          ),
        ],
      );

      expect(stats.presentCount, 1);
      expect(stats.lateCount, 1);
      expect(stats.absentCount, 1);
      expect(stats.totalSessions, 3);
      expect(stats.attendedCount, 2);
      expect(stats.attendancePercentage, closeTo(66.7, 0.1));
    },
  );
}
