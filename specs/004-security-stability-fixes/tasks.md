# Task Breakdown: Pre-Deploy Security & Stability Fixes
# Feature: `004-security-stability-fixes`
# Plan: specs/004-security-stability-fixes/plan.md
# Spec: specs/004-security-stability-fixes/spec.md
# Generated: 2026-03-23

---

## Implementation Strategy

MVP = Fix Group A (security) — zero-tolerance before any production deploy.
Everything else follows in strict priority order. Each phase is independently testable.

---

## Phase 1: Setup

> Initialize files and verify baseline analysis.

- [ ] T001 Run `flutter analyze` and record baseline issue count for comparison (output to terminal)
- [ ] T002 [P] Create `firestore.rules` at repo root with empty `rules_version = '2'` skeleton
- [ ] T003 [P] Create `firestore.indexes.json` at repo root with empty `{ "indexes": [], "fieldOverrides": [] }` skeleton
- [ ] T004 [P] Create `.gitattributes` at repo root to normalize CRLF → LF (`L1` fix from audit)

---

## Phase 2: Foundational — Data Model & Interface Changes

> These interface changes are prerequisites for Fix Group A (C2) and must be done before any Dart code changes.

- [ ] T005 [US2] Update abstract method `deleteStudent` in `lib/features/student/domain/repos/i_student_repository.dart` — add `{required String performedByUid}` named param
- [ ] T006 [US2] Update abstract method `restoreStudent` in `lib/features/student/domain/repos/i_student_repository.dart` — add `{required String performedByUid}` named param
- [ ] T007 [US2] Update `DeleteStudentUseCase.call()` signature in `lib/features/student/domain/usecases/delete_student_usecase.dart` — add `{required String performedByUid}` and forward to repository
- [ ] T008 [US2] Update `RestoreStudentUseCase.call()` signature in `lib/features/student/domain/usecases/restore_student_usecase.dart` — add `{required String performedByUid}` and forward to repository

---

## Phase 3: User Story 1 — Server-Side Role Enforcement (Firestore Rules)

**Story Goal**: All write operations are rejected by Firestore for unauthorized roles.
**Independent Test**: Deploy rules to Firebase Emulator; attempt unauthorized writes — must receive `permission-denied`.

### Implementation

- [ ] T009 [US1] Author helper functions in `firestore.rules` — `isSignedIn()`, `userRole()`, `isAdmin()`, `isServant()`, `isServantOfTeam(teamId)` — using `get(/databases/.../Users/$(request.auth.uid))`
- [ ] T010 [US1] Add `match /Users/{uid}` rule block in `firestore.rules` — read: own uid or admin; write: admin only
- [ ] T011 [US1] Add `match /Students/{docId}` rule block in `firestore.rules` — read: any signed-in user; create/update/delete: admin only
- [ ] T012 [US1] Add `match /Classes/{teamId}` rule block in `firestore.rules` — read: any signed-in; write: admin only
- [ ] T013 [US1] Add `match /Classes/{teamId}/attendance_sessions/{sessionId}` nested rule in `firestore.rules` — read: any signed-in; create/update/delete: admin only
- [ ] T014 [US1] Add `match /Classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}` nested rule in `firestore.rules` — read: any signed-in; write: admin OR `isServantOfTeam(teamId)`
- [ ] T015 [US1] Verify rules locally with Firebase Emulator — confirm `permission-denied` for servant creating a session; confirm success for admin creating a session

---

## Phase 4: User Story 2 — Actor Identity on Archive/Restore

**Story Goal**: `archivedByUserId` and `restoredByUserId` in Firestore contain the performing admin's uid.
**Independent Test**: Archive a student as admin A → read Firestore doc → `archivedByUserId == A.uid`.

### Implementation

