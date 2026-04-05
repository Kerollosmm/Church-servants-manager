# Implementation Plan: CSMS Full System

**Feature:** Church Servant & Student Management System
**Spec:** [spec.md](./spec.md)
**Constitution:** [constitution.md](../../memory/constitution.md)
**Plan Version:** 1.0.0
**Created:** 2026-04-04

---

## Constitution Check

| Principle | Relevance | Compliance Strategy |
| --------- | --------- | ------------------- |
| P01: Clean Architecture | HIGH | All phases follow presentation→domain→data slicing |
| P02: SRP | HIGH | AttendanceRepository (1002 lines) must be split in Phase 1 |
| P04: Auth Boundaries | CRITICAL | Phase 0 fixes Firestore rules deployment gap |
| P05: Server-Auth Mutations | CRITICAL | Phase 0 adds missing Cloud Functions for student provisioning |
| P06: No Duplicate Writes | HIGH | Denormalized field update owners documented per phase |
| P07: Test-First | HIGH | Every phase includes test tasks before or alongside code |
| P08: Incremental Delivery | CRITICAL | 6 phases, each merge-safe and rollback-safe |
| P12: Predictable Bloc | HIGH | Existing BLoCs audited in Phase 1; new ones follow sealed pattern |
| P13: Repo/Service Discipline | HIGH | Phase 1 splits AttendanceRepository into repo + service |
| P14: Firebase Safety | CRITICAL | Phase 0 wires firestore.rules; transactions specified per FR-06 |
| P16: Naming Consistency | MEDIUM | All new files follow convention; existing legacy names preserved |

---

## Technical Context

### What Exists (Do NOT Rewrite)

| Component | Path | Status |
| --------- | ---- | ------ |
| AuthBloc + states | `features/auth/` | Working. Sealed states. Keep as-is. |
| AuthService + providers | `features/auth/data/services/` | Working. Minor refactor for degraded mode. |
| StudentDataRepository | `features/student/data/repos/` | Working. Has domain interface (IStudentRepository). |
| StudentQueryService | `features/student/data/services/` | Working. Firestore query delegation. |
| StudentLinkedUserSyncService | `features/student/data/services/` | Working but UNTESTED (D-07). Needs tests. |
| ServantDataRepository | `features/servant/data/repo/` | Working. No domain interface yet. |
| TeamRepository | `features/team/data/repos/` | Working. No domain interface. |
| AdminTeamService | `features/admin/data/` | Working. Orchestrates team + membership. |
| AdminTeamMembershipService | `features/admin/data/` | Working. Cross-doc updates. |
| AdminUserProvisioningService | `features/auth/data/services/` | Working. Calls Cloud Functions. |
| AppRouter (go_router) | `core/routing/` | Working. Role-gated. |
| DI Container (injection.dart) | `core/di/` | Working. Manual wiring with GetIt. |
| firestore.rules | root | Working but NOT deployed via firebase.json (SEC-01). |
| Cloud Functions (4 callables) | `functions/src/` | Working. Missing Firestore re-validation (SEC-02). |

### What Must Be Refactored First (Phase 1 Prerequisite)

| Component | Issue | Action |
| --------- | ----- | ------ |
| `firebase.json` | Missing `firestore` deployment config | Add `firestore.rules` + `firestore.indexes.json` stanza |
| Cloud Functions `requireAdmin()` | Checks claims first, then Firestore — but doesn't check `isArchived` from Firestore | Add archive-state check from Firestore doc |
| `AttendanceRepository` (1002 lines) | Violates P02 (SRP). Contains session CRUD + mark CRUD + history queries + overlap detection | Split into: `AttendanceSessionRepository`, `AttendanceMarkRepository`, `AttendanceSessionService` |
| `validSelfUserCreate` in firestore.rules | Allows self-registration (student role) | Remove or restrict (Q4 decision: no self-registration) |
| `attendace_recourd/` directory | Stale typo directory | Delete |

### What Should Be Server-Authoritative

| Operation | Current | Target |
| --------- | ------- | ------ |
| Create servant account | Cloud Function (`createPrivilegedUser`) | Keep. Add students to same function. |
| Create student account (with auth) | Client-side + self-reg | NEW Cloud Function (`createStudentUser`) |
| Archive user | Cloud Function (`archiveManagedUser`) | Keep. Add team cleanup for servants. |
| Restore user | Cloud Function (`restoreManagedUser`) | Keep. Add password reset email trigger. |
| Role changes | Not implemented | NEW Cloud Function (`changeUserRole`) |
| Audit log writes | Not implemented | NEW Cloud Function trigger on user lifecycle |

