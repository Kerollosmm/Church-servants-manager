import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';

class AttendanceRosterItem {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRosterItem &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          studentName == other.studentName &&
          teamId == other.teamId &&
          sessionId == other.sessionId &&
          manualStatus == other.manualStatus &&
          effectiveStatus == other.effectiveStatus &&
          isMarked == other.isMarked &&
          markedAt == other.markedAt &&
          markedByName == other.markedByName &&
          isSessionOpen == other.isSessionOpen &&
          canEdit == other.canEdit &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      studentId.hashCode ^
      studentName.hashCode ^
      teamId.hashCode ^
      sessionId.hashCode ^
      manualStatus.hashCode ^
      effectiveStatus.hashCode ^
      isMarked.hashCode ^
      markedAt.hashCode ^
      markedByName.hashCode ^
      isSessionOpen.hashCode ^
      canEdit.hashCode ^
      sortOrder.hashCode;
}
