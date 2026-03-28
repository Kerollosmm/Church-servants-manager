# Phase 4 — Attendance Recording: Task Checklist (Logic Only)

> **Scope**: `AttendanceRecordModel`, cubit wiring, mark logic, student attendance cubit, security rules for student self-read, and unit tests.
> No UI/widget code.

## P4-T1 · Implement `AttendanceRecordModel`
- [X] P4-T1.1 Fill `lib/features/attendance_record/models/attendance_record_model.dart` with a pure Dart model:
  ```dart
  class AttendanceRecordModel extends Equatable {
    final String studentId;
    final String sessionId;
    final String teamId;
    final AttendanceMarkStatus? status;   // null = absent/unmarked
    final DateTime? markedAt;
    final String? markedByName;
    final String? note;
  }
  ```
- [X] P4-T1.2 Factory: `AttendanceRecordModel.fromAttendanceMark(AttendanceMark mark, {required String sessionId, required String teamId})`
- [X] P4-T1.3 Factory: `AttendanceRecordModel.absent({required String studentId, required String sessionId, required String teamId})`
- [X] P4-T1.4 Implement `Equatable.props`
- [X] P4-T1.5 Unit test: `fromAttendanceMark` maps all fields; `absent` factory produces null `status`

## P4-T2 · Wire `AttendanceTakingCubit`
- [X] P4-T2.1 Open `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`
- [X] P4-T2.2 Implement `initialize(String teamId, String sessionId)`:
  - Subscribe to `repository.watchSessionRosterSnapshot(teamId:, sessionId:)`
  - Emit loaded state with `AttendanceRosterSnapshot`
  - Cancel subscription on `close()`
- [X] P4-T2.3 Implement `markPresent(String studentId, String studentNameSnapshot)` → calls `repository.markStudentPresent(…, markedBy: currentUser)`
- [X] P4-T2.4 Implement `markLate(String studentId, String studentNameSnapshot)` → calls `repository.markStudentLate(…)`
- [X] P4-T2.5 Implement `clearMark(String studentId)` → calls `repository.clearStudentMark(…)`
- [X] P4-T2.6 Implement `markAllPresent()` → calls `repository.markAllPresentForRemainingStudents(…)` with confirm guard
- [X] P4-T2.7 States: `AttendanceTakingInitial`, `AttendanceTakingLoading`, `AttendanceTakingLoaded(AttendanceRosterSnapshot)`, `AttendanceTakingError(String)`, `AttendanceTakingMarkInProgress(String studentId)`
- [X] P4-T2.8 Register `AttendanceTakingCubit` in `GetIt` via `injection.dart`
- [X] P4-T2.9 Unit test: `initialize()` streams roster; `markPresent()` calls repo with correct args

## P4-T3 · Wire `StudentAttendanceCubit`
- [X] P4-T3.1 Open `lib/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart`
- [X] P4-T3.2 Implement `load(String studentId, {String? teamId})`:
  - Subscribe to `repository.watchStudentAttendanceHistory(studentId:, teamId:)`
  - Compute stats: `total`, `attended` (present + late count), `percentage`
  - Emit loaded state with history list + stats
- [X] P4-T3.3 States: `StudentAttendanceInitial`, `StudentAttendanceLoading`, `StudentAttendanceLoaded({items, total, attended, percentage})`, `StudentAttendanceError(String)`
- [X] P4-T3.4 Register in `GetIt` if not already
- [X] P4-T3.5 Unit test: `load()` computes percentage correctly for mixed present/late/absent history

## P4-T4 · Update `AppRouter` — Cubit Injection for Attendance Routes
- [X] P4-T4.1 Wrap `attendanceTaking` route with `BlocProvider<AttendanceTakingCubit>(create: (_) => getIt<AttendanceTakingCubit>()..initialize(args.teamId, args.sessionId))`
- [X] P4-T4.2 Wrap `studentAttendance` route with `BlocProvider<StudentAttendanceCubit>(create: (_) => getIt<StudentAttendanceCubit>()..load(args.studentId, teamId: args.teamId))`
- [X] P4-T4.3 Run `flutter analyze` — 0 issues

## P4-T5 · Firestore Security Rules — Student Self-Attendance Read
- [X] P4-T5.1 Add `isLinkedStudent(studentId)` helper in `firestore.rules`:
  ```javascript
  function isLinkedStudent(studentId) {
    return get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.linkedStudentId == studentId;
  }
  ```
- [X] P4-T5.2 Allow student to read their own mark: `attendanceMarks/{markId}` where `isLinkedStudent(markId)`
- [X] P4-T5.3 Allow student to read session docs where `request.auth.uid` maps to a student in `studentIdsSnapshot` (via `isLinkedStudent` cross-check)
- [X] P4-T5.4 Confirm student **cannot** read other students' marks

## P4-T6 · Final Gate
- [X] `flutter analyze` — 0 issues
- [X] `flutter test test/features/attendance/` — all pass
- [X] `flutter test test/features/attendance_record/` — all pass (new model tests)
