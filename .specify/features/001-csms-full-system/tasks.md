# Tasks: CSMS Full System Implementation

**Feature:** Church Servant & Student Management System
**Spec:** [spec.md](./spec.md) | **Plan:** [plan.md](./plan.md) | **Data Model:** [data-model.md](./data-model.md)
**Generated:** 2026-04-04
**Total Tasks:** 79

---

## User Stories → Task Mapping

| Story | Title | Tasks | Priority |
| ----- | ----- | ----- | -------- |
| US-01 | Auth Flow & Role Routing | T001–T006 | P1 |
| US-02 | Admin — Create Servant Account | T017–T019 | P1 |
| US-03 | Admin — Manage Teams | T020–T023, T069 | P1 |
| US-04 | Admin — Assign Servant to Team | T024–T027 | P1 |
| US-05 | Servant — Take Attendance | T028–T036, T070, T071 | P1 |
| US-06 | Servant — View Attendance History | T037–T039 | P2 |
| US-07 | Student — View Own Profile | T040–T042 | P2 |
| US-08 | Student — View Own Attendance | T043–T045 | P2 |
| US-09 | Admin — Archive/Restore User | T046–T050, T072 | P1 |
| US-10 | Admin — View Dashboard | T051–T054 | P2 |
| US-11 | System — Degraded Mode | T055–T059 | P2 |
| — | Setup/Infra | T001–T006 | P0 |
| — | Refactor Prerequisites | T007–T016, T073, T074 | P0 |
| — | Hardening & Cleanup | T060–T068, T075, T076, T077 | P3 |

---

## Phase 1: Safety & Infrastructure (P0)

> **Goal:** Fix all security blockers and infrastructure gaps. No feature changes. No client changes.
> **Rollback:** Revert firebase.json + redeploy functions.
> **Agent:** Gemini (infrastructure config) + HUMAN REVIEW for security changes.

- [x] T001 Add Firestore deployment config to `firebase.json`
  - **Purpose:** Fix SEC-01 — firestore.rules are not deployed via CI/CD. [P01-T1]
  - **Refs:** Plan P0-T1, Constitution P14
  - **Dependencies:** None
  - **Work:**
    - Add `"firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" }` to `firebase.json`
    - Create empty `firestore.indexes.json` file (`{ "indexes": [], "fieldOverrides": [] }`)
  - **Files:** `firebase.json`, `firestore.indexes.json` (new)
  - **Definition of Done:**
    - `firebase deploy --only firestore:rules` succeeds in emulator
    - Rules in emulator match committed `firestore.rules`
  - **Tests:** Manual deployment verification
  - **Regression Risk:** LOW — additive config change only
  - **Reviewer Checklist:**
    - [ ] `firebase.json` is valid JSON
    - [ ] Path to `firestore.rules` is correct relative to project root
    - [ ] `firestore.indexes.json` is valid JSON
  - **Agent:** Gemini ✅

- [x] T002 Harden Cloud Function `requireAdmin()` — check Firestore archive state
  - **Purpose:** Fix SEC-02 — archived admins can still call privileged functions. [P0-T2]
  - **Refs:** Plan P0-T2, Constitution P04, FR-01.5
  - **Dependencies:** None
  - **Work:**
    - In `functions/src/index.ts`, modify `requireAdmin()` to read the Firestore `Users/{uid}` doc
    - After role check, add: `if (userDoc.data()?.isArchived === true) throw new HttpsError('permission-denied', 'Archived users cannot perform admin operations.')`
    - Move the existing Firestore doc read BEFORE the claims check to avoid short-circuit on stale claims
  - **Files:** `functions/src/index.ts`
  - **Definition of Done:**
    - Archived admin calling any callable → `permission-denied` error
    - Non-archived admin calling any callable → success
  - **Tests:** Add `functions/tests/require_admin_test.ts` with mock auth contexts
  - **Regression Risk:** MEDIUM — must not break existing admin operations
  - **Reviewer Checklist:**
    - [ ] `requireAdmin()` always reads Firestore doc, never relies on claims alone
    - [ ] Error messages are user-safe (no internal details)
    - [ ] Existing callables still work for non-archived admins
  - **Agent:** Gemini ✅ | **HUMAN REVIEW required** before deploy

- [x] T003 Remove self-registration from Firestore rules
  - **Purpose:** Per clarification Q4 — no self-registration. [P0-T3]
  - **Refs:** Plan P0-T3, Spec FR-01.2 (updated), BR-03 (updated)
  - **Dependencies:** T001
  - **Work:**
    - In `firestore.rules`, remove `validSelfUserCreate(userId)` function (lines 91–101)
    - Change Users create rule from `allow create: if isSignedIn() && (isAdmin() || validSelfUserCreate(userId))` to `allow create: if isAdmin()`
    - Verify Cloud Functions use Admin SDK (`adminDb`) which bypasses Firestore rules
  - **Files:** `firestore.rules`
  - **Definition of Done:**
    - Non-admin user attempting to create a Users doc → `permission-denied`
    - Cloud Function `createPrivilegedUser` still creates Users docs successfully (Admin SDK)
  - **Tests:** Firestore rules emulator test
  - **Regression Risk:** MEDIUM — must verify all existing user creation paths use Cloud Functions
  - **Reviewer Checklist:**
    - [ ] `validSelfUserCreate` function is fully removed
    - [ ] Users create rule is `if isAdmin()` only
    - [ ] Cloud Functions confirmed to use Admin SDK (not client SDK)
    - [ ] No client-side code attempts direct Users doc creation
  - **Agent:** Gemini ✅ | **HUMAN REVIEW required** before deploy

- [x] T004 Add Firestore rules for read-model collections (audit_logs)
  - **Purpose:** Enforce INV-07 — backend-only collections deny all client writes. [P0-T4]
  - **Refs:** Plan P0-T4, Constitution P05, FR-12.5
  - **Dependencies:** T001
  - **Work:**
    - Add rules in `firestore.rules`:
      ```
      match /audit_logs/{logId} {
        allow read: if isAdmin();
        allow write: if false;
      }
      match /attendance_history/{docId} {
        allow read: if isSignedIn();
        allow write: if false;
      }
      ```
  - **Files:** `firestore.rules`
  - **Definition of Done:**
    - Client write to `audit_logs` → denied
    - Admin read of `audit_logs` → allowed
    - Cloud Function write to `audit_logs` via Admin SDK → succeeds (bypasses rules)
  - **Tests:** Rules emulator test
  - **Regression Risk:** LOW — new collections, no existing data
  - **Agent:** Gemini ✅

- [x] T005 Delete stale `attendance_record/` directory
  - **Purpose:** Remove D-05 tech debt — stale typo directory. [P0-T5]
  - **Refs:** Plan P0-T5
  - **Dependencies:** None
  - **Work:**
    - Verify `lib/features/attendance_record/` has no active imports (search codebase)
    - Delete directory entirely
  - **Files:** `lib/features/attendance_record/` (delete)
  - **Definition of Done:**
    - Directory deleted
    - `flutter analyze` reports no missing imports
    - `flutter test` passes
  - **Tests:** `flutter test` (regression)
  - **Regression Risk:** LOW — verify no imports first
  - **Agent:** Gemini ✅

- [ ] T006 Deploy Phase 0 to Firebase (rules + functions)
  - **Purpose:** Apply security fixes to production. [P0 gate]
  - **Refs:** Constitution HR-01 (deploy order: rules → functions → client)
  - **Dependencies:** T001, T002, T003, T004
  - **Work:**
    - `firebase deploy --only firestore:rules`
    - `firebase deploy --only functions`
    - Verify all 4 callables respond correctly
    - Verify self-registration attempt is denied
  - **Files:** None (deployment action)
  - **Definition of Done:**
    - Firebase Console shows updated rules
    - All 4 callables work for non-archived admin
    - Archived admin is rejected by all callables
  - **Tests:** Manual smoke test
  - **Regression Risk:** HIGH — production-affecting deployment
  - **Agent:** **HUMAN ONLY** — deploy must be human-reviewed and executed

