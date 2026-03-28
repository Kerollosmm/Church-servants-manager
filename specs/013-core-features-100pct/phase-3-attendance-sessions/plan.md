# Phase 3 — Attendance Sessions (Logic Only)

## Goal
Fix the 3 failing `attendance_repository_test.dart` cases, harden `_writeMark` idempotency, add unit tests for the servant/admin session lifecycle role policy, and strengthen Firestore security rules for attendance session access.

## Existing Assets (keep, do not rewrite)
- `AttendanceRepository` — full session lifecycle (`createSession`, `closeSession`, conflict detection, roster building)
- `AdminDashboardCubit` — session streams
- `AttendanceSession` model — `isOpenAt`, `isEffectivelyClosedAt`, `isClosed`
- Cubit folder: `lib/features/attendance/presentation/bloc/session_admin/`

## What Is Being Fixed (Logic Only)

### 1. 3 Failing Repository Tests
**Root causes** (from code inspection):
- **Idempotent mark**: mock `.get()` returns an empty snapshot on second call, so `existingMarkedAt` is always null → `markedAt` gets overwritten by `FieldValue.serverTimestamp()`
- **Late-status preservation**: same mock issue — `markedAt` from the first write is not returned on read, so updating status to `late` resets `markedAt`
- **Third case**: to be confirmed from test file

**Fix**: correct mock setup so `markRef.get()` returns a populated `DocumentSnapshot` with `markedAt` on second and subsequent calls.

### 2. `_writeMark` Correctness Verification
- Confirm the logic `existingMarkedAt ?? FieldValue.serverTimestamp()` is sound
- Add `// FIX [013-P3]` comment for traceability

### 3. Role Policy Unit Tests
- Servant can call `createSession()` → succeeds
- Servant calling `closeSession()` → throws `AttendancePermissionDeniedFailure`
- These behaviors already exist in repo logic; tests confirm them

### 4. Conflict Detection Coverage
- Unit tests for `_sessionsOverlap` and `_isDuplicateSessionCandidate` edge cases

### 5. Session Lifecycle Unit Tests
- `isEffectivelyClosedAt(now)` returns `true` for expired-and-open sessions
- `isEffectivelyClosedAt(now)` returns `true` for admin-closed-early sessions

### 6. Firestore Security Rules — Attendance
- Confirm servant can read/write `attendanceSessions` and `attendanceMarks` for their team
- Confirm student cannot write to either collection
- Add rule: only admin can update `isClosed: true` on a session doc

## Files Changed (Logic Only)
| File | Change |
|------|--------|
| `test/features/attendance/data/repos/attendance_repository_test.dart` | Fix 3 failing tests (mock correction) |
| `lib/features/attendance/data/repos/attendance_repository.dart` | `// FIX` comment; no logic change if already correct |
| `firestore.rules` | session close permission + servant/student boundaries |

## Servant/Admin Policy (documented)
| Action | Admin | Servant | Student |
|--------|-------|---------|---------|
| Create session | ✅ | ✅ | ❌ |
| Close session | ✅ | ❌ | ❌ |
| Write marks | ✅ | ✅ | ❌ |
| Read sessions | ✅ | ✅ | see Phase 4 |

## Completion Gate
- [ ] `flutter analyze` — 0 issues
- [ ] All 3 previously failing repo tests now pass
- [ ] `flutter test test/features/attendance/` — all pass
