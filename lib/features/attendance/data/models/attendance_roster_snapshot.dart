import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:equatable/equatable.dart';

class AttendanceRosterSnapshot extends Equatable {
  const AttendanceRosterSnapshot({required this.session, required this.roster});

  final AttendanceSession session;
  final List<AttendanceRosterItem> roster;

  @override
  List<Object?> get props => [session, roster];
}
