# Phase 4 — Attendance Recording: Task Checklist

## P4-T1 · Implement AttendanceRecordModel
- [ ] P4-T1.1 Fill `lib/features/attendance_record/models/attendance_record_model.dart`
  - Fields: `studentId`, `sessionId`, `teamId`, `status?`, `markedAt?`, `markedByName?`, `note?`
  - Factory: `AttendanceRecordModel.fromAttendanceMark(mark, {sessionId, teamId})`
  - Factory: `AttendanceRecordModel.absent({studentId, sessionId, teamId})`
  - `equatable` for value equality
- [ ] P4-T1.2 Unit test: `fromAttendanceMark` maps fields correctly; `absent` factory sets null status

## P4-T2 · Wire AttendanceTakingCubit
- [ ] P4-T2.1 Open `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`
- [ ] P4-T2.2 Ensure it subscribes to `watchSessionRosterSnapshot(teamId, sessionId)` in `initialize(teamId, sessionId)`
- [ ] P4-T2.3 Expose methods: `markPresent(studentId, name)`, `markLate(studentId, name)`, `clearMark(studentId)`, `markAllPresent()`
- [ ] P4-T2.4 Register in `GetIt` (check `injection.dart`; add if missing)
- [ ] P4-T2.5 Update `AppRouter` — wrap `AttendanceTakingScreen` route with `BlocProvider<AttendanceTakingCubit>`

## P4-T3 · Attendance Widget Atoms
- [ ] P4-T3.1 Create `attendance_status_chip.dart`
  - Input: `EffectiveAttendanceStatus`
  - Colors: present=green, late=orange, absent=red, unknown=grey
- [ ] P4-T3.2 Create `attendance_mark_buttons.dart`
  - Shows "حاضر" / "متأخر" / "مسح" buttons based on current `manualStatus`
  - Hidden entirely when `canEdit == false`
  - Loading state per button (tracks loading studentId in cubit)
- [ ] P4-T3.3 Create `attendance_roster_tile.dart`
  - `sortOrder`-based ordering (use `sortOrder` from `AttendanceRosterItem`)
  - Left: student name + status chip
  - Right: `AttendanceMarkButtons` (or nothing if !canEdit)
  - Note icon if `note != null`
- [ ] P4-T3.4 Create `session_header_card.dart`
  - Session title, team name, time range, duration
  - Open/closed badge (`SessionStatusBadge` from Phase 3)
  - Marked count: "X / Y مخدوم"
- [ ] P4-T3.5 Create `attendance_history_tile.dart`
  - Session date, team name, `AttendanceStatusChip`
  - Tap → push `attendanceTaking` (view-only)

## P4-T4 · Implement AttendanceTakingScreen
- [ ] P4-T4.1 `BlocProvider<AttendanceTakingCubit>` + call `initialize(args.teamId, args.sessionId)` on creation
- [ ] P4-T4.2 `SessionHeaderCard` at top
- [ ] P4-T4.3 `BlocBuilder` states:
  - loading → shimmer list
  - error → error + retry
  - loaded → `ListView.builder` with `AttendanceRosterTile` items using `ValueKey(item.studentId)`
- [ ] P4-T4.4 FAB "تحديد الجميع حاضرين":
  - Visible only when session open AND unmarked count > 0
  - Confirm dialog → call `markAllPresent()`
- [ ] P4-T4.5 Mark button taps → call cubit method + show per-tile loading
- [ ] P4-T4.6 View-only header when `!session.isOpenAt(now)` (no FAB, no buttons)
- [ ] P4-T4.7 Widget test: roster renders 3 students; mark present updates status chip

## P4-T5 · Implement StudentAttendanceScreen
- [ ] P4-T5.1 `BlocProvider<StudentAttendanceCubit>` — call `load(args.studentId, teamId: args.teamId)`
- [ ] P4-T5.2 Stats header card: total / attended / percentage
- [ ] P4-T5.3 `BlocBuilder` → loaded: `ListView` of `AttendanceHistoryTile` items sorted by date desc
- [ ] P4-T5.4 `BlocBuilder` → loading / empty / error states
- [ ] P4-T5.5 Widget test: stats header shows correct percentage

## P4-T6 · Firestore Security Rules — Student Self-Attendance Read
- [ ] P4-T6.1 Open `firestore.rules`
- [ ] P4-T6.2 Add rule allowing student to read attendance marks where doc ID == their studentId:
  ```javascript
  match /Classes/{teamId}/attendanceSessions/{sessionId}/attendanceMarks/{markId} {
    allow read: if request.auth.uid != null
                 && (isAdmin() || isServant()
                     || isLinkedStudent(markId));
  }
  ```
- [ ] P4-T6.3 Add `isLinkedStudent(studentId)` helper function using `Users/{uid}/linkedStudentId` field
- [ ] P4-T6.4 Allow student to read session docs where their UID is in `studentIdsSnapshot`

## P4-T7 · Final Gate
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test test/features/attendance/` — all pass
- [ ] Manual smoke: servant marks student present → status chip updates in real-time on second device
- [ ] Bulk mark → 0 skips for already-marked, confirms with server
- [ ] Student logs in → sees own attendance history with stats
- [ ] Closed session → view-only mode, no buttons
