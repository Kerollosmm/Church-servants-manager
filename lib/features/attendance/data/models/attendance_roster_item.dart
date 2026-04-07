import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:equatable/equatable.dart';

class AttendanceRosterItem extends Equatable {
  const AttendanceRosterItem({
    required this.studentId,
    required this.studentName,
    required this.teamId,
    required this.sessionId,
    this.manualStatus,
    required this.effectiveStatus,
    required this.isMarked,
    this.markedAt,
    this.markedByName,
    required this.isSessionOpen,
    required this.canEdit,
    required this.sortOrder,
  });

  final String studentId;
  final String studentName;
  final String teamId;
  final String sessionId;
  final AttendanceMarkStatus? manualStatus;
  final AttendanceEffectiveStatus effectiveStatus;
  final bool isMarked;
  final DateTime? markedAt;
  final String? markedByName;
  final bool isSessionOpen;
  final bool canEdit;
  final int sortOrder;

  static AttendanceEffectiveStatus resolveEffectiveStatus({
    required AttendanceMarkStatus? manualStatus,
    required AttendanceSession session,
    required DateTime now,
  }) {
    if (manualStatus == AttendanceMarkStatus.present) {
      return AttendanceEffectiveStatus.present;
    }
    if (manualStatus == AttendanceMarkStatus.late) {
      return AttendanceEffectiveStatus.late;
    }
    if (session.isEffectivelyClosedAt(now)) {
      return AttendanceEffectiveStatus.absent;
    }
    return AttendanceEffectiveStatus.unmarked;
  }

  AttendanceRosterItem copyWith({
    String? studentId,
    String? studentName,
    String? teamId,
    String? sessionId,
    AttendanceMarkStatus? manualStatus,
    bool clearManualStatus = false,
    AttendanceEffectiveStatus? effectiveStatus,
    bool? isMarked,
    DateTime? markedAt,
    bool clearMarkedAt = false,
    String? markedByName,
    bool clearMarkedByName = false,
    bool? isSessionOpen,
    bool? canEdit,
    int? sortOrder,
  }) {
    return AttendanceRosterItem(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      teamId: teamId ?? this.teamId,
      sessionId: sessionId ?? this.sessionId,
      manualStatus: clearManualStatus
          ? null
          : (manualStatus ?? this.manualStatus),
      effectiveStatus: effectiveStatus ?? this.effectiveStatus,
      isMarked: isMarked ?? this.isMarked,
      markedAt: clearMarkedAt ? null : (markedAt ?? this.markedAt),
      markedByName: clearMarkedByName
          ? null
          : (markedByName ?? this.markedByName),
      isSessionOpen: isSessionOpen ?? this.isSessionOpen,
      canEdit: canEdit ?? this.canEdit,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    studentName,
    teamId,
    sessionId,
    manualStatus,
    effectiveStatus,
    isMarked,
    markedAt,
    markedByName,
    isSessionOpen,
    canEdit,
    sortOrder,
  ];
}