---

## Phase 2: Architecture Refactoring Prerequisites (P0)

> **Goal:** Restructure existing code to support safe feature development. App behavior is UNCHANGED.
> **Rollback:** Revert commits. All changes are internal refactors.
> **Agent:** Gemini (refactoring) + Codex (test generation).

- [x] T007 Split AttendanceRepository — extract AttendanceSessionRepository
  - **Purpose:** Fix D-06 / P02 (SRP) — session CRUD extracted from 1002-line god class. [P1-T1a]
  - **Refs:** Plan P1-T1, Constitution P02, P13
  - **Dependencies:** T005
  - **Work:**
    - Create `lib/features/attendance/data/repos/attendance_session_repository.dart`
    - Move session-related methods: `createSession`, `closeSession`, `reopenSession`, `getSessionsForTeam`, `getSessionById`, `getSessionsForDate`
    - Add class doc comment per P17
    - Keep `AttendanceRepository` as a thin facade delegating to the new repo (backward compat)
  - **Files:** `lib/features/attendance/data/repos/attendance_session_repository.dart` (new), `lib/features/attendance/data/repos/attendance_repository.dart` (modify)
  - **Definition of Done:**
    - New file ≤300 lines
    - `AttendanceRepository` facade still satisfies `IAttendanceRepository` interface
    - `flutter test` passes with zero regressions
  - **Tests:** Run existing attendance tests to verify no behavioral change
  - **Regression Risk:** MEDIUM — interface must remain identical
  - **Agent:** Gemini ✅

- [x] T008 Split AttendanceRepository — extract AttendanceMarkRepository
  - **Purpose:** Fix D-06 / P02 (SRP) — mark CRUD extracted. [P1-T1b]
  - **Refs:** Plan P1-T1, Constitution P02, P13, FR-08.7
  - **Dependencies:** T007
  - **Work:**
    - Create `lib/features/attendance/data/repos/attendance_mark_repository.dart`
    - Move mark-related methods: `createMark`, `updateMark`, `getMarksForSession`, `getMarkForStudent`
    - Add `deleteMark()` method (new — per FR-08.7 toggle-off deletes document)
    - Add class doc comment per P17
  - **Files:** `lib/features/attendance/data/repos/attendance_mark_repository.dart` (new), `lib/features/attendance/data/repos/attendance_repository.dart` (modify)
  - **Definition of Done:**
    - New file ≤200 lines
    - `deleteMark()` deletes the mark document at path `Classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`
    - Existing mark tests pass unchanged
  - **Tests:** Run existing tests; add unit test for `deleteMark()`
  - **Regression Risk:** MEDIUM
  - **Agent:** Gemini ✅

- [x] T009 Create AttendanceSessionService (orchestration layer)
  - **Purpose:** Orchestration logic that spans session + mark repos. [P1-T1c]
  - **Refs:** Plan P1-T1, Constitution P13 (service boundary)
  - **Dependencies:** T007, T008
  - **Work:**
    - Create `lib/features/attendance/data/services/attendance_session_service.dart`
    - Method: `createSessionWithRosterSnapshot(teamId, title, startsAt, endsAt, createdByUserId, createdByName)` — reads active students for team, creates session document with frozen roster
    - Method: `closeSession(teamId, sessionId)`
    - Method: `reopenSession(teamId, sessionId, reopenedByUserId, reopenedByName)` — admin only
    - Add class doc comment per P17
  - **Files:** `lib/features/attendance/data/services/attendance_session_service.dart` (new)
  - **Definition of Done:**
    - Service depends on `AttendanceSessionRepository` + `StudentQueryService` (injected)
    - Service does NOT directly access Firestore
    - ≤200 lines
  - **Tests:** Unit test with mocked repos
  - **Regression Risk:** LOW — new code, no existing code modified
  - **Agent:** Gemini ✅

- [x] T010 Add IServantRepository domain interface
  - **Purpose:** Align servant repo with clean architecture (P01). [P1-T2a]
  - **Refs:** Plan P1-T2
  - **Dependencies:** None
  - **Work:**
    - Create `lib/features/servant/domain/repos/i_servant_repository.dart`
    - Define: `Stream<List<Servant>> watchServants()`, `Future<Servant?> getServantById(String uid)`, `Future<void> updateServant(Servant servant)`
    - Make `ServantDataRepository` implement `IServantRepository`
    - Register `IServantRepository` in `injection.dart`
  - **Files:** `lib/features/servant/domain/repos/i_servant_repository.dart` (new), `lib/features/servant/data/repo/servant_data_repository.dart` (modify), `lib/core/di/injection.dart` (modify)
  - **Definition of Done:**
    - Presentation layer can depend on `IServantRepository` instead of `ServantDataRepository`
    - All existing code compiles
  - **Tests:** `flutter analyze` — no errors
  - **Regression Risk:** LOW
  - **Agent:** Gemini ✅

- [x] T011 Add ITeamRepository domain interface
  - **Purpose:** Align team repo with clean architecture (P01). [P1-T2b]
  - **Refs:** Plan P1-T2
  - **Dependencies:** None
  - **Work:**
    - Create `lib/features/team/domain/repos/i_team_repository.dart`
    - Define: `Stream<List<Team>> watchTeams()`, `Future<Team?> getTeamById(String id)`, `Future<void> createTeam(Team team)`, `Future<void> updateTeam(Team team)`, `Future<void> archiveTeam(String id)`, `Future<void> restoreTeam(String id)`
    - Make `TeamRepository` implement `ITeamRepository`
    - Register in `injection.dart`
  - **Files:** `lib/features/team/domain/repos/i_team_repository.dart` (new), `lib/features/team/data/repos/team_repository.dart` (modify), `lib/core/di/injection.dart` (modify)
  - **Definition of Done:** Same as T010
  - **Tests:** `flutter analyze`
  - **Regression Risk:** LOW
  - **Agent:** Gemini ✅

- [x] T012 Register new attendance repos/services in DI container
  - **Purpose:** Wire P1 refactored components into GetIt. [P1 wiring]
  - **Refs:** Constitution P01, DI registration discipline
  - **Dependencies:** T007, T008, T009
  - **Work:**
    - Add registrations for `AttendanceSessionRepository`, `AttendanceMarkRepository`, `AttendanceSessionService` in `injection.dart`
    - Group under `// ---- Attendance ----` comment block
    - Maintain singleton scope (LazySingleton)
  - **Files:** `lib/core/di/injection.dart`
  - **Definition of Done:**
    - `getIt<AttendanceSessionRepository>()` resolves correctly
    - `flutter test` passes
  - **Tests:** Verify DI resolution in existing tests
  - **Regression Risk:** LOW
  - **Agent:** Gemini ✅

- [ ] T013 [P] Write unit tests for StudentLinkedUserSyncService
  - **Purpose:** Close D-07 — critical sync logic is untested. [P1-T3]
  - **Refs:** Plan P1-T3, Constitution P07
  - **Dependencies:** None (test-only task)
  - **Work:**
    - Create `test/features/student/data/services/student_linked_user_sync_service_test.dart`
    - Test cases:
      - Student name change → Users doc `name` field updated
      - Student with `uid == null` → no sync attempted, no error
      - Firestore write failure → caught, logged via `debugPrint`, not thrown
      - Concurrent sync calls → no duplicate writes
  - **Files:** `test/features/student/data/services/student_linked_user_sync_service_test.dart` (new)
  - **Definition of Done:** ≥90% branch coverage on sync service
  - **Tests:** `flutter test test/features/student/data/services/`
  - **Regression Risk:** None (test-only)
  - **Agent:** Codex ✅ (test generation strength)

