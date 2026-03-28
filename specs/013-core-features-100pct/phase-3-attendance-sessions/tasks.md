# Phase 3 — Attendance Sessions: Task Checklist (Logic Only)

> **Scope**: Repository bug fixes, cubit event handlers, role-policy enforcement in logic layer, security rules, and unit tests.
> No UI/widget code.

## P3-T1 · Fix 3 Failing Attendance Repository Tests
- [x] P3-T1.1 Open `test/features/attendance/data/repos/attendance_repository_test.dart`; read all 3 failing test descriptions
- [x] P3-T1.2 **Idempotent mark write**: fix mock so second call to `markDoc.get()` returns a snapshot with `markedAt` already set → `_writeMark` must preserve original `markedAt` on repeated calls
- [x] P3-T1.3 **Late-status preservation**: fix mock so updating status from `present` → `late` retains the original `markedAt` timestamp (not replace with `FieldValue.serverTimestamp()`)
- [x] P3-T1.4 **Third failing case**: read test, identify root cause, apply minimal fix
- [x] P3-T1.5 Run `flutter test test/features/attendance/data/repos/attendance_repository_test.dart` — all pass

## P3-T2 · Harden `_writeMark` Logic in Repository
- [x] P3-T2.1 Open `attendance_repository.dart` → `_writeMark()` method
- [x] P3-T2.2 Confirm `existingMarkedAt = existing.data()?['markedAt']` is read **before** any write
- [x] P3-T2.3 Confirm the `set()` call uses `existingMarkedAt ?? FieldValue.serverTimestamp()` — never overwrites
- [x] P3-T2.4 Add a `// FIX [013-P3]: preserve markedAt on idempotent re-mark` comment on the relevant line

## P3-T3 · Enforce Session Close Role Policy in Logic Layer
- [x] P3-T3.1 Confirm `closeSession()` calls `_assertAdmin(closedBy)` — already present; add unit test if missing
- [x] P3-T3.2 Confirm `createSession()` calls `assertUserCanManageAttendance()` which allows both admin and servant — add unit test asserting servant can create
- [x] P3-T3.3 Unit test: servant calling `closeSession()` throws `AttendancePermissionDeniedFailure`
- [x] P3-T3.4 Unit test: servant calling `createSession()` succeeds (no permission error)

## P3-T4 · Validate Conflict Detection Logic
- [x] P3-T4.1 Review `_sessionsOverlap()` and `_isDuplicateSessionCandidate()` in `attendance_repository.dart`
- [x] P3-T4.2 Unit test: two overlapping sessions (same team, same time window) → `AttendanceSessionConflictFailure`
- [x] P3-T4.3 Unit test: sessions on same day but non-overlapping times → no conflict

## P3-T5 · Session Lifecycle Logic — `isEffectivelyClosedAt` Coverage
- [x] P3-T5.1 Confirm `AttendanceSession.isEffectivelyClosedAt(now)` returns `true` for: `isClosed=true` OR `endsAt < now`
- [x] P3-T5.2 Unit test: an expired-but-not-closed session is effectively closed
- [x] P3-T5.3 Unit test: session closed early (before `endsAt`) is effectively closed

## P3-T6 · Firestore Security Rules — Attendance Session Access
- [x] P3-T6.1 Open `firestore.rules`
- [x] P3-T6.2 Confirm servant can read/write `attendanceSessions` and `attendanceMarks` for their assigned team
- [x] P3-T6.3 Confirm student **cannot** write to `attendanceSessions` or `attendanceMarks`
- [x] P3-T6.4 Confirm only admin can set `isClosed: true` on a session doc (rule-level enforcement)

## P3-T7 · Final Gate
- [x] `flutter analyze` — 0 issues
- [x] `flutter test test/features/attendance/` — all pass (including previously failing 3)
