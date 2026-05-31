import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';

class AttendanceRosterSnapshot {
  const AttendanceRosterSnapshot({required this.session, required this.roster});

  final AttendanceSession session;
  final List<AttendanceRosterItem> roster;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRosterSnapshot &&
          runtimeType == other.runtimeType &&
          session == other.session;

  @override
  int get hashCode => session.hashCode ^ roster.hashCode;
}