### Where Transactions Are Required

| Operation | Documents Involved | Mechanism |
| --------- | ------------------ | --------- |
| Servant-to-team assignment | Team doc + new servant User + old servant User (up to 3) | `Firestore.runTransaction` (FR-06.2) |
| Servant-to-team unassignment | Team doc + servant User | `Firestore.runTransaction` (FR-06.4) |
| Session creation (overlap check) | Read existing sessions + write new session | `Firestore.runTransaction` (FR-07.2) |
| Servant archive (team cleanup) | Servant User + all assigned Team docs | `WriteBatch` (no read dependency after initial fetch) |

### Where Stale Cache Could Break Correctness

| Scenario | Risk | Mitigation |
| -------- | ---- | ---------- |
| Cached role after admin demotion | User sees admin screens | AuthBloc re-checks on foreground (FR-01.5) |
| Cached session after admin close | Servant tries to mark | Firestore rules reject; UI shows error (E-05) |
| Cached student list after archive | Archived student appears in session creation | Session creation reads server roster snapshot (BR-08) |
| Cached team assignment after unassign | Servant sees old team | Stream auto-reconnects on network resume |

### Where Async Race Conditions May Appear

| Scenario | Risk | Mitigation |
| -------- | ---- | ---------- |
| Two servants creating sessions for same team simultaneously | Duplicate sessions | Transaction with overlap check (FR-07.2) |
| Two admins assigning different servants to same team | Inconsistent assignment | Transaction with read-then-write (FR-06.2) |
| BLoC emits state after close() | StateError crash | All async ops check `isClosed` (P12) |
| AuthBloc sign-out while write is in-flight | Write succeeds but user sees login screen | Queued write syncs silently; no user impact |

---

## Phased Rollout Plan

### Phase 0: Infrastructure & Security Fixes

**Goal:** Fix all security blockers and infrastructure gaps before any feature work.
**Rollback:** Revert firebase.json + functions deployment. No client changes.
**Duration Estimate:** 1–2 days

#### P0-T1: Wire Firestore Rules into firebase.json

- **Intent:** Enable `firebase deploy --only firestore` to deploy rules from version control.
- **Responsibility:** Infrastructure configuration.
- **Files:** `firebase.json`
- **Change:**
  ```json
  {
    "firestore": {
      "rules": "firestore.rules",
      "indexes": "firestore.indexes.json"
    }
  }
  ```
- **Create:** `firestore.indexes.json` (empty indexes file for now).
- **Acceptance Criteria:**
  - `firebase deploy --only firestore:rules` succeeds.
  - Rules in Firebase Console match the committed `firestore.rules`.
- **Test:** Manual deployment verification.
- **Risk:** LOW. Additive config change.

#### P0-T2: Harden Cloud Function Authorization

- **Intent:** Close SEC-02: callable functions must re-validate archive state from Firestore.
- **Responsibility:** Backend security hardening.
- **Files:** `functions/src/index.ts`, `functions/src/lifecycle_helpers.ts`
- **Change:** Update `requireAdmin()` to also check `isArchived != true` from the Firestore user doc.
- **Acceptance Criteria:**
  - An archived admin's call to any callable function returns `permission-denied`.
  - A non-archived admin's call succeeds.
- **Test:** Add Firebase Functions test in `functions/tests/` with mock auth context.
- **Risk:** MEDIUM. Must not break existing admin operations.

#### P0-T3: Update Firestore Rules — Remove Self-Registration Path

- **Intent:** Per clarification Q4, remove `validSelfUserCreate()` since no self-registration exists.
- **Responsibility:** Security rules alignment with spec.
- **Files:** `firestore.rules`
- **Change:** Remove `validSelfUserCreate(userId)` from Users create rule. Only admins create users.
  ```
  allow create: if isAdmin();
  ```
- **Acceptance Criteria:**
  - A non-admin user cannot create a Users document.
  - Admin-created users still work via Cloud Functions (functions use Admin SDK, bypass rules).
- **Test:** Firestore rules emulator test.
- **Risk:** MEDIUM. Must verify Cloud Functions use Admin SDK (they do — `adminDb` bypasses rules).

