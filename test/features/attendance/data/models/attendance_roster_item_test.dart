import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AttendanceSession buildSession({
    required bool isClosed,
    required DateTime endsAt,
  }) {
    return AttendanceSession(
      id: 'session-1',
      teamId: 'team-1',
      dateKey: '2026-03-09',
      startsAt: DateTime(2026, 3, 9, 18),
      endsAt: endsAt,
      durationMinutes: 30,
      createdByUserId: 'admin-1',
      createdByName: 'Admin',
      createdAt: DateTime(2026, 3, 9, 17, 55),
      updatedAt: DateTime(2026, 3, 9, 17, 55),
      isClosed: isClosed,
    );
  }

  test('resolveEffectiveStatus maps present and late directly', () {
    final session = buildSession(
      isClosed: false,
      endsAt: DateTime(2026, 3, 9, 18, 30),
    );

    expect(
      AttendanceRosterItem.resolveEffectiveStatus(
        manualStatus: AttendanceMarkStatus.present,
        session: session,
        now: DateTime(2026, 3, 9, 18, 5),
      ),
      AttendanceEffectiveStatus.present,
    );
    expect(
      AttendanceRosterItem.resolveEffectiveStatus(
        manualStatus: AttendanceMarkStatus.late,
        session: session,
        now: DateTime(2026, 3, 9, 18, 35),
      ),
      AttendanceEffectiveStatus.late,
    );
  });

  test(
    'resolveEffectiveStatus derives unmarked while open and absent after close',
    () {
      final openSession = buildSession(
        isClosed: false,
        endsAt: DateTime(2026, 3, 9, 18, 30),
      );
      final closedSession = buildSession(
        isClosed: true,
        endsAt: DateTime(2026, 3, 9, 18, 30),
      );

      expect(
        AttendanceRosterItem.resolveEffectiveStatus(
          manualStatus: null,
          session: openSession,
          now: DateTime(2026, 3, 9, 18, 5),
        ),
        AttendanceEffectiveStatus.unmarked,
      );
      expect(
        AttendanceRosterItem.resolveEffectiveStatus(
          manualStatus: null,
          session: closedSession,
          now: DateTime(2026, 3, 9, 18, 5),
        ),
        AttendanceEffectiveStatus.absent,
      );
      expect(
        AttendanceRosterItem.resolveEffectiveStatus(
          manualStatus: null,
          session: openSession,
          now: DateTime(2026, 3, 9, 18, 45),
        ),
        AttendanceEffectiveStatus.absent,
      );
    },
  );
}
