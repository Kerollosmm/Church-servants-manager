# Phase 4 — Attendance Recording (Logic Only)

## Goal
Implement `AttendanceRecordModel`, fully wire `AttendanceTakingCubit` and `StudentAttendanceCubit` to their repository streams, inject both into `AppRouter`, and add Firestore security rules allowing students to read their own attendance marks.

## Existing Assets (keep, do not rewrite)
- `AttendanceRepository` — all mark methods + `watchSessionRosterSnapshot` + `watchStudentAttendanceHistory`
- `AttendanceMark`, `AttendanceRosterItem`, `AttendanceRosterSnapshot`, `StudentAttendanceHistoryItem` models
- Cubit folder structure: `attendance_taking/`, `student_attendance/`

## What Is Being Fixed / Implemented (Logic Only)

### 1. `AttendanceRecordModel`
- Currently an empty file
- A pure Dart `Equatable` model bridging `AttendanceMark` (Firestore model) and future local cache (Hive — deferred)
- Two factories: `fromAttendanceMark(…)` and `absent(…)`

### 2. `AttendanceTakingCubit` Wiring
- `initialize(teamId, sessionId)` subscribes to `watchSessionRosterSnapshot` and emits states
- `markPresent`, `markLate`, `clearMark`, `markAllPresent` delegate to repository
- Per-student mark-in-progress state emitted so the cubit tracks which tile is loading
- Subscription cancelled on `close()`
- Registered in `GetIt`

### 3. `StudentAttendanceCubit` Wiring  
- `load(studentId, {teamId})` subscribes to `watchStudentAttendanceHistory`
- Computes stats: `total`, `attended` (present + late), `percentage`
- States: Initial → Loading → Loaded(items, stats) → Error
- Registered in `GetIt` if missing

### 4. `AppRouter` — Cubit Injection
- `attendanceTaking` route: wrap with `BlocProvider<AttendanceTakingCubit>` + call `initialize()`
- `studentAttendance` route: wrap with `BlocProvider<StudentAttendanceCubit>` + call `load()`

### 5. Firestore Security Rules — Student Self-Attendance Read
- `isLinkedStudent(studentId)` helper reads `Users/{uid}.linkedStudentId`
- Student can read `attendanceMarks/{markId}` where `isLinkedStudent(markId) == true`
- Student can read session docs where their linked student ID is in `studentIdsSnapshot`
- Student still cannot write marks or session docs

## Files Changed (Logic Only)
| File | Change |
|------|--------|
| `lib/features/attendance_record/models/attendance_record_model.dart` | Implement model (was empty) |
| `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart` | Full implementation |
| `lib/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart` | Full implementation |
| `lib/core/di/injection.dart` | Register both cubits |
| `lib/core/routing/app_router.dart` | Wrap 2 routes with `BlocProvider` + cubit init |
| `firestore.rules` | Student self-read rules for marks + sessions |
| `test/features/attendance_record/` | Unit tests for `AttendanceRecordModel` |
| `test/features/attendance/bloc/` | Unit tests for both cubits |

## Completion Gate
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test test/features/attendance/` — all pass
- [ ] `flutter test test/features/attendance_record/` — all pass