- [ ] T014 [P] Write unit tests for AuthBloc degraded mode
  - **Purpose:** Close D-08 — degraded mode has limited test coverage. [P1-T4]
  - **Refs:** Plan P1-T4, Constitution P07, Spec US-11
  - **Dependencies:** None (test-only task)
  - **Work:**
    - Create `test/features/auth/presentation/bloc/auth_bloc_degraded_test.dart`
    - Test cases:
      - Profile fetch failure with valid cached user → `AuthDegraded` state emitted
      - Degraded state + foreground event with connectivity → re-resolves to `AuthAuthenticated`
      - Degraded state + signed-out user → routes to login
      - `AuthDegraded` carries user-readable message
  - **Files:** `test/features/auth/presentation/bloc/auth_bloc_degraded_test.dart` (new)
  - **Definition of Done:** All degraded state transitions have test coverage
  - **Tests:** `flutter test test/features/auth/`
  - **Regression Risk:** None (test-only)
  - **Agent:** Codex ✅

- [x] T015 Implement AuthFreshnessPolicy (15-min write window)
  - **Purpose:** Per clarification Q1 — track auth validation freshness. [P1-T5]
  - **Refs:** Plan P1-T5, Spec AC-11.2, AC-11.3, NFR-02.2
  - **Dependencies:** T014
  - **Work:**
    - Create `lib/features/auth/domain/auth_freshness_policy.dart`
    - Class with: `void recordValidation()`, `bool get canPerformWrites` (true if last validation < 15 min ago)
    - Inject `Clock` for testability (from `package:clock` or custom)
    - Integrate into `AuthService` — call `recordValidation()` on successful profile fetch
  - **Files:** `lib/features/auth/domain/auth_freshness_policy.dart` (new), `lib/features/auth/data/services/auth_service.dart` (modify)
  - **Definition of Done:**
    - `canPerformWrites` returns `true` within 15 minutes of last validation
    - `canPerformWrites` returns `false` after 15 minutes
    - BLoC/Cubit can query `canPerformWrites` before any write operation
  - **Tests:** Unit test with mocked clock
  - **Regression Risk:** LOW — new class, minor integration into AuthService
  - **Agent:** Gemini ✅

- [ ] T016 Write unit tests for AuthFreshnessPolicy
  - **Purpose:** Test-first for risky auth logic. [P1-T5 test]
  - **Refs:** Constitution P07
  - **Dependencies:** T015
  - **Work:**
    - Create `test/features/auth/domain/auth_freshness_policy_test.dart`
    - Test cases:
      - Fresh validation (0 min ago) → `canPerformWrites == true`
      - Validation at 14 min → `canPerformWrites == true`
      - Validation at 15 min → `canPerformWrites == false`
      - Validation at 60 min → `canPerformWrites == false`
      - `recordValidation()` resets the window
      - No validation ever recorded → `canPerformWrites == false`
  - **Files:** `test/features/auth/domain/auth_freshness_policy_test.dart` (new)
  - **Definition of Done:** 100% branch coverage
  - **Agent:** Codex ✅

---

## Phase 3: Backend Enhancements (Cloud Functions)

> **Goal:** Add missing Cloud Functions and server-side logic.
> **Rollback:** `firebase deploy --only functions` with previous version.
> **Agent:** Gemini (TypeScript) + HUMAN REVIEW before deploy.

- [x] T017 [US2] Create `createStudentUser` Cloud Function
  - **Purpose:** Per FR-01.2 + Q4 — admin-provisioned student accounts. [P2-T1]
  - **Refs:** Spec FR-01.2, FR-02.3, AC-02.1, BR-03 (updated)
  - **Dependencies:** T002
  - **Work:**
    - Add `createStudentUser` callable to `functions/src/index.ts`
    - Input: `{ email, name, password, group?, classId?, phone? }`
    - Operations: `adminAuth.createUser()` → `setCustomUserClaims({ role: 'student' })` → write Users doc → write Students doc (with `uid` link)
    - Rollback on failure: attempt to delete Auth user, Users doc, and Students doc regardless of prior successes. Catch and aggregate errors from each compensating delete. Write a `RollbackLogs` (or `RecoveryActions`) Firestore doc recording which cleanup steps succeeded/failed with error details. Surface a distinct rollback-failure error from the callable (no silent orphaning).
    - Add helper functions in `lifecycle_helpers.ts` for safe delete-if-exists operations (`deleteAuthUserIfExists`, `deleteDocIfExists`).
  - **Files:** `functions/src/index.ts`, `functions/src/lifecycle_helpers.ts`
  - **Definition of Done:**
    - Calling `createStudentUser` creates Auth user + Users doc + Students doc
    - Students doc has `uid` matching Auth UID
    - Duplicate email → `already-exists` error, no partial data
    - Rollback failures produce a `RollbackLogs` entry and a distinct `rollback-failure` error
  - **Tests:** `functions/tests/create_student_user_test.ts` (emulator) — assert behavior when a rollback delete fails (no silent orphaning, RollbackLogs entry present, callable throws distinct rollback-failure error)
  - **Regression Risk:** LOW — new function, doesn't modify existing ones
  - **Agent:** Gemini ✅ | **HUMAN REVIEW required** before deploy

- [x] T018 [US2] Add `parseStudentCreateRequest` to lifecycle_helpers
  - **Purpose:** Input validation for student creation. [P2-T1 helper]
  - **Refs:** Spec FR-02.3
  - **Dependencies:** None
  - **Work:**
    - Add TypeScript type `CreateStudentUserRequest` and parser function
    - Validate: email format, name non-empty, group in allowed values
  - **Files:** `functions/src/lifecycle_helpers.ts`
  - **Definition of Done:** Invalid input → `invalid-argument` HttpsError
  - **Tests:** Unit test for parser
  - **Agent:** Gemini ✅

- [x] T019 [US2] Add `buildStudentProfile` to lifecycle_helpers
  - **Purpose:** Build Students document payload for creation. [P2-T1 helper]
  - **Refs:** Data model (Students collection)
  - **Dependencies:** T018
  - **Work:**
    - Add function `buildStudentProfile({ uid, name, email, group, classId, phone })` → Firestore-ready document
    - Include: `isArchived: false`, `role: 'student'`, `createdAt: FieldValue.serverTimestamp()`, `updatedAt: FieldValue.serverTimestamp()`
  - **Files:** `functions/src/lifecycle_helpers.ts`
  - **Definition of Done:** Returns valid Students document shape
  - **Agent:** Gemini ✅

- [x] T020 [US3] Add audit log helper function
  - **Purpose:** Per FR-12.5 + INV-07 — backend-only audit logs. [P2-T3]
  - **Refs:** Plan P2-T3, Spec BR-14, data-model (audit_logs)
  - **Dependencies:** T004
  - **Work:**
    - Create `functions/src/audit.ts`
    - Export `writeAuditLog(action, actorUid, targetUid?, details?)` → writes to `audit_logs/{autoId}`
    - Fields: `action`, `actorUid`, `targetUid`, `details`, `timestamp: FieldValue.serverTimestamp()`
  - **Files:** `functions/src/audit.ts` (new)
  - **Definition of Done:** Audit log document written on every lifecycle call
  - **Tests:** Verify audit log exists after `createPrivilegedUser` call
  - **Agent:** Gemini ✅

- [x] T021 [US3] Wire audit logging into existing lifecycle functions
  - **Purpose:** All existing callables now write audit logs. [P2-T3 integration]
  - **Refs:** Spec BR-14
  - **Dependencies:** T020
  - **Work:**
    - Import `writeAuditLog` in `index.ts`
    - Add calls in: `createPrivilegedUser`, `rollbackPrivilegedUser`, `archiveManagedUser`, `restoreManagedUser`
    - Add call in new `createStudentUser` (T017)
  - **Files:** `functions/src/index.ts`
  - **Definition of Done:** Each callable writes one audit_log document
  - **Agent:** Gemini ✅