- [ ] T016 [US2] Update `deleteStudent` in `lib/features/student/data/repos/student_data_repository.dart` — add `{required String performedByUid}` param; replace `'archivedByUserId': 'system'` with `'archivedByUserId': performedByUid` (// FIX [004-C2])
- [ ] T017 [US2] Update `restoreStudent` in `lib/features/student/data/repos/student_data_repository.dart` — add `{required String performedByUid}` param; replace `'restoredByUserId': 'system'` with `'restoredByUserId': performedByUid` (// FIX [004-C2])
- [ ] T018 [US2] Update `StudentDataBloc` in `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart` — pass `state.authUser!.uid` (or current user uid) as `performedByUid` when calling `DeleteStudentUseCase` and `RestoreStudentUseCase`
- [ ] T019 [US2] Verify: run app on emulator → archive student as admin → check Firestore `Students/{id}.archivedByUserId` is admin uid, not `'system'`

---

## Phase 5: User Story 3 — Idempotent Logout

**Story Goal**: Calling `logOut()` twice in a row causes no exception.
**Independent Test**: Call `logOut()` twice sequentially — second call must return normally.

### Implementation

- [ ] T020 [P] [US3] In `lib/features/auth/data/services/firebase_auth_provider.dart`, remove the `else { throw UserNotLoggedInAuthException(); }` branch from `logOut()` — add comment `// FIX [004-H4]: idempotent logout`
- [ ] T021 [US3] Verify: in debug build, trigger `AuthEventSignOut` twice in rapid succession — confirm no `UserNotLoggedInAuthException` is raised and no red-screen error appears

---

## Phase 6: User Story 4 — Active Session Query Optimization

**Story Goal**: `watchActiveSessionForTeam` queries only open sessions from Firestore.
**Independent Test**: Monitor Firestore reads in emulator — only `isClosed == false` documents returned.

### Implementation

- [ ] T022 [US4] In `lib/features/attendance/data/repos/attendance_repository.dart`, add private method `_watchOpenSessionsForTeam(String teamId)` — queries `_sessionsCol(teamId).where('isClosed', isEqualTo: false).snapshots()` mapping result with `_mapSessionsSnapshot` (// FIX [004-H3])
- [ ] T023 [US4] In `watchActiveSessionForTeam`, replace the `watchSessionsForTeam(teamId)` argument in `Rx.combineLatest2` with `_watchOpenSessionsForTeam(teamId)`
- [ ] T024 [US4] Add composite index for `isClosed` + ordering (if needed) to `firestore.indexes.json` — verify against emulator index requirements
- [ ] T025 [US4] Verify: create 5 closed sessions + 1 open session in emulator → confirm `watchActiveSessionForTeam` stream emits only the open session

---

## Phase 7: User Story 5 — Attendance Stats Performance

**Story Goal**: Stats queries are parallel (team) and bounded to 6 months (student).
**Independent Test**: Team stats with 10 sessions completes within 5 seconds; student with 200 sessions issues at most ~50 reads.

### Implementation

- [ ] T026 [US5] In `lib/features/attendance/data/repos/attendance_repository.dart`, in `getTeamAttendanceStats`: extract `eligibleSessions` list (sessions in range + closed) before the loop, then replace sequential `await _marksCol(...).get()` with `final markSnapshots = await Future.wait(eligibleSessions.map((s) => _marksCol(teamId, s.id).get()));` — iterate `markSnapshots` by index (// FIX [004-H1])
- [ ] T027 [US5] In `lib/features/attendance/data/repos/attendance_repository.dart`, add optional `DateTime? since` parameter to the private `_studentSessionsQuery` method — when not null, apply `.where('startsAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since!))` to the query (// FIX [004-H2])
- [ ] T028 [US5] In `getStudentAttendanceStats`, compute `final since = DateTime.now().subtract(const Duration(days: 180));` and pass `since: range == null ? since : null` when calling `_loadStudentSessions` — preserves explicit date range override
- [ ] T029 [US5] Add the composite index for `attendance_sessions` collectionGroup — fields: `studentIdsSnapshot` (CONTAINS) + `startsAt` (ASCENDING) — in `firestore.indexes.json`
- [ ] T030 [US5] Verify: in debug build with emulator, call `getTeamAttendanceStats` with 10 sessions — confirm Firestore read count = 10 concurrent mark reads (check emulator metrics); confirm `getStudentAttendanceStats` for a student with 50 sessions only returns sessions from last 180 days

---

## Phase 8: User Story 6 — DevTools Route Guard

**Story Goal**: `/devtools` route does not exist in release builds.
**Independent Test**: Release build — navigate to `/devtools` — route not found (fallback shown).

### Implementation

- [ ] T031 [P] [US6] In `lib/core/routing/app_router.dart`, wrap the `case devTools:` block with `if (kDebugMode)` — add comment `// FIX [004-M3]: devTools not accessible in release builds`; ensure `import 'package:flutter/foundation.dart'` is present
- [ ] T032 [US6] Verify: build in release mode (`flutter build apk --release`); confirm route resolves to `unknownRoute`/`NotFoundScreen` for `/devtools`

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T033 [P] Run `flutter analyze` — confirm **zero** issues
- [ ] T034 [P] Run `dart run build_runner build --delete-conflicting-outputs` — confirm no conflicts
- [ ] T035 Deploy Firestore rules + indexes to production: `firebase deploy --only firestore:rules,firestore:indexes`
- [ ] T036 Tag git commit: `git tag v1.0.0-security-patch`

---

## Dependency Graph

```
Phase 1 (Setup)
  └─ T005, T006 (foundational interface changes)
       └─ T007, T008 (use case changes)
            └─ T016, T017 (repo implementation)
                 └─ T018 (BLoC caller update)

Phase 3 (Firestore Rules) ← independent of all Dart changes
  └─ T009 → T010 → T011 → T012 → T013 → T014

Phase 5 (Idempotent Logout) ← independent of everything else
  T020

Phase 6 (Active Session Query) ← independent
  T022 → T023 → T024

Phase 7 (Stats Performance) ← depends on understanding attendance_repository structure
  T026 (parallel reads)
  T027 → T028 (student stats cap)
  T029 (index declaration)

Phase 8 (DevTools Guard) ← fully independent
  T031

Phase 9 ← depends on all previous phases complete
  T033 → T034 → T035 → T036
```

---

## Parallel Execution Examples

Tasks marked `[P]` can run in parallel across separate files:

**Group 1 (parallel start)**:
- T002 (firestore.rules skeleton)
- T003 (firestore.indexes.json skeleton)
- T004 (.gitattributes)
- T020 (idempotent logout — isolated file)
- T031 (devTools guard — isolated file)

**Group 2 (after T005+T006)**:
- T007 (DeleteUseCase) in parallel with T008 (RestoreUseCase)

**Group 3 (after T022)**:
- T026 (parallel marks reads) in parallel with T027 (student sessions cap)

---

## Task Summary

| Phase | Area | Tasks | User Story |
|-------|------|-------|------------|
| 1 | Setup | T001–T004 | — |
| 2 | Interface changes | T005–T008 | US2 (prereq) |
| 3 | Firestore rules | T009–T015 | US1 |
| 4 | Actor identity | T016–T019 | US2 |
| 5 | Idempotent logout | T020–T021 | US3 |
| 6 | Active session query | T022–T025 | US4 |
| 7 | Stats performance | T026–T030 | US5 |
| 8 | DevTools guard | T031–T032 | US6 |
| 9 | Polish & deploy | T033–T036 | — |

**Total**: 36 tasks | **Parallelizable**: 9 tasks | **MVP scope**: Phase 3 (US1) + Phase 4 (US2) — the two critical security fixes
