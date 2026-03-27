# Phase 4 — Attendance Recording: Data Model

## AttendanceMark (existing — reference only)
```
AttendanceMark {
  id: String              // == studentId (document ID in marks subcollection)
  studentNameSnapshot: String
  status: AttendanceMarkStatus   // present | late
  markedByUserId: String
  markedByName: String
  markedAt: DateTime             // set once on first write, never overwritten
  updatedAt: DateTime
  note: String?
}
```

## AttendanceMarkStatus (existing enum)
```
enum AttendanceMarkStatus { present, late }
```

## AttendanceRosterItem (existing — reference only)
```
AttendanceRosterItem {
  studentId: String
  studentName: String
  teamId: String
  sessionId: String
  manualStatus: AttendanceMarkStatus?   // null = not yet marked
  effectiveStatus: EffectiveAttendanceStatus
  isMarked: bool
  markedAt: DateTime?
  markedByName: String?
  isSessionOpen: bool
  canEdit: bool           // false when session is closed/expired
  sortOrder: int
}
```

## EffectiveAttendanceStatus (existing enum)
```
enum EffectiveAttendanceStatus { present | late | absent | unknown }
```
- `unknown` = session not yet started

## AttendanceRecordModel (LOCAL — implement this)
```dart
// lib/features/attendance_record/models/attendance_record_model.dart
// Lightweight local representation (Firestore-backed; Hive deferred)
class AttendanceRecordModel {
  final String studentId;
  final String sessionId;
  final String teamId;
  final AttendanceMarkStatus? status;   // null = absent/unmarked
  final DateTime? markedAt;
  final String? markedByName;
  final String? note;

  const AttendanceRecordModel({...});

  factory AttendanceRecordModel.fromAttendanceMark(
    AttendanceMark mark, {
    required String sessionId,
    required String teamId,
  });

  factory AttendanceRecordModel.absent({
    required String studentId,
    required String sessionId,
    required String teamId,
  });
}
```

## StudentAttendanceHistoryItem (existing — reference only)
```
StudentAttendanceHistoryItem {
  session: AttendanceSession
  mark: AttendanceMark?   // null = absent
  effectiveStatus: EffectiveAttendanceStatus
}
```

## AttendanceTakingArgs (existing RouteArgs)
```
AttendanceTakingArgs {
  teamId: String
  sessionId: String
}
```

## StudentAttendanceArgs (existing RouteArgs)
```
StudentAttendanceArgs {
  studentId: String
  teamId: String?
}
```

## Firestore Path (marks)
`Classes/{teamId}/attendanceSessions/{sessionId}/attendanceMarks/{studentId}`
