# Phase 3 — Attendance Sessions (60% → 100%)

## Goal
Rebuild session create, session history, and session management screens on top of the existing `AttendanceRepository` and `AdminDashboardCubit`/`SessionAdminCubit` stack. Decide and implement the servant-vs-admin create/close lifecycle policy. Fix the 3 failing `attendance_repository_test.dart` cases.

## Existing Assets (keep, do not rewrite)
- `AttendanceRepository` — full session lifecycle: `createSession`, `closeSession`, `watchSessionsForTeam`, `watchActiveSessionForTeam`, `watchSessionById`, `getSessionById`
- `AdminDashboardCubit` — session/dashboard streams
- Session cubit folder: `lib/features/attendance/presentation/bloc/session_admin/`
- `AttendanceSession` model — full, including `isOpenAt()`, `isClosed`, `isEffectivelyClosedAt()`
- Conflict-detection logic in repository

## What Is Missing / Broken
1. `AttendanceSessionCreateScreen` — blank
2. `AttendanceHistoryScreen` — blank
3. **Role policy gap** — `createSession` checks `assertUserCanManageAttendance` (servant + admin can create), but `closeSession` calls `_assertAdmin` (admin only). Need explicit documented decision and UI enforcement.
4. 3 failing repo tests (idempotent mark, late-status preservation cases — in `attendance_repository_test.dart`)

## Role Policy Decision (HUMAN DECISION REQUIRED — resolved here)
**Decision**: Servants can **create** sessions only. Only **admins** can **close** sessions.  
**Rationale**: Matches the closed-roster safety model — a servant opens taking, admin reviews and closes to lock marks.  
**UI Enforcement**: "Close Session" button only shown when `user.role == admin`.

## Architecture Decisions
- `AttendanceSessionCreateScreen`:
  - Cubit: `SessionAdminCubit` (existing) — call `createSession`
  - Fields: team (dropdown), date+time picker, duration (minutes), optional title
  - After success → pop + show snack; router pushes to `attendanceTaking`
- `AttendanceHistoryScreen`:
  - Uses `watchSessionsForTeam(teamId)` stream
  - Grouped by date key (`session.dateKey`)
  - Tapping a session → push `attendanceTaking` (view-only if closed)
  - Admin: "Close" action on open sessions
- Session list tile shows: title/date, open/closed badge, student count, created-by

## Files to Create / Modify

### New Widgets (create)
- `lib/features/attendance/presentation/widgets/session_list_tile.dart`
- `lib/features/attendance/presentation/widgets/session_status_badge.dart`
- `lib/features/attendance/presentation/widgets/session_create_form.dart`
- `lib/features/attendance/presentation/widgets/session_date_group_header.dart`

### Screens to Implement
- `attendance_session_create_screen.dart` — create form + cubit wiring
- `attendance_history_screen.dart` — date-grouped list + close action for admins

### Test Fixes
- `test/features/attendance/data/repos/attendance_repository_test.dart` — fix 3 failing cases:
  1. Idempotent mark write (second identical `markStudentPresent` must not throw, must preserve `markedAt`)
  2. Late-status preservation (marking late must not overwrite `markedAt` from a prior present mark)
  3. (Third case — assess from test file)

## UI Design Reference
- `UI Screens/create_attendance_session/`
- `UI Screens/attendance_history/`

## Completion Gate
- [ ] `flutter analyze` passes
- [ ] Session create works end-to-end: team selected → session appears in history
- [ ] History screen shows sessions grouped by date, open/closed status
- [ ] Servant sees "Close" button hidden; admin sees it
- [ ] 3 failing repo tests fixed and green
- [ ] `flutter test test/features/attendance/` passes
