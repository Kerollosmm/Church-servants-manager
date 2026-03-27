# Phase 4 — Attendance Recording (55% → 100%)

## Goal
Build the full `AttendanceTakingScreen` roster UI, implement the `AttendanceRecordModel` (local layer), wire the `AttendanceTakingCubit`, and add the student self-attendance view. Every mark action must be real-time, idempotent, and work correctly for all roster states.

## Existing Assets (keep, do not rewrite)
- `AttendanceRepository._writeMark()` — mark/update via `set(merge:true)` keyed by `studentId`
- `markStudentPresent`, `markStudentLate`, `clearStudentMark`, `markAllPresentForRemainingStudents`
- `watchSessionRosterSnapshot(teamId, sessionId)` → `Stream<AttendanceRosterSnapshot>`
- `watchStudentAttendanceHistory(studentId, teamId?)` → `Stream<List<StudentAttendanceHistoryItem>>`
- Roster item model: `AttendanceRosterItem` with `effectiveStatus`, `isMarked`, `canEdit`
- Bloc folders: `attendance_taking/`, `student_attendance/`

## What Is Missing / Broken
1. `AttendanceTakingScreen` — blank (`Text('AttendanceTakingScreen - Blanked')`)
2. `StudentAttendanceScreen` — blank
3. `AttendanceRecordModel` — empty file (1 blank line)
4. **Cubit wiring** — `AttendanceTakingCubit` exists in folder but needs connection to screen
5. **Bulk-fill UI** — "Mark All Present" button not surfaced

## Architecture Decisions
- `AttendanceTakingScreen` receives `AttendanceTakingArgs` (existing: `teamId`, `sessionId`)
- `BlocProvider<AttendanceTakingCubit>` wraps the screen (injected from `AppRouter`)
- Cubit calls `watchSessionRosterSnapshot` → emits `AttendanceRosterSnapshot`
- Roster list: `ListView.builder` over `AttendanceRosterSnapshot.roster`
- Each `AttendanceRosterTile` shows: name, status chip, mark/unmark/late buttons
- `canEdit` flag from roster item drives button visibility (false = session closed)
- **Bulk action**: FAB "تحديد الجميع حاضرين" → calls `markAllPresentForRemainingStudents`
- **Session header**: session title, team name, time range, open/closed badge, student count / marked count
- **Export/view-only mode**: when session `isEffectivelyClosed`, all mark buttons hidden

## AttendanceRecordModel (local layer)
This model is the local representation of a single attendance mark for offline/cache purposes. Fill the empty file with a minimal model first (Firestore-backed only; Hive extension deferred to Phase offline sprint).

## StudentAttendanceScreen
- Receives `StudentAttendanceArgs` (existing: `studentId`, optional `teamId`)
- Uses `StudentAttendanceCubit` → `watchStudentAttendanceHistory`
- Shows timeline list: session date, team name, status chip (present/late/absent)
- Stats header: total sessions attended / total sessions / percentage
- Student self-view: accessible to student role reading own UID

## Files to Create / Modify

### Attendance Record Model (fill empty file)
- `lib/features/attendance_record/models/attendance_record_model.dart`

### New Widgets (create)
- `lib/features/attendance/presentation/widgets/attendance_roster_tile.dart`
- `lib/features/attendance/presentation/widgets/attendance_mark_buttons.dart`
- `lib/features/attendance/presentation/widgets/attendance_status_chip.dart`
- `lib/features/attendance/presentation/widgets/session_header_card.dart`
- `lib/features/attendance/presentation/widgets/attendance_history_tile.dart` (for student view)

### Screens to Implement (replace blanks)
- `attendance_taking_screen.dart` — full roster with real-time marks
- `student_attendance_screen.dart` — student self-attendance history

### Cubit Wiring
- `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart` — wire to screen
- `lib/core/routing/app_router.dart` — wrap `AttendanceTakingScreen` with `BlocProvider<AttendanceTakingCubit>`

## UI Design Reference
- `UI Screens/attendance_taking/`
- `UI Screens/student_attendance_history/`

## Completion Gate
- [ ] `flutter analyze` passes
- [ ] `AttendanceTakingScreen` shows real roster, live mark updates
- [ ] Mark present / late / clear all work and persist
- [ ] Bulk "mark all present" works and skips already-marked
- [ ] Closed session shows view-only mode (no buttons)
- [ ] `StudentAttendanceScreen` shows history with stats header
- [ ] `flutter test test/features/attendance/` — all pass
