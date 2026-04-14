import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceMark.fromMap', () {
    test('handles missing optional fields gracefully', () {
      final data = <String, dynamic>{
        'studentNameSnapshot': 'Mina',
        'status': 'present',
        'markedByUserId': 'servant-1',
        'markedByName': 'Servant',
        'markedAt': Timestamp.fromDate(DateTime(2026, 3, 9, 18)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 9, 18)),
      };

      final mark = AttendanceMark.fromMap(data, 'student-1');

      expect(mark.studentId, 'student-1');
      expect(mark.studentUid, isNull);
      expect(mark.note, isNull);
      expect(mark.serverUpdatedAt, isNull);
      expect(mark.studentNameSnapshot, 'Mina');
      expect(mark.status, AttendanceMarkStatus.present);
    });

    test('parses studentUid when present', () {
      final data = <String, dynamic>{
        'studentNameSnapshot': 'Mina',
        'studentUid': 'auth-uid-123',
        'status': 'present',
        'markedByUserId': 'servant-1',
        'markedByName': 'Servant',
        'markedAt': Timestamp.fromDate(DateTime(2026, 3, 9, 18)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 9, 18)),
      };

      final mark = AttendanceMark.fromMap(data, 'student-1');

      expect(mark.studentUid, 'auth-uid-123');
    });
  });

  group('AttendanceMark.toMap', () {
    test('does NOT include studentId in the map body', () {
      final mark = AttendanceMark(
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        status: AttendanceMarkStatus.present,
        markedByUserId: 'servant-1',
        markedByName: 'Servant',
        markedAt: DateTime(2026, 3, 9, 18),
        updatedAt: DateTime(2026, 3, 9, 18),
      );

      final map = mark.toMap();

      expect(map.containsKey('studentId'), isFalse);
    });

    test('does NOT include serverUpdatedAt in the map body', () {
      final mark = AttendanceMark(
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        status: AttendanceMarkStatus.present,
        markedByUserId: 'servant-1',
        markedByName: 'Servant',
        markedAt: DateTime(2026, 3, 9, 18),
        updatedAt: DateTime(2026, 3, 9, 18),
        serverUpdatedAt: DateTime(2026, 3, 9, 18, 1),
      );

      final map = mark.toMap();

      expect(map.containsKey('serverUpdatedAt'), isFalse);
    });
  });

  group('DateTime serialization', () {
    test('clientUpdatedAt (markedAt) serializes/deserializes correctly', () {
      final now = DateTime(2026, 3, 9, 18, 30);
      final mark = AttendanceMark(
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        status: AttendanceMarkStatus.present,
        markedByUserId: 'servant-1',
        markedByName: 'Servant',
        markedAt: now,
        updatedAt: now,
      );

      final map = mark.toMap();
      // markedAt should be in the map (as Timestamp).
      expect(map['markedAt'], isA<Timestamp>());

      // Round-trip through fromMap.
      final restored = AttendanceMark.fromMap(map, 'student-1');
      expect(restored.markedAt.year, now.year);
      expect(restored.markedAt.month, now.month);
      expect(restored.markedAt.day, now.day);
    });

    test('serverUpdatedAt is nullable and preserved on read', () {
      final data = <String, dynamic>{
        'studentNameSnapshot': 'Mina',
        'status': 'present',
        'markedByUserId': 'servant-1',
        'markedByName': 'Servant',
        'markedAt': Timestamp.fromDate(DateTime(2026, 3, 9, 18)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 3, 9, 18)),
        'serverUpdatedAt': Timestamp.fromDate(DateTime(2026, 3, 9, 18, 1)),
      };

      final mark = AttendanceMark.fromMap(data, 'student-1');

      expect(mark.serverUpdatedAt, isNotNull);
      expect(mark.serverUpdatedAt!.minute, 1);
    });
  });

  group('isPresent computed getter', () {
    test('returns true for present status', () {
      final mark = AttendanceMark(
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        status: AttendanceMarkStatus.present,
        markedByUserId: 'servant-1',
        markedByName: 'Servant',
        markedAt: DateTime(2026, 3, 9, 18),
        updatedAt: DateTime(2026, 3, 9, 18),
      );

      expect(mark.isPresent, isTrue);
    });

    test('returns false for late status', () {
      final mark = AttendanceMark(
        studentId: 'student-1',
        studentNameSnapshot: 'Mina',
        status: AttendanceMarkStatus.late,
        markedByUserId: 'servant-1',
        markedByName: 'Servant',
        markedAt: DateTime(2026, 3, 9, 18),
        updatedAt: DateTime(2026, 3, 9, 18),
      );

      expect(mark.isPresent, isFalse);
    });
  });
}
