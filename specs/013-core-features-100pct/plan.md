# 013 — Core Features to 100% (Logic Only)

## Objective
Bring the logic, data, and backend layers of **Authentication & Roles**, **Student Management**, **Attendance Sessions**, and **Attendance Recording** to production-ready correctness. No UI/widget code is included in this plan.

## What This Plan Covers
- BLoC/Cubit event handlers and state correctness
- Repository data-layer bugs (search, pagination, idempotent writes)
- Firestore collection casing alignment across app, rules, and Cloud Functions
- Role-policy enforcement in logic (not just UI conditionals)
- Security rules for admin/servant/student boundaries
- New model implementations (`AttendanceRecordModel`, `StudentProfileCubit`, `AttendanceTakingCubit`, `StudentAttendanceCubit`)
- Unit test fixes (3 failing repo tests, 2 stale router tests)

## Constitution Alignment
- Business logic ONLY in Cubits/Blocs — no exceptions
- Firestore access ONLY through Repository layer
- All state/model classes immutable (equatable or freezed)
- All deps via GetIt — no inline construction
- Every fix tagged `// FIX [013-Px]: reason`

## Phase Overview

| # | Phase | Focus | Est. Hours | Spec Folder |
|---|-------|-------|----------:|-------------|
| 1 | Authentication & Roles | Casing fix, AdminGate guard, AuthBloc hardening, stale file/test cleanup | 6h | `phase-1-auth-roles/` |
| 2 | Student Management | Server-side search, pagination cursor, StudentProfileCubit, self-read rule | 8h | `phase-2-student-management/` |
| 3 | Attendance Sessions | 3 failing repo tests, `_writeMark` idempotency, role-policy tests, session lifecycle tests | 6h | `phase-3-attendance-sessions/` |
| 4 | Attendance Recording | `AttendanceRecordModel`, cubit wiring, AppRouter injection, student self-read rules | 8h | `phase-4-attendance-recording/` |

**Total**: ~28 hours

## Execution Order
Phase 1 → 2 → 3 → 4. Auth casing fix in Phase 1 unblocks all Firestore reads in later phases.

## Completion Gate (all phases)
1. `flutter analyze` returns 0 issues.
2. `flutter test` suite passes with no failures or timeouts.
3. No raw Firestore string literals; all paths go through `FirestoreCollections` constants.
4. All new/changed code has corresponding unit tests.
