import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap uses document id as studentId and defaults unknown status', () {
    final mark = AttendanceMark.fromMap({
      'studentNameSnapshot': 'Mina',
      'status': 'unknown',
      'markedByUserId': 'servant-1',
      'markedByName': 'Servant',
    }, 'student-1');

    expect(mark.studentId, 'student-1');
    expect(mark.studentNameSnapshot, 'Mina');
    expect(mark.status, AttendanceMarkStatus.present);
  });

  test('toMap omits studentId because document id is authoritative', () {
    final mark = AttendanceMark(
      studentId: 'student-1',
      studentNameSnapshot: 'Mina',
      status: AttendanceMarkStatus.late,
      markedByUserId: 'servant-1',
      markedByName: 'Servant',
      markedAt: DateTime(2026, 3, 9, 18),
      updatedAt: DateTime(2026, 3, 9, 18, 5),
    );

    expect(mark.toMap().containsKey('studentId'), isFalse);
  });
}