#### P0-T4: Add Firestore Rules for Read-Model Collections

- **Intent:** Enforce INV-07: audit_logs, attendance_history, attendance_stats are backend-only.
- **Files:** `firestore.rules`
- **Change:** Add deny-all-client-writes rules for read-model collections:
  ```
  match /audit_logs/{logId} {
    allow read: if isAdmin();
    allow write: if false; // Backend-only via Admin SDK
  }
  ```
- **Acceptance Criteria:** Client writes to `audit_logs` are rejected.
- **Test:** Firestore rules emulator test.
- **Risk:** LOW. These collections may not exist yet; rules are pre-emptive.

#### P0-T5: Delete Stale Directory

- **Intent:** Remove `attendace_recourd/` (D-05).
- **Files:** Delete `lib/features/attendance_record/` (stale typo directory)
- **Risk:** LOW. Verify no imports reference it.

---

### Phase 1: Core Refactoring (No New Features)

**Goal:** Restructure existing code to support safe feature development. App behavior is UNCHANGED after this phase.
**Rollback:** Revert commits. All changes are internal refactors.
**Duration Estimate:** 3–5 days

#### P1-T1: Split AttendanceRepository (SRP Fix)

- **Intent:** Break the 1002-line god class into focused components per P02/P13.
- **Responsibility:** Data layer restructuring.
- **Boundary:** No domain or presentation changes. Same external API surface.
- **Files Created:**
  - `features/attendance/data/repos/attendance_session_repository.dart` — Session CRUD + overlap detection.
  - `features/attendance/data/repos/attendance_mark_repository.dart` — Mark CRUD (create, update, delete).
  - `features/attendance/data/services/attendance_session_service.dart` — Session lifecycle orchestration (create with roster snapshot, close, reopen).
- **Files Modified:**
  - `features/attendance/data/repos/attendance_repository.dart` — Thin facade delegating to new repos.
  - `core/di/injection.dart` — Register new repos/services.
- **Inputs/Outputs:** Same Firestore collections/subcollections. Same domain interfaces.
- **Failure Modes:** Regression in existing attendance functionality.
- **Test Implications:**
  - Move existing attendance tests to new repo test files.
  - Add unit tests for `AttendanceSessionService.createWithRosterSnapshot()`.
  - Verify `IAttendanceRepository` contract unchanged.
- **Acceptance Criteria:**
  - `flutter test` passes with zero regressions.
  - No file exceeds 300 lines (excluding generated code).
  - Each new class has a doc comment per P17.

#### P1-T2: Add Domain Interfaces for Servant and Team Repositories

- **Intent:** Align servant/team repos with IStudentRepository pattern (P01).
- **Files Created:**
  - `features/servant/domain/repos/i_servant_repository.dart`
  - `features/team/domain/repos/i_team_repository.dart`
- **Files Modified:**
  - `features/servant/data/repo/servant_data_repository.dart` — Implements `IServantRepository`.
  - `features/team/data/repos/team_repository.dart` — Implements `ITeamRepository`.
  - `core/di/injection.dart` — Register interface bindings.
- **Acceptance Criteria:**
  - Presentation layer can depend on interfaces, not concrete repos.
  - Existing BLoC/Cubit code compiles without changes.

#### P1-T3: Add Tests for StudentLinkedUserSyncService

- **Intent:** Close D-07: critical sync logic is untested.
- **Files Created:**
  - `test/features/student/data/services/student_linked_user_sync_service_test.dart`
- **Test Cases:**
  - Student name change propagates to Users doc.
  - Student without linked user (uid=null) does not attempt sync.
  - Firestore write failure is caught and logged, not thrown.
- **Acceptance Criteria:** ≥90% branch coverage on sync service.

#### P1-T4: Add Tests for AuthBloc Degraded Mode Path

- **Intent:** Close D-08: degraded mode has limited test coverage.
- **Files Created/Modified:**
  - `test/features/auth/presentation/bloc/auth_bloc_degraded_test.dart`
- **Test Cases:**
  - Profile fetch failure with valid cached user → `AuthDegraded` state.
  - Degraded state + write attempt → error.
  - Degraded state + network recovery → re-resolves to `AuthAuthenticated`.
  - 15-minute freshness window expiry → writes disabled.
- **Acceptance Criteria:** All degraded-mode state transitions have test coverage.

