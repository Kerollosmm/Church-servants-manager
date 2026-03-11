import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap tolerates missing fields and primitive drift', () {
    final session = AttendanceSession.fromMap({
      'teamId': 42,
      'durationMinutes': '45',
      'isClosed': 'false',
    }, 'session-1');

    expect(session.id, 'session-1');
    expect(session.teamId, '42');
    expect(session.durationMinutes, 45);
    expect(session.isClosed, isFalse);
    expect(session.studentIdsSnapshot, isEmpty);
  });

  test('fromMap parses timestamps and derives endsAt fallback', () {
    final startsAt = DateTime(2026, 3, 9, 18, 0);
    final session = AttendanceSession.fromMap({
      'teamId': 'team-1',
      'startsAt': Timestamp.fromDate(startsAt),
      'durationMinutes': 30,
      'isReopenedForAdminEdit': true,
      'reopenedByName': 'Admin',
    }, 'session-2');

    expect(session.startsAt, startsAt);
    expect(session.endsAt, startsAt.add(const Duration(minutes: 30)));
    expect(session.dateKey, '2026-03-09');
    expect(session.isReopenedForAdminEdit, isTrue);
    expect(session.reopenedByName, 'Admin');
  });

  test('isOpenAt and isEffectivelyClosedAt respect time and manual close', () {
    final session = AttendanceSession(
      id: 's1',
      teamId: 'team-1',
      dateKey: '2026-03-09',
      startsAt: DateTime(2026, 3, 9, 18, 0),
      endsAt: DateTime(2026, 3, 9, 18, 30),
      durationMinutes: 30,
      createdByUserId: 'admin-1',
      createdByName: 'Admin',
      createdAt: DateTime(2026, 3, 9, 17, 55),
      updatedAt: DateTime(2026, 3, 9, 17, 55),
    );

    expect(session.isOpenAt(DateTime(2026, 3, 9, 18, 10)), isTrue);
    expect(session.isEffectivelyClosedAt(DateTime(2026, 3, 9, 18, 10)), isFalse);
    expect(session.isOpenAt(DateTime(2026, 3, 9, 18, 30)), isFalse);
    expect(
      session.isEffectivelyClosedAt(DateTime(2026, 3, 9, 18, 30)),
      isTrue,
    );
    expect(session.copyWith(isClosed: true).isOpenAt(DateTime(2026, 3, 9, 18, 10)), isFalse);
  });

  test('canRoleEdit allows admin correction on reopened sessions', () {
    final session = AttendanceSession(
      id: 's1',
      teamId: 'team-1',
      dateKey: '2026-03-09',
      startsAt: DateTime(2026, 3, 9, 18, 0),
      endsAt: DateTime(2026, 3, 9, 18, 30),
      durationMinutes: 30,
      createdByUserId: 'admin-1',
      createdByName: 'Admin',
      createdAt: DateTime(2026, 3, 9, 17, 55),
      updatedAt: DateTime(2026, 3, 9, 17, 55),
      isClosed: true,
      isReopenedForAdminEdit: true,
    );

    expect(
      session.canRoleEdit(
        role: UserRole.admin,
        now: DateTime(2026, 3, 10, 8, 0),
      ),
      isTrue,
    );
    expect(
      session.canRoleEdit(
        role: UserRole.servant,
        now: DateTime(2026, 3, 10, 8, 0),
      ),
      isFalse,
    );
  });
}
