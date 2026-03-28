import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance_record/models/attendance_record_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceRecordModel', () {
    test('fromAttendanceMark maps all mark fields', () {
      final markedAt = DateTime(2026, 3, 28, 10, 30);
      final mark = AttendanceMark(
        studentId: 'student-1',
        studentNameSnapshot: 'Mary',
        status: AttendanceMarkStatus.late,
        markedByUserId: 'servant-1',
        markedByName: 'Servant Mary',
        markedAt: markedAt,
        updatedAt: markedAt,
        note: 'Traffic',
      );

      final model = AttendanceRecordModel.fromAttendanceMark(
        mark,
        sessionId: 'session-1',
        teamId: 'team-1',
      );

      expect(
        model,
        AttendanceRecordModel(
          studentId: 'student-1',
          sessionId: 'session-1',
          teamId: 'team-1',
          status: AttendanceMarkStatus.late,
          markedAt: markedAt,
          markedByName: 'Servant Mary',
          note: 'Traffic',
        ),
      );
    });

    test('absent factory creates an unmarked record', () {
      final model = AttendanceRecordModel.absent(
        studentId: 'student-2',
        sessionId: 'session-2',
        teamId: 'team-2',
      );

      expect(model.studentId, 'student-2');
      expect(model.sessionId, 'session-2');
      expect(model.teamId, 'team-2');
      expect(model.status, isNull);
      expect(model.markedAt, isNull);
      expect(model.markedByName, isNull);
      expect(model.note, isNull);
    });
  });
}