- [x] T022 [US9] Enhance `archiveManagedUser` — servant team cleanup
  - **Purpose:** Per FR-04.4 — archiving a servant clears team assignments. [P2-T2]
  - **Refs:** Plan P2-T2, Spec AC-09.6, BR-10
  - **Dependencies:** T002
  - **Work:**
    - In `archiveManagedUser`, after disabling Auth user:
      - Read target User doc to get role
      - If role === 'servant': query all Classes where `assignedServantId == target.uid`
      - For each: clear `assignedServantId`/`assignedServantName`
      - Clear `assignedTeamIds` on servant's Users doc
      - Use batched write for atomicity
  - **Files:** `functions/src/index.ts`
  - **Definition of Done:**
    - Archiving a servant → all their team assignments are cleared
    - Archiving a student → no team cleanup (students don't have team assignments)
  - **Tests:** Emulator test with servant assigned to 2 teams
  - **Regression Risk:** MEDIUM — modifying existing function
  - **Agent:** Gemini ✅ | **HUMAN REVIEW required**

- [x] T023 [US9] Enhance `restoreManagedUser` — password reset email
  - **Purpose:** Per FR-04.5, AC-09.4 — restored users get password reset. [P2-T4]
  - **Refs:** Plan P2-T4, Spec AC-09.5, INV-09
  - **Dependencies:** T002
  - **Work:**
    - In `restoreManagedUser`, add `restorePendingPasswordReset: true` to the Users doc patch
    - Call `adminAuth.generatePasswordResetLink(email)` and send via email (or set flag for client-side handling)
  - **Files:** `functions/src/index.ts`, `functions/src/lifecycle_helpers.ts`
  - **Definition of Done:**
    - Restored user doc has `restorePendingPasswordReset: true`
    - Password reset mechanism is triggered
  - **Tests:** Emulator test verifying field is set
  - **Agent:** Gemini ✅

- [x] T069 [US3] Add team name uniqueness validation
  - **Purpose:** Per FR-05.3 — team names MUST be unique within a group. [ANALYSIS FIX H1]
  - **Refs:** Spec FR-05.3
  - **Dependencies:** T011
  - **Work:**
    - In `TeamRepository.createTeam()` and `updateTeam()`:
    - Move the duplicate-name check+write into a Firestore transaction using `firestore.runTransaction()`. Inside the transaction: query `Classes` where `groupId == team.groupId` and `name == team.name` using `transaction.get()`, abort/throw a user-readable Arabic error if a conflicting doc exists (for update, ensure the found doc id != team.id).
    - Optionally add a composite `[groupId, name]` index for query performance.
    - Keep a fallback that maps Firestore write exceptions to the same Arabic error.
    - Handle transaction conflicts/retries gracefully.
  - **Files:** `lib/features/team/data/repos/team_repository.dart`
  - **Definition of Done:**
    - Creating a team with duplicate name in same group → error
    - Creating a team with same name in different group → success
    - Concurrent duplicate creation → only one succeeds (transactional guarantee)
  - **Tests:** Unit test with FakeFirebaseFirestore + concurrent creation test
  - **Regression Risk:** LOW — additive validation
  - **Agent:** Gemini ✅

- [x] T070 [US5] Implement session reopen flow
  - **Purpose:** Per FR-07.5 — admin can reopen a closed session for editing. [ANALYSIS FIX H2]
  - **Refs:** Spec FR-07.5, FR-07.6
  - **Dependencies:** T009
  - **Work:**
    - In `AttendanceSessionService.reopenSession(teamId, sessionId, reopenedByUserId, reopenedByName)`:
    - Set `isClosed = false`, `reopenedAt = FieldValue.serverTimestamp()`, `reopenedByUserId`, `reopenedByName`
    - In attendance marking Cubit: if session has `reopenedAt != null`, only allow marks from admin (not the assigned servant)
  - **Files:** `lib/features/attendance/data/services/attendance_session_service.dart`, `lib/features/attendance/presentation/bloc/attendance_marking_cubit.dart`
  - **Definition of Done:**
    - Admin reopens closed session → session accepts marks from admin only
    - Servant attempts to mark on reopened session → rejected
  - **Tests:** Unit test for service + Cubit guard
  - **Agent:** Gemini ✅

- [x] T071 [US5] Write tests for session reopen logic
  - **Purpose:** Test-first for reopen guard. [ANALYSIS FIX H2 test]
  - **Dependencies:** T070
  - **Work:**
    - Test cases:
      - Reopen closed session by admin → success, metadata recorded
      - Reopen attempt by servant → rejected
      - Mark on reopened session by admin → allowed
      - Mark on reopened session by servant → rejected
  - **Files:** `test/features/attendance/data/services/attendance_session_service_test.dart` (extend)
  - **Agent:** Codex ✅

- [x] T072 [US9] Create `changeUserRole` Cloud Function
  - **Purpose:** Per FR-12.2 — role changes MUST be server-authoritative. [ANALYSIS FIX C1]
  - **Refs:** Spec FR-12.2, Constitution P05
  - **Dependencies:** T002, T020
  - **Work:**
    - Add `changeUserRole` callable to `functions/src/index.ts`
    - Input: `{ targetUid, newRole }` where newRole ∈ ['admin', 'servant', 'student']
    - Operations: update `customClaims.role`, update Users doc `role` field, write audit log
    - Role-transition cleanup:
      - Demoting servant→other: clear `assignedTeamIds` from Users doc; remove user from those team documents (remove from team member arrays if applicable)
      - Promoting to servant: initialize `assignedTeamIds` as empty array; set `groupId` if provided
      - Promoting to student: create or link a Students collection document with `uid` and initialize student-specific fields (`name`, `email`, `group`, `classId`)
      - Demoting from student: remove or archive the Students doc; clear `uid` from Students if unlinking
    - Remove or migrate any previous role-specific permissions/metadata
    - Perform all changes as part of the same atomic Firestore transaction or batched operation
    - Validation: caller must be admin, target must not be self, target must not be archived
  - **Files:** `functions/src/index.ts`, `functions/src/audit.ts`, `functions/src/lifecycle_helpers.ts`
  - **Definition of Done:**
    - Role change updates both claims + Firestore atomically
    - Role-transition cleanup performed (assignedTeamIds cleared, Students doc created/removed as appropriate)
    - Non-admin caller → rejected
    - Audit log written
  - **Tests:** Emulator tests covering servant→student and student→servant transitions; verify assignedTeamIds cleared on demotion, Students doc created on promotion
  - **Regression Risk:** MEDIUM — new function modifying user state
  - **Agent:** Gemini ✅ | **HUMAN REVIEW required** before deploy

---

## Phase 4: Core Data Layer — Transactions & Sync (US-04, US-05)

> **Goal:** Implement transactional writes and denormalized field update contracts.
> **Rollback:** Revert data layer. No UI impact.
> **Agent:** Gemini (transaction logic is complex, needs reasoning).

- [x] T024 [US4] Implement transactional servant-to-team assignment
  - **Purpose:** Per FR-06.2 + Q3 — transaction-based assignment. [P3-T1]
  - **Refs:** Plan P3-T1, Spec FR-06.2–FR-06.5, Constitution P14
  - **Dependencies:** T010, T011, T012
  - **Work:**
    - In `lib/features/admin/data/admin_team_membership_service.dart`:
    - Rewrite `assignServant(teamId, newServantUid)` to use `FirebaseFirestore.instance.runTransaction()`:
      1. Read: team doc, new servant Users doc, old servant Users doc (if `assignedServantId` != null)
      2. Validate: new servant not archived, team not archived
      3. Write: team `assignedServantId` + `assignedServantName`, new servant `assignedTeamIds` += teamId, old servant `assignedTeamIds` -= teamId
    - Add retry logic (Firestore transaction retries automatically, but log on 3rd retry failure)
  - **Files:** `lib/features/admin/data/admin_team_membership_service.dart`
  - **Definition of Done:**
    - Assignment updates all 3 docs atomically
    - Failure rolls back all changes
    - Archived servant → rejected
  - **Tests:** Unit test with FakeFirebaseFirestore
  - **Regression Risk:** HIGH — modifying critical business logic
  - **Reviewer Checklist:**
    - [ ] Transaction reads all affected docs before writing
    - [ ] Old servant cleanup is in the same transaction
    - [ ] Archive state validated within transaction
  - **Agent:** Gemini ✅ | **HUMAN REVIEW required**

- [x] T025 [US4] Write unit tests for transactional assignment
  - **Purpose:** Test-first for multi-doc transaction (P07). [P3-T1 test]
  - **Refs:** Constitution P07
  - **Dependencies:** T024
  - **Work:**
    - Test cases:
      - Assign servant to empty team → team + servant updated
      - Reassign (replace old servant) → team + new servant + old servant all updated
      - Assign to archived team → error, no changes
      - Assign archived servant → error, no changes
      - Concurrent assignment → transaction retries, one wins
      - Unassign servant → team cleared, servant cleared
  - **Files:** `test/features/admin/data/admin_team_membership_service_test.dart` (new or modify)
  - **Definition of Done:** All 6 test cases pass
  - **Agent:** Codex ✅

- [x] T026 [US4] Implement servant name → team eager update
  - **Purpose:** Per NFR-04.2(a) + BR-12 — update denormalized name. [P3-T2]
  - **Refs:** Plan P3-T2, data-model (Classes.assignedServantName)
  - **Dependencies:** T024
  - **Work:**
    - In servant update flow (wherever servant name is written):
    - After updating servant name, query `Classes` where `assignedServantId == servantUid`
    - Batch-update `assignedServantName` on all matching teams
    - Single update owner: document in code comment per P06
  - **Files:** `lib/features/admin/data/admin_team_service.dart` or servant repo
  - **Definition of Done:**
    - Servant name change → all assigned teams show new name
    - No stale `assignedServantName` values
  - **Tests:** Unit test verifying propagation
  - **Agent:** Gemini ✅

- [x] T027 [US4] Implement team rename → student team_name eager update
  - **Purpose:** Per NFR-04.2(b) + BR-16 — update denormalized team name. [P3-T3]
  - **Refs:** Plan P3-T3, data-model (Students.team_name)
  - **Dependencies:** T011
  - **Work:**
    - In `TeamRepository.updateTeam()` or `AdminTeamService`:
    - If team name changed, query `Students` where `classId == teamId`
    - Batch-update `team_name` on all matching students
  - **Files:** `lib/features/team/data/repos/team_repository.dart`
  - **Definition of Done:**
    - Team rename → all students in that team have updated `team_name`
  - **Tests:** Unit test
  - **Regression Risk:** LOW — additive behavior on existing method
  - **Agent:** Gemini ✅

- [x] T028 [US5] Implement session creation with transaction (overlap check)
  - **Purpose:** Per FR-07.2 — transactional session creation. [P3-T4]
  - **Refs:** Plan P3-T4, Spec AC-05.7, FR-07.2
  - **Dependencies:** T009
  - **Work:**
    - In `AttendanceSessionService.createSessionWithRosterSnapshot()`:
    - Use `Firestore.runTransaction()`:
      1. Read: all sessions for team on same `dateKey`
      2. Validate: no overlapping time range (startA < endB && startB < endA)
      3. Validate: at least one active student in roster (EC-01: reject empty roster)
      4. Write: session doc with deterministic ID, frozen roster, timestamps
    - Deterministic session ID: `{dateKey}_{startsAt.millisecondsSinceEpoch}_{url_safe_slug}` where `url_safe_slug` is generated from the session title by normalizing (trimmed, lowercased, punctuation-removed, dash-joined). Alternatively, use Firestore auto-IDs and enforce uniqueness via the transactional overlap check.
  - **Files:** `lib/features/attendance/data/services/attendance_session_service.dart`
  - **Definition of Done:**
    - Overlapping session → rejected with user-readable error
    - Non-overlapping → session created with frozen roster
    - Empty roster → rejected (EC-01)
  - **Tests:** Unit tests for overlap detection, empty roster, normal creation
  - **Regression Risk:** MEDIUM — replaces existing non-transactional creation
  - **Agent:** Gemini ✅

- [x] T029 [US5] Write unit tests for session creation transaction
  - **Purpose:** Test-first for overlap detection (P07). [P3-T4 test]
  - **Dependencies:** T028
  - **Work:**
    - Test cases:
      - Create session with no existing → success
      - Create session overlapping existing → error
      - Create session adjacent (non-overlapping) → success
      - Create session with empty roster → error
      - Create session with 50 students → success, all IDs in snapshot
      - Concurrent creation attempt → one wins, other gets overlap error
  - **Files:** `test/features/attendance/data/services/attendance_session_service_test.dart` (new)
  - **Agent:** Codex ✅

- [x] T030 [US5] Implement mark toggle-off (delete document)
  - **Purpose:** Per Q2 + FR-08.7 — toggle-off deletes mark document. [P4-T5]
  - **Refs:** Spec AC-05.3 (updated), FR-08.7
  - **Dependencies:** T008
  - **Work:**
    - In `AttendanceMarkRepository`, verify `deleteMark(teamId, sessionId, studentId)` is implemented (from T008)
    - In attendance marking Cubit/BLoC:
      - If current mark status == tapped status → call `deleteMark()` (delete document)
      - If current mark status != tapped status → call `updateMark()` (change status)
      - If no current mark → call `createMark()` (create document)
  - **Files:** `lib/features/attendance/presentation/bloc/attendance_marking_cubit.dart` (modify or create)
  - **Definition of Done:**
    - Tap "present" on unmarked student → mark doc created with status="present"
    - Tap "present" on already-present student → mark doc DELETED
    - Tap "late" on present student → mark doc updated to status="late"
  - **Tests:** Cubit test verifying all 3 scenarios
  - **Agent:** Gemini ✅

- [x] T031 [US5] Write tests for mark toggle logic
  - **Purpose:** All 3 toggle paths verified. [P4-T5 test]
  - **Dependencies:** T030
  - **Files:** `test/features/attendance/presentation/bloc/attendance_marking_cubit_test.dart` (new)
  - **Agent:** Codex ✅

- [x] T032 [US5] Implement attendance marking screen (real-time roster)
  - **Purpose:** Per FR-08.6, AC-05.4 — real-time roster display with mark buttons. [P4 UI]
  - **Refs:** Spec AC-05.1–AC-05.6, FR-08.6
  - **Dependencies:** T008, T009, T030
  - **Work:**
    - Build or refactor `lib/features/attendance/presentation/screens/attendance_marking_screen.dart`
    - Stream-driven roster list (real-time updates within 5 seconds)
    - Each student row: name + present button + late button (toggle behavior per T030)
    - Session read-only guard: if `isClosed || now > endsAt` → mark buttons disabled
    - Permission guard: only assigned servant or admin can mark
  - **Files:** `lib/features/attendance/presentation/screens/attendance_marking_screen.dart`
  - **Definition of Done:**
    - Real-time updates visible within 5 seconds
    - Mark buttons disabled outside session window
    - Only authorized users see mark buttons
  - **Tests:** Widget test with mock Cubit
  - **Agent:** Gemini ✅

- [x] T033 [US5] Implement session creation screen
  - **Purpose:** Per AC-05.1, AC-05.2, AC-05.7 — UI for creating sessions. [P4 UI]
  - **Dependencies:** T028
  - **Work:**
    - Screen: team selector (from assignedTeamIds), date picker, time picker, duration input, title
    - On submit: call `AttendanceSessionService.createSessionWithRosterSnapshot()`
    - Show error if overlap detected
  - **Files:** `lib/features/attendance/presentation/screens/session_creation_screen.dart` (new or modify)
  - **Definition of Done:** Session created from UI with validation
  - **Tests:** Widget test
  - **Agent:** Gemini ✅

- [x] T034 [US5] Add attendance routes to AppRouter
  - **Purpose:** Wire attendance screens into navigation. [P4 routing]
  - **Dependencies:** T032, T033
  - **Work:**
    - Add routes: `/teams/:teamId/sessions/new`, `/teams/:teamId/sessions/:sessionId/mark`
    - Guard: servant must be assigned to team, or user is admin
  - **Files:** `lib/core/routing/app_router.dart`
  - **Definition of Done:** Navigation to attendance screens works from servant dashboard
  - **Agent:** Gemini ✅

- [x] T035 [US5] Register attendance Cubit/BLoC in DI
  - **Purpose:** Wire new state management into GetIt. [P4 DI]
  - **Dependencies:** T030, T032
  - **Files:** `lib/core/di/injection.dart`
  - **Agent:** Gemini ✅

- [x] T036 [US5] Write widget test for attendance marking screen
  - **Purpose:** Verify UI behavior. [P4 test]
  - **Dependencies:** T032
  - **Files:** `test/features/attendance/presentation/screens/attendance_marking_screen_test.dart` (new)
  - **Agent:** Codex ✅

---

## Phase 5: Feature Screens (US-06 through US-10)

> **Goal:** Complete remaining user stories — history views, profiles, dashboard.
> **Agent:** Gemini (BLoC logic) + Codex (test generation).

- [x] T037 [P] [US6] Implement AttendanceHistoryCubit
  - **Purpose:** Per AC-06.1–06.4 — servant views past sessions. [P4-T2]
  - **Refs:** Spec US-06, FR-09.1
  - **Dependencies:** T007
  - **Work:**
    - Create `lib/features/attendance/presentation/bloc/attendance_history_cubit.dart`
    - States: `Initial`, `Loading`, `Loaded(sessions)`, `Error(message)`
    - Method: `loadSessionsForTeam(teamId)` → returns sessions reverse-chronological
    - Each session includes: date, title, present/late/absent counts
  - **Files:** `lib/features/attendance/presentation/bloc/attendance_history_cubit.dart` (new)
  - **Definition of Done:** Cubit emits correct states for loaded/empty/error
  - **Tests:** `bloc_test` with mock repo
  - **Agent:** Gemini ✅

- [x] T038 [P] [US6] Refine attendance history screen
  - **Purpose:** Wire AttendanceHistoryCubit to existing screen. [P4 UI]
  - **Dependencies:** T037
  - **Work:**
    - Update `lib/features/attendance/presentation/screens/attendance_history_screen.dart`
    - List sessions with date/title/counts, tap to expand marks
    - Permission: servant sees only their team(s)
  - **Files:** `lib/features/attendance/presentation/screens/attendance_history_screen.dart`
  - **Agent:** Gemini ✅

- [ ] T039 [P] [US6] Write tests for AttendanceHistoryCubit
  - **Dependencies:** T037
  - **Files:** `test/features/attendance/presentation/bloc/attendance_history_cubit_test.dart` (new)
  - **Agent:** Codex ✅

- [x] T040 [P] [US7] Implement student profile screen (read-only)
  - **Purpose:** Per AC-07.1, AC-07.2 — student views own profile. [P4-T4]
  - **Refs:** Spec US-07
  - **Dependencies:** None (uses existing student data)
  - **Work:**
    - Create or update `lib/features/student/presentation/screens/student_profile_screen.dart`
    - Display: name, phone, parent contacts, grade, education stage, team name, father of confession
    - All fields READ-ONLY
    - Route: `/student/profile` accessible by student role only
  - **Files:** `lib/features/student/presentation/screens/student_profile_screen.dart`
  - **Definition of Done:** All fields displayed, no edit buttons present
  - **Tests:** Widget test
  - **Agent:** Gemini ✅

- [x] T041 [P] [US7] Add student profile route to AppRouter
  - **Dependencies:** T040
  - **Files:** `lib/core/routing/app_router.dart`
  - **Agent:** Gemini ✅

- [ ] T042 [P] [US7] Write widget test for student profile screen
  - **Dependencies:** T040
  - **Files:** `test/features/student/presentation/screens/student_profile_screen_test.dart` (new)
  - **Agent:** Codex ✅

- [x] T043 [P] [US8] Implement student attendance view Cubit
  - **Purpose:** Per AC-08.1–08.3 — student views own attendance. [P4]
  - **Refs:** Spec US-08
  - **Dependencies:** T007
  - **Work:**
    - Create `lib/features/attendance/presentation/bloc/student_attendance_cubit.dart`
    - Input: studentId (from AuthBloc)
    - Output: list of sessions they were part of + per-session status + summary stats (% present/late/absent)
    - Permission: only own data (query filtered by studentId in marks subcollection)
  - **Files:** `lib/features/attendance/presentation/bloc/student_attendance_cubit.dart` (new)
  - **Agent:** Gemini ✅

- [x] T044 [P] [US8] Implement student attendance screen
  - **Dependencies:** T043
  - **Files:** `lib/features/attendance/presentation/screens/student_attendance_screen.dart` (new)
  - **Agent:** Gemini ✅

- [ ] T045 [P] [US8] Write tests for student attendance Cubit
  - **Dependencies:** T043
  - **Files:** `test/features/attendance/presentation/bloc/student_attendance_cubit_test.dart` (new)
  - **Agent:** Codex ✅

- [ ] T046 [US9] Implement forced password reset screen
  - **Purpose:** Per INV-09, AC-09.5 — restored users must reset password first. [P4-T3]
  - **Refs:** Spec FR-11.4, AC-09.5
  - **Dependencies:** T023
  - **Work:**
    - Create `lib/features/auth/presentation/screens/forced_password_reset_screen.dart`
    - Screen shows: "Your password has been reset. Please set a new password."
    - Form: new password + confirm password
    - On success: clear `restorePendingPasswordReset` flag on Users doc, navigate to home
  - **Files:** `lib/features/auth/presentation/screens/forced_password_reset_screen.dart` (new)
  - **Agent:** Gemini ✅

- [ ] T047 [US9] Add forced password reset route guard in AppRouter
  - **Purpose:** Block navigation until password reset complete.
  - **Dependencies:** T046
  - **Work:**
    - In `AppRouter`, add redirect logic: if `user.restorePendingPasswordReset == true` → redirect to forced reset screen
  - **Files:** `lib/core/routing/app_router.dart`
  - **Agent:** Gemini ✅

- [ ] T048 [US9] Write widget test for forced password reset screen
  - **Dependencies:** T046
  - **Files:** `test/features/auth/presentation/screens/forced_password_reset_screen_test.dart` (new)
  - **Agent:** Codex ✅

- [ ] T049a [US9] Implement archive servant UI with confirmation dialog
  - **Purpose:** Admin can archive a servant with confirmation. [ANALYSIS FIX H5 split]
  - **Refs:** Spec FR-04.4, NFR-05.3
  - **Dependencies:** T022
  - **Work:**
    - In admin servant list screen: add archive button
    - On tap: show confirmation dialog (Arabic text) per NFR-05.3
    - On confirm: call `archiveManagedUser` Cloud Function
    - Show success/error feedback
  - **Files:** Modify existing admin servant list screen
  - **Definition of Done:** Archive button visible, confirmation shown, CF called
  - **Tests:** Widget test verifying dialog + CF call
  - **Agent:** Gemini ✅

- [ ] T049b [US9] Implement restore servant UI
  - **Purpose:** Admin can restore an archived servant. [ANALYSIS FIX H5 split]
  - **Refs:** Spec FR-04.5
  - **Dependencies:** T023
  - **Work:**
    - In archived servants list: add restore button
    - On tap: show confirmation dialog
    - On confirm: call `restoreManagedUser` Cloud Function
  - **Files:** Modify existing admin servant list screen
  - **Agent:** Gemini ✅

- [ ] T049c [US9] Implement archive student UI with confirmation dialog
  - **Purpose:** Admin can archive a student with confirmation. [ANALYSIS FIX H5 split]
  - **Refs:** Spec FR-03.1, NFR-05.3
  - **Dependencies:** T022
  - **Work:**
    - In admin student list screen: add archive button with confirmation dialog
    - On confirm: call `archiveManagedUser` Cloud Function
  - **Files:** Modify existing admin student list screen
  - **Agent:** Gemini ✅

- [ ] T049d [US9] Implement restore student UI
  - **Purpose:** Admin can restore an archived student. [ANALYSIS FIX H5 split]
  - **Dependencies:** T023
  - **Work:**
    - In archived students list: add restore button with confirmation dialog
    - On confirm: call `restoreManagedUser` Cloud Function
  - **Files:** Modify existing admin student list screen
  - **Agent:** Gemini ✅

- [ ] T050 [US9] Write tests for archive/restore UI flows
  - **Dependencies:** T049a, T049b, T049c, T049d
  - **Work:** Widget tests for all 4 archive/restore screens (dialog shown, CF called, feedback displayed)
  - **Files:** `test/features/admin/presentation/screens/` (new test files)
  - **Agent:** Codex ✅

- [ ] T051 [P] [US10] Implement GetDashboardStatsUseCase
  - **Purpose:** Per AC-10.1 — aggregated dashboard metrics. [P4-T1]
  - **Refs:** Spec US-10, FR-10.1–10.3
  - **Dependencies:** T010, T011
  - **Work:**
    - Create `lib/features/admin/domain/usecases/get_dashboard_stats_usecase.dart`
    - Returns `DashboardStats`: activeStudentCount, activeServantCount, activeTeamCount, sessionsThisMonth, pendingRestoreUsers
    - Uses streams from: `IStudentRepository`, `IServantRepository`, `ITeamRepository`
  - **Files:** `lib/features/admin/domain/usecases/get_dashboard_stats_usecase.dart` (new)
  - **Agent:** Gemini ✅

- [ ] T052 [P] [US10] Implement AdminDashboardCubit
  - **Dependencies:** T051
  - **Files:** `lib/features/admin/presentation/bloc/admin_dashboard_cubit.dart` (new or modify)
  - **Agent:** Gemini ✅

- [ ] T053 [P] [US10] Update admin dashboard screen with live counts
  - **Dependencies:** T052
  - **Files:** `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`
  - **Agent:** Gemini ✅

- [ ] T054 [P] [US10] Write tests for dashboard Cubit
  - **Dependencies:** T052
  - **Files:** `test/features/admin/presentation/bloc/admin_dashboard_cubit_test.dart` (new)
  - **Agent:** Codex ✅

---

## Phase 6: Degraded Mode & Connectivity (US-11)

- [ ] T055 [US11] Implement ConnectivityBanner widget
  - **Purpose:** Per AC-11.1, NFR-02.3 — visible offline/degraded indicator. [P5-T3]
  - **Refs:** Spec US-11
  - **Dependencies:** T015
  - **Work:**
    - Create `lib/core/widgets/connectivity_banner.dart`
    - States: Online (hidden), Offline (amber banner), Degraded (red banner with "writes disabled")
    - Positioned at top of app shell, below AppBar
    - Reads from `AuthFreshnessPolicy.canPerformWrites` + connectivity state
  - **Files:** `lib/core/widgets/connectivity_banner.dart` (new)
  - **Agent:** Gemini ✅

- [ ] T056 [US11] Integrate ConnectivityBanner into app shell
  - **Dependencies:** T055
  - **Work:** Add banner to root scaffold/shell. Wrap write-performing buttons with `canPerformWrites` check.
  - **Files:** Root app widget or shell scaffold
  - **Agent:** Gemini ✅

- [ ] T057 [US11] Implement write guard for degraded mode
  - **Purpose:** Per AC-11.3 — disable write buttons when auth stale.
  - **Dependencies:** T015, T055
  - **Work:**
    - Create `lib/core/widgets/write_guard.dart` — wrapper widget that disables its child when `canPerformWrites == false`
    - Apply to: mark buttons, session create button, student create button
  - **Files:** `lib/core/widgets/write_guard.dart` (new)
  - **Agent:** Gemini ✅

- [ ] T058 [US11] Write tests for ConnectivityBanner
  - **Dependencies:** T055
  - **Files:** `test/core/widgets/connectivity_banner_test.dart` (new)
  - **Agent:** Codex ✅

- [ ] T059 [US11] Write tests for write guard behavior
  - **Dependencies:** T057
  - **Files:** `test/core/widgets/write_guard_test.dart` (new)
  - **Agent:** Codex ✅

---

## Phase 7: Hardening, Cleanup & Verification

> **Goal:** Global error handling, cleanup, and final verification.
> **Agent:** Mixed assignments.

- [ ] T060 Configure global error handlers in main.dart
  - **Purpose:** Per P15 — catch unhandled errors. [P5-T1]
  - **Dependencies:** None
  - **Work:**
    - In `main.dart`, add `FlutterError.onError = (details) { debugPrint(...) }`
    - Add `PlatformDispatcher.instance.onError = (error, stack) { debugPrint(...); return true; }`
  - **Files:** `lib/main.dart`
  - **Agent:** Gemini ✅

- [ ] T061 [P] Add repository write logging
  - **Purpose:** Per P15 — debug logging for every Firestore write. [P5-T2]
  - **Dependencies:** None
  - **Work:**
    - In all repositories: add `debugPrint('[WRITE] collection/docId: $operation')` before each Firestore set/update/delete
    - Only in `kDebugMode`
  - **Files:** All repository files
  - **Agent:** Gemini ✅

- [ ] T062 [P] Verify edge case: empty roster session creation (EC-01)
  - **Purpose:** Confirm EC-01 is handled.
  - **Dependencies:** T028
  - **Work:** Verify that `createSessionWithRosterSnapshot()` rejects creation when no active students exist in team.
  - **Tests:** Already covered by T029. Verify test exists and passes.
  - **Agent:** Codex ✅

- [ ] T063 [P] Verify edge case: session duration validation (EC-09)
  - **Dependencies:** T028
  - **Work:** Verify `durationMinutes > 0` validation exists in session creation and Firestore rules.
  - **Agent:** Codex ✅

- [ ] T064 Remove unused dependencies
  - **Purpose:** Close D-03, D-04 — unused packages. [P6-T3]
  - **Dependencies:** All feature tasks complete
  - **Work:**
    - Check if `injectable` is used anywhere → if not, remove from pubspec.yaml
    - Check if `hive`/`hive_flutter` is used → if not, remove
    - Run `flutter pub get` to verify clean dependency tree
  - **Files:** `pubspec.yaml`
  - **Agent:** Gemini ✅

- [ ] T065 Run build_runner to verify generated files
  - **Purpose:** Ensure all Freezed/generated files are current. [P6-T4]
  - **Dependencies:** All feature tasks
  - **Work:** `flutter pub run build_runner build --delete-conflicting-outputs`
  - **Definition of Done:** No changes to generated files
  - **Agent:** Gemini ✅

- [ ] T066 Run flutter analyze — fix all warnings
  - **Dependencies:** T065
  - **Work:** `flutter analyze` exits clean on all changed files
  - **Agent:** Gemini ✅

- [ ] T067 Firestore rules emulator full test suite
  - **Purpose:** Verify every rule path. [P6-T2]
  - **Dependencies:** T003, T004
  - **Work:**
    - Test all permission matrix entries from spec section 11
    - Admin can read/write everything
    - Servant can only access assigned teams
    - Student can only read own data
    - No client can write to audit_logs
  - **Files:** `test/firestore_rules/` (new directory)
  - **Agent:** Codex ✅ | **HUMAN REVIEW required**

- [ ] T068 Final integration smoke test
  - **Purpose:** End-to-end verification. [P6-T1]
  - **Dependencies:** ALL previous tasks
  - **Work:**
    - Test flow: admin creates servant → assigns to team → servant creates session → marks attendance → admin views history
    - Test flow: admin archives servant → verify team unassigned → restore → verify no team assignment
    - Test flow: offline scenario → cached data visible → writes blocked after 15-min window
  - **Definition of Done:** All 3 flows pass end-to-end
  - **Agent:** **HUMAN** — manual acceptance testing

---

## Added Tasks (Analysis Remediation)

> Tasks T069–T077 were added after cross-artifact consistency analysis.
> They close coverage gaps identified in findings C1, C2, C4, H1, H2, H5, H6, H7.

- [x] T073 Wire StudentLinkedUserSyncService into student update flow
  - **Purpose:** Per FR-03.3 — student name change MUST sync to linked Users doc. [ANALYSIS FIX C2]
  - **Refs:** Spec FR-03.3, INV-01
  - **Dependencies:** T013
  - **Work:**
    - Verify that `StudentLinkedUserSyncService.syncToUser()` is called from the student update flow
    - If NOT called: add call in `StudentRepository.updateStudent()` or `StudentService` after successful student doc write
    - If ALREADY called: document verification in this task's DoD
  - **Files:** `lib/features/student/data/` (repo or service)
  - **Definition of Done:**
    - Updating a student's name where `uid != null` → Users doc `name` field updated
    - Updating a student with `uid == null` → no sync, no error
  - **Tests:** Integration test with FakeFirebaseFirestore
  - **Agent:** Gemini ✅

- [x] T074 [P] Add session title validation (required field)
  - **Purpose:** Per updated FR-07.7 — title is REQUIRED for deterministic ID. [ANALYSIS FIX H3]
  - **Refs:** Spec FR-07.7 (updated), BR-15
  - **Dependencies:** T028
  - **Work:**
    - In session creation form: make title field required (non-empty, trimmed)
    - In `AttendanceSessionService.createSessionWithRosterSnapshot()`: validate `title.isNotEmpty`
    - In session creation screen: UI validation with Arabic error message
  - **Files:** `lib/features/attendance/data/services/attendance_session_service.dart`, session creation screen
  - **Definition of Done:** Empty title → rejected with Arabic error
  - **Tests:** Unit test for service validation + widget test for form validation
  - **Agent:** Gemini ✅

- [ ] T075 Implement student list search by name prefix
  - **Purpose:** Per FR-03.5 — student search by name prefix. [ANALYSIS FIX C4]
  - **Refs:** Spec FR-03.5
  - **Dependencies:** None (uses existing student data)
  - **Work:**
    - Add a normalized searchable field (`searchName`) on student documents, maintained in StudentRepository when creating/updating students. This field contains a lowercased, Unicode-normalized (NFD), diacritics-stripped form of the name.
    - In student list screen: add search text field at top
    - Server-side: perform range queries against `searchName` using `where('searchName', isGreaterThanOrEqualTo: normPrefix)` and `where('searchName', isLessThan: normPrefix + '\uf8ff')`
    - Client-side offline fallback: implement the same normalization function for local filtering so both server and offline filters use identical rules
  - **Files:** Student list screen + student repository
  - **Definition of Done:**
    - Typing prefix filters list in real-time
    - Works offline with cached data using identical normalization
    - Arabic names with/without diacritics match the same results
  - **Tests:** Widget test + unit test for query construction + unit test for normalization function
  - **Agent:** Gemini ✅

- [ ] T076 Implement student list lazy loading (pagination)
  - **Purpose:** Per FR-03.6 — lazy loading for churches with >100 students. [ANALYSIS FIX C4]
  - **Refs:** Spec FR-03.6, Constitution P11
  - **Dependencies:** T075
  - **Work:**
    - In student list screen: implement cursor-based pagination using `startAfterDocument`
    - Load 25 students per page
    - Use `ListView.builder` with scroll detection for infinite scroll
    - Show loading indicator during fetch
  - **Files:** Student list screen + student repository
  - **Definition of Done:**
    - List loads first 25 students, loads more on scroll
    - Works with search filter from T075
  - **Tests:** Widget test verifying pagination trigger
  - **Agent:** Gemini ✅

- [ ] T077 Add confirmation dialogs for all destructive operations
  - **Purpose:** Per NFR-05.3 — destructive operations MUST require confirmation. [ANALYSIS FIX H6]
  - **Refs:** Spec NFR-05.3
  - **Dependencies:** T049a, T049b, T032
  - **Work:**
    - Verify confirmation dialogs exist on: archive user, close session, delete mark (toggle-off)
    - Create shared `ConfirmationDialog` widget with Arabic text support
    - Wire into all destructive actions that don't already have confirmation
  - **Files:** `lib/core/widgets/confirmation_dialog.dart` (new), affected screens
  - **Definition of Done:**
    - Every destructive action listed in NFR-05.3 has a confirmation dialog
    - Dialogs use Arabic text
  - **Tests:** Widget test for shared dialog widget
  - **Agent:** Gemini ✅

---

## Dependency Graph

```
T001 ──────┬──→ T003 ──→ T006
           ├──→ T004 ──→ T006
T002 ──────┤         ┌──→ T006
           └─────────┘
T005 ──→ T007 ──→ T008 ──→ T009 ──→ T012
              └──→ T028 ──→ T029
                   └──→ T032 ──→ T034
T008 ──→ T030 ──→ T031
              └──→ T032 ──→ T035
T010 ──┬──→ T024 ──→ T025, T026
T011 ──┘         └──→ T027
T015 ──→ T016
     └──→ T055 ──→ T056, T057
T017 ──→ T018, T019
T020 ──→ T021
T022, T023 ──→ T046 ──→ T047 ──→ T049
T037, T043, T051 ──→ (parallel, no dep on each other)
ALL ──→ T064 ──→ T065 ──→ T066 ──→ T068
```

## Parallel Execution Opportunities

| Parallel Group | Tasks | Rationale |
| -------------- | ----- | --------- |
| Security fixes | T001, T002, T005 | Independent infrastructure changes |
| Domain interfaces | T010, T011 | Independent new files |
| Test backfill | T013, T014 | Independent test files, no code changes |
| Backend functions | T017–T023 | Parallel after T006 completes |
| Student stories | T040, T043 | Independent features, no shared state |
| Dashboard | T051–T054 | Independent of attendance features |
| Connectivity | T055–T059 | Independent of feature screens |
| Edge case verification | T062, T063 | Independent checks |

## Agent Assignment Summary

| Agent | Task Count | Task IDs |
| ----- | ---------- | -------- |
| **Gemini** | 44 | T001–T012, T015, T017–T028, T030, T032–T035, T037–T038, T040–T041, T043–T044, T046–T047, T049, T051–T053, T055–T057, T060–T061, T064–T066 |
| **Codex** | 18 | T013, T014, T016, T025, T029, T031, T036, T039, T042, T045, T048, T050, T054, T058, T059, T062, T063, T067 |
| **Human** | 6 | T006 (deploy), T002 review, T003 review, T022 review, T024 review, T068 (acceptance) |

## MVP Scope (Minimum Viable First Deploy)

**Phase 0 (T001–T006)** + **Phase 2 subset (T007–T012)** = Security fixes + clean architecture.
This gets the app to a secure, well-structured baseline with no feature regressions.

**First feature increment:** Phase 4 core (T024–T036) = Transactional team assignment + attendance marking.
This delivers the primary value proposition: reliable attendance tracking.