#### P1-T5: Add Offline/Degraded Mode Connectivity Tracking

- **Intent:** Implement the 15-minute auth freshness window from clarification Q1.
- **Files Modified:**
  - `features/auth/data/services/auth_service.dart` — Track `lastAuthValidatedAt`.
  - `features/auth/domain/` — Add `AuthFreshnessPolicy` class.
- **Inputs:** System clock, last successful auth validation timestamp.
- **Outputs:** `bool canPerformWrites` computed from freshness window.
- **Test Implications:** Unit test with mocked clock for time-based scenarios.

---

### Phase 2: Backend Enhancements

**Goal:** Add missing Cloud Functions and server-side logic.
**Rollback:** `firebase deploy --only functions` with previous version.
**Duration Estimate:** 2–3 days

#### P2-T1: Add Student User Provisioning Cloud Function

- **Intent:** Per FR-01.2 + Q4: admins create student accounts via backend.
- **Files Modified:** `functions/src/index.ts`, `functions/src/lifecycle_helpers.ts`
- **New Callable:** `createStudentUser`
  - Input: `{ email, name, group, classId?, ...studentFields }`
  - Creates Auth user → Sets claims (role=student) → Writes Users doc → Writes Students doc.
  - All within a single callable. Uses Admin SDK (bypasses Firestore rules).
- **Failure Modes:** Email exists → `already-exists` error, no partial data.
- **Test:** Functions test with emulator.

#### P2-T2: Enhance Archive Function — Servant Team Cleanup

- **Intent:** Per FR-04.4: archiving a servant must clear team assignments.
- **Files Modified:** `functions/src/index.ts`
- **Change:** `archiveManagedUser` checks if target is a servant. If so:
  - Read all teams where `assignedServantId == target.uid`.
  - Clear `assignedServantId`/`assignedServantName` on each team.
  - Clear `assignedTeamIds` on the servant's Users doc.
  - Use batched write for atomicity.
- **Failure Modes:** Partial team cleanup → batch ensures all-or-nothing.
- **Test:** Emulator test with servant assigned to 2 teams.

#### P2-T3: Add Audit Log Writing

- **Intent:** Per FR-12.5 + INV-07: backend-only audit logs.
- **Files Created:** `functions/src/audit.ts`
- **Change:** Add `writeAuditLog()` helper called by all lifecycle functions.
  - Fields: `action`, `actorUid`, `targetUid`, `timestamp`, `details`.
  - Collection: `audit_logs/{autoId}`.
- **Test:** Verify audit log written for create, archive, restore operations.

#### P2-T4: Add Password Reset Email on Restore

- **Intent:** Per FR-04.5/AC-09.4: restored users get password reset email.
- **Files Modified:** `functions/src/index.ts`
- **Change:** `restoreManagedUser` now calls `adminAuth.generatePasswordResetLink()` after re-enable.
- **Test:** Verify `restorePendingPasswordReset=true` is set on restored user.

---

### Phase 3: Data Layer — Transactions & Sync Contracts

**Goal:** Implement transactional writes and denormalized field update contracts.
**Rollback:** Revert data layer changes. No UI impact.
**Duration Estimate:** 3–4 days

#### P3-T1: Implement Transactional Servant-to-Team Assignment

- **Intent:** Per FR-06.2 + clarification Q3: transaction-based assignment.
- **Files Modified:**
  - `features/admin/data/admin_team_membership_service.dart`
- **Change:** Rewrite `assignServant()` to use `Firestore.runTransaction()`:
  1. Read: team doc, new servant User doc, old servant User doc (if exists).
  2. Write: update team assignedServantId/Name, update new servant assignedTeamIds, update old servant assignedTeamIds.
  3. Retry up to 3 times on contention (FR-06.5).
- **Inputs:** teamId, newServantUid
- **Outputs:** void (success) or typed failure (contention, not-found, archived).
- **Failure Modes:** Transaction contention → retry. Servant archived → reject.
- **Test:** FakeFirebaseFirestore transaction test. Concurrent modification test.

#### P3-T2: Implement Servant Name → Team Eager Update

- **Intent:** Per NFR-04.2(a) + BR-12: eager denormalized name update.
- **Files Modified:**
  - `features/servant/data/repo/servant_data_repository.dart` (single update owner — NOT in admin_team_service.dart)
