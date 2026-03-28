import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:equatable/equatable.dart';

class AttendanceRecordModel extends Equatable {
  const AttendanceRecordModel({
    required this.studentId,
    required this.sessionId,
    required this.teamId,
    this.status,
    this.markedAt,
    this.markedByName,
    this.note,
  });

  // FIX [013-P4]: Bridge Firestore attendance marks into a local record model.
  factory AttendanceRecordModel.fromAttendanceMark(
    AttendanceMark mark, {
    required String sessionId,
    required String teamId,
  }) {
    return AttendanceRecordModel(
      studentId: mark.studentId,
      sessionId: sessionId,
      teamId: teamId,
      status: mark.status,
      markedAt: mark.markedAt,
      markedByName: mark.markedByName,
      note: mark.note,
    );
  }

  // FIX [013-P4]: Represent absent or unmarked students without a status value.
  factory AttendanceRecordModel.absent({
    required String studentId,
    required String sessionId,
    required String teamId,
  }) {
    return AttendanceRecordModel(
      studentId: studentId,
      sessionId: sessionId,
      teamId: teamId,
    );
  }

  final String studentId;
  final String sessionId;
  final String teamId;
  final AttendanceMarkStatus? status;
  final DateTime? markedAt;
  final String? markedByName;
  final String? note;

  @override
  List<Object?> get props => [
    studentId,
    sessionId,
    teamId,
    status,
    markedAt,
    markedByName,
    note,
  ];
}