- **Change:** When servant name is edited in the servant repository's name-update flow (e.g., `updateServantName` / `saveServant`), query all Team documents where `assignedServantId == servantUid` and update `assignedServantName` to the new value. Perform this as a best-effort operation that catches and logs failures via the repository logger. Follow the propagation pattern used by TeamRepository in P3-T3 for consistency.
- **Inputs:** servantUid, newName
- **Outputs:** void (best-effort; log failures)
- **Test:** Verify team doc updated after servant rename.

#### P3-T3: Implement Team Rename → Student team_name Eager Update

- **Intent:** Per NFR-04.2(b) + BR-16: eager denormalized name update.
- **Files Modified:** `features/team/data/repos/team_repository.dart`
- **Change:** When team name is changed, query all Students where `classId == teamId` and update `team_name`.
- **Inputs:** teamId, newName
- **Outputs:** void (batched write)
- **Test:** Verify student docs updated after team rename.

#### P3-T4: Implement Session Creation with Transaction (Overlap Check)

- **Intent:** Per FR-07.2: transactional session creation with overlap detection.
- **Files Modified:** `features/attendance/data/services/attendance_session_service.dart`
- **Change:** `createSession()` uses `Firestore.runTransaction()`:
  1. Read: all sessions for team on the same `dateKey`.
  2. Check: no time overlap with existing sessions.
  3. Write: new session document with roster snapshot.
- **dateKey definition:** `dateKey` is derived from the session's start datetime as `"YYYY-MM-DD"` (e.g., `2026-04-04`). It is computed from `startsAt.toLocal()` to ensure consistency. Sessions that span midnight are assigned to the dateKey of their **start date only**. Overlap checks are performed only against sessions sharing the same dateKey. This choice is documented and accepted: a session starting at 23:00 and ending at 01:00 the next day will only be checked for overlaps against other sessions on the start date.
- **Test:** Overlap detection unit tests. Empty roster edge case. Midnight-spanning session test.

---

### Phase 4: Domain & Presentation — Feature Completion

**Goal:** Complete UI screens, BLoC/Cubit logic, and routing for all roles.
**Rollback:** Feature flag all new screens. Revert UI code.
**Duration Estimate:** 5–7 days

#### P4-T1: Admin Dashboard — Live Counts

- **Intent:** Per FR-10.1–10.3: real-time dashboard metrics.
- **Layer:** Presentation + Domain
- **Files:**
  - `features/admin/presentation/bloc/admin_dashboard_cubit.dart`
  - `features/admin/presentation/screens/admin_dashboard_screen.dart` (modify existing)
  - `features/admin/domain/usecases/get_dashboard_stats_usecase.dart`
- **Inputs:** Stream<int> for each count (students, servants, teams, sessions).
- **Outputs:** `AdminDashboardState` with counts and pending-restore list.
- **Test:** Cubit test with mock streams.

#### P4-T2: Attendance History Screen — Per-Student View

- **Intent:** Per FR-09.2-09.3: student sees their own attendance.
- **Layer:** Presentation + Domain
- **Files:**
  - `features/attendance/presentation/screens/attendance_history_screen.dart` (modify)
  - `features/attendance/presentation/bloc/attendance_history_cubit.dart`
- **Inputs:** studentId
- **Outputs:** List of sessions with marks + summary stats.
- **Test:** Cubit test. Verify student can only see own data.

#### P4-T3: Forced Password Reset Flow

- **Intent:** Per INV-09 + FR-11.4: restored users must reset password first.
- **Layer:** Presentation + Auth Domain
- **Files:**
  - `features/auth/presentation/screens/forced_password_reset_screen.dart` (new)
  - `core/routing/app_router.dart` — Add route guard for `restorePendingPasswordReset`.
- **Test:** Widget test verifying navigation block until reset complete.

#### P4-T4: Student Profile Screen — Read-Only

- **Intent:** Per US-07: student views own profile.
- **Layer:** Presentation
- **Files:**
  - `features/student/presentation/screens/student_profile_screen.dart` (modify or create)
- **Test:** Widget test verifying all fields displayed, no edit buttons.

#### P4-T5: Mark Toggle-Off (Delete) Implementation

- **Intent:** Per clarification Q2 + FR-08.7: toggle-off deletes mark document.
- **Layer:** Data + Presentation
- **Files:**
  - `features/attendance/data/repos/attendance_mark_repository.dart` — Add `deleteMark()`.
  - `features/attendance/presentation/bloc/attendance_marking_cubit.dart` — Handle toggle-off.
- **Test:** Verify mark document deleted on second tap. Verify student reverts to unmarked.

---

### Phase 5: Observability & Hardening

**Goal:** Add logging, error boundaries, and edge case handling.
**Rollback:** Revert. No data model changes.
**Duration Estimate:** 2–3 days

#### P5-T1: Global Error Handlers

- **Intent:** Per P15: configure `FlutterError.onError` and `PlatformDispatcher.onError`.
- **Files:** `main.dart`
- **Test:** Verify unhandled errors are caught and logged.

#### P5-T2: Repository Write Logging

- **Intent:** Per P15: log every Firestore write with collection path and doc ID.
- **Files:** All repository files (add `debugPrint` in debug mode).
- **Test:** Verify log output in debug builds.

#### P5-T3: Connectivity Indicator Widget

- **Intent:** Per AC-11.1 + NFR-02.3: visible offline/degraded indicator.
- **Files:**
  - `core/widgets/connectivity_banner.dart` (new)
  - App shell widget (add banner overlay)
- **Test:** Widget test with mock connectivity state.

#### P5-T4: Edge Case Hardening

- **Intent:** Cover remaining edge cases from spec section 13.
- **Files:** Various (per edge case).
- **Edge cases to verify:**
  - EC-01: Empty roster session creation
  - EC-04: Servant archived while session open
  - EC-07: Long name truncation
  - EC-09: Session duration validation (>0)
  - EC-12: Password reset email failure handling

---

### Phase 6: Integration Testing & Cleanup

**Goal:** End-to-end verification. Remove tech debt. Final polish.
**Rollback:** No destructive changes in this phase.
**Duration Estimate:** 2–3 days

#### P6-T1: Integration Tests

- Full user lifecycle: admin creates servant → assigns to team → servant creates session → marks attendance → admin views history.
- Archive/restore cycle: archive servant → verify team unassigned → restore → verify no team assignment → admin re-assigns.
- Offline scenario: cached data available → writes blocked after 15-min window.

#### P6-T2: Firestore Rules Emulator Test Suite

- Test every rule path against the permissions matrix (section 11 of spec).
- Verify read-model collections deny client writes.

#### P6-T3: Remove Unused Dependencies

- Remove `injectable` package (D-03).
- Remove `hive`/`hive_flutter` (D-04) or implement if needed.

#### P6-T4: Build Runner + Lint Clean

- Run `build_runner build` to ensure all generated files are current.
- Run `flutter analyze` and fix all warnings in changed files.

---

## Risk Register

| ID | Risk | Probability | Impact | Mitigation |
| -- | ---- | ----------- | ------ | ---------- |
| R-01 | AttendanceRepository split introduces regression | MEDIUM | HIGH | Run full test suite after split. Keep facade for backward compat. |
| R-02 | Firestore rules change locks out existing users | LOW | CRITICAL | Test with emulator before deployment. Deploy rules before client. |
| R-03 | Transaction contention on team assignment | LOW | MEDIUM | 3-retry policy (FR-06.5). Monitor in production. |
| R-04 | Cloud Function deployment breaks existing callables | MEDIUM | HIGH | Version functions. Test with emulator. Deploy functions before client. |
| R-05 | 15-min freshness window too aggressive for slow church Wi-Fi | MEDIUM | MEDIUM | Make window configurable (start with 15 min, adjust based on feedback). |
| R-06 | Removing self-registration breaks existing student accounts | LOW | HIGH | Verify existing student Users docs are preserved. Only change rule for NEW creates. |
| R-07 | Eager denormalized updates miss some documents | LOW | MEDIUM | Query-then-batch pattern. Log failures. Add consistency check job (future). |
| R-08 | Mark deletion in offline mode creates sync conflict | LOW | MEDIUM | Firestore SDK handles delete-then-sync naturally. Test with emulator. |

---

## Deployment Order (Per HR-01)

```
Phase 0: firestore.rules → firestore.indexes.json → Cloud Functions → (no client changes)
Phase 1: Client refactoring only (no server changes)
Phase 2: Cloud Functions → (no client changes needed)
Phase 3: Client data layer only
Phase 4: Client presentation layer
Phase 5: Client hardening
Phase 6: Cleanup + integration testing → FINAL DEPLOY
```

**For each phase:**
1. Deploy Firestore rules/indexes first
2. Deploy Cloud Functions second
3. Deploy client app last

This ensures the backend is always ready before clients exercise new code paths.

---

## Testing Strategy

| Layer | Tool | Coverage Target |
| ----- | ---- | --------------- |
| Domain (use cases, policies) | `flutter test` + `mocktail` | 100% of business rules |
| Data (repositories, services) | `flutter test` + `fake_cloud_firestore` | 90% of CRUD operations |
| BLoC/Cubit | `bloc_test` | 100% of state transitions |
| Widgets | `flutter test` (widget tests) | Key screens + edge cases |
| Firestore Rules | Emulator + rules unit test lib | 100% of permission matrix |
| Cloud Functions | Emulator + mocha/jest | 100% of callable functions |
| Integration | Emulator + full user flows | 3 critical paths minimum |

---

## Observability Strategy

| Signal | Mechanism | Where |
| ------ | --------- | ----- |
| User lifecycle events | `audit_logs` collection (backend-only) | Cloud Functions |
| Session lifecycle events | `audit_events` subcollection | Cloud Functions (trigger on session write) |
| Client errors | `FlutterError.onError` → `debugPrint` (dev) | `main.dart` |
| Repository writes | `debugPrint` with collection/docId | All repositories |
| Connectivity state | `ConnectivityBanner` widget | App shell |
| Auth freshness | `AuthFreshnessPolicy` state | AuthBloc |

---

## Data Flow Changes (Key Modifications)

```
BEFORE:
  Student self-registers → AuthBloc → Users doc (client write) → No Students doc link

AFTER:
  Admin calls createStudentUser CF → Auth user + Users doc + Students doc (atomic, server-side)
  Student opens app → Login only → AuthBloc reads existing profile → Routed by role

BEFORE:
  Servant assigned to team → AdminTeamMembershipService → 2 loose writes (team + user)

AFTER:
  Admin assigns servant → AdminTeamMembershipService → Firestore.runTransaction → 3 atomic writes

BEFORE:
  Mark toggled off → unclear (no implementation)

AFTER:
  Mark toggled off → AttendanceMarkRepository.deleteMark() → Firestore document deleted
```

---

## Files Likely Affected (Summary)

### New Files (Estimated 15–20)

| File | Phase |
| ---- | ----- |
| `features/attendance/data/repos/attendance_session_repository.dart` | P1 |
| `features/attendance/data/repos/attendance_mark_repository.dart` | P1 |
| `features/attendance/data/services/attendance_session_service.dart` | P1 |
| `features/servant/domain/repos/i_servant_repository.dart` | P1 |
| `features/team/domain/repos/i_team_repository.dart` | P1 |
| `features/auth/domain/auth_freshness_policy.dart` | P1 |
| `features/auth/presentation/screens/forced_password_reset_screen.dart` | P4 |
| `features/admin/domain/usecases/get_dashboard_stats_usecase.dart` | P4 |
| `core/widgets/connectivity_banner.dart` | P5 |
| `functions/src/audit.ts` | P2 |
| `firestore.indexes.json` | P0 |
| + test files mirroring each new file | All |

### Modified Files (Estimated 15–20)

| File | Phase | Change |
| ---- | ----- | ------ |
| `firebase.json` | P0 | Add firestore stanza |
| `firestore.rules` | P0 | Remove self-reg, add audit rules |
| `functions/src/index.ts` | P0, P2 | Harden auth, add student CF, add audit |
| `core/di/injection.dart` | P1, P3 | Register new repos/services |
| `features/attendance/data/repos/attendance_repository.dart` | P1 | Thin to facade |
| `features/admin/data/admin_team_membership_service.dart` | P3 | Transactional assignment |
| `features/servant/data/repo/servant_data_repository.dart` | P1, P3 | Interface + name sync |
| `features/team/data/repos/team_repository.dart` | P1, P3 | Interface + rename sync |
| `features/auth/data/services/auth_service.dart` | P1 | Freshness tracking |
| `core/routing/app_router.dart` | P4 | Add forced-reset guard |
| `main.dart` | P5 | Global error handlers |

### Deleted Files

| File | Phase |
| ---- | ----- |
| `lib/features/attendance_record/` (entire directory) | P0 |
