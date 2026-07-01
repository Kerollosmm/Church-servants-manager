# CSMS Security Remediation - Tasks

**Status:** Ready for Execution  
**Generated:** 2026-06-28  
**Total Tasks:** 68  
**Estimated Effort:** 3-4 Sprints  

---

## Phase 1: Setup & Validation (No Story Label)

**Goal:** Establish baseline, validate current state, create safety nets before touching production code.

- [ ] T001 Read and understand all 10 critical security issues from SECURITY_REMEDIATION_PLAN.md
- [ ] T002 [P] Create a backup branch from main before any changes: `git checkout -b security-remediation-main`
- [ ] T003 Verify all Firestore composite indexes are properly defined in firestore.indexes.json
- [ ] T004 Run existing test suite and document baseline pass/fail rate
- [ ] T005 Audit all repositories for missing `syncStatus` field in Firestore writes
- [ ] T006 Document current DLQ behavior: verify if it's used in sync loop or decoration-only
- [ ] T007 Map all `searchStudents` call sites and verify they pass actor context
- [ ] T008 Verify `RoleUserRoute` BLoC lifecycle with Flutter DevTools memory profiler

---

## Phase 2: Foundational - Atomic Sync Foundation (No Story Label)

**Goal:** Fix the core sync engine to prevent duplicate writes, data loss, and race conditions. This MUST be done first as all other fixes depend on reliable sync.

- [ ] T009 [P] Create `lib/core/services/transaction_log_service.dart` - Transaction log pattern in Hive for atomic local/remote writes
- [ ] T010 [P] Create `lib/core/models/transaction_log_entry.dart` - Model for pending transactions with status enum: `pending`, `remote_success`, `local_success`, `failed`
- [ ] T011 Integrate TransactionLogService into SyncService: on any `enqueue`, write to transaction log first
- [ ] T012 Modify SyncService.processQueue to read from transaction log, not sync queue box directly
- [ ] T013 Update StudentDataRepository.createStudent to use transaction log pattern (write log -> Firestore -> update log -> local cache)
- [ ] T014 Update StudentDataRepository.updateStudent to use transaction log pattern
- [ ] T015 Handle rollback: if Firestore succeeds but local cache fails, mark as `local_fail` and alert user with retry UI
- [ ] T016 [P] Write unit tests for TransactionLogService covering: success, Firestore fail, local cache fail, rollback
- [ ] T017 [P] Write integration test: create student offline, go online, verify no duplicate writes in Firestore

---

## Phase 3: User Story 1 - [US1] Fix searchStudents Authorization (Critical)

**Story Goal:** Ensure servants can only search for students within their assigned scope (teams/classes).  
**Acceptance Criteria:**  
- A servant with Team A cannot search/find students in Team B  
- Admin can search all students  
- Query performance is acceptable (uses index)  
- Works offline (searches local cache first)  

- [ ] T018 [US1] Modify `StudentDataBloc._onSearchStudents` to extract `actor.effectiveAssignedTeamIds` and `actor.groupId`
- [ ] T019 [US1] Update `IStudentRepository.searchStudents` signature to accept `List<String> authorizedClassIds` and `String? groupId`
- [ ] T020 [US1] Update `StudentDataRepository.searchStudents` to filter by `authorizedClassIds` using Firestore `whereIn` (max 10 items)
- [ ] T021 [US1] **Constitution Check:** If a servant has >10 teams, implement fallback strategy: query by `groupId` instead, then client-side filter
- [ ] T022 [US1] Ensure offline search filters by authorized scope from local Hive cache
- [ ] T023 [US1] Add error handling for Firestore query failures (e.g., missing index)
- [ ] T024 [P] [US1] Write widget test: servant searches, results only show authorized students
- [ ] T025 [P] [US1] Write unit test: servant with 10+ teams falls back to group-based query
- [ ] T026 [P] [US1] Write integration test: create students in two teams, servant only sees their team

---

## Phase 4: User Story 2 - [US2] Implement Atomic Writes with Rollback (Critical)

**Story Goal:** Ensure Firestore write and local Hive cache are atomic (or safely recoverable).  
**Acceptance Criteria:**  
- If Firestore write succeeds but local cache fails, the app is in a recoverable state  
- If Firestore write fails, the sync engine retries safely without duplicates  
- The `syncStatus` field is written to Firestore and reliably tracked  

- [ ] T027 [US2] Add `syncStatus` and `clientUpdatedAt` to `StudentModel.toMap()` for Firestore writes
- [ ] T028 [US2] Update `StudentModel.fromMap()` to read `syncStatus` from Firestore back to local model
- [ ] T029 [US2] Modify `StudentDataRepository.createStudent` to write `syncStatus: 'pending'` before Firestore write
- [ ] T030 [US2] Modify `StudentDataRepository.createStudent` to update `syncStatus: 'synced'` only after Firestore and local cache succeed
- [ ] T031 [US2] Implement rollback logic: on local cache failure after Firestore success, mark transaction log as `local_fail` and show in UI
- [ ] T032 [US2] Update `StudentDataRepository.updateStudent` with same atomic write pattern
- [ ] T033 [US2] Update Firestore security rules to validate `request.resource.data.syncStatus` is present on all writes
- [ ] T034 [P] [US2] Write unit test: mock Firestore success + Hive failure, verify rollback state
- [ ] T035 [P] [US2] Write integration test: create student, verify syncStatus flow: pending -> synced in Firestore

---

## Phase 5: User Story 3 - [US3] Make Sync Engine Robust to Connectivity Manipulation (Critical)

**Story Goal:** The sync engine should not trust client-side connectivity state.  
**Acceptance Criteria:**  
- Sync queue is always written to locally, regardless of connectivity state  
- Sync engine processes queue based on handler success/failure, not connectivity checks  
- Handlers properly catch and categorize network errors for retry vs. DLQ  

- [ ] T036 [US3] Refactor `SyncService.enqueue` to ALWAYS write to sync queue, remove connectivity check
- [ ] T037 [US3] Refactor `SyncService.processQueue` to always attempt processing when triggered
- [ ] T038 [US3] Update `StudentSyncHandler.execute` to catch `FirebaseException` and categorize: network error (retry), permission denied (DLQ), other (DLQ)
- [ ] T039 [US3] Update `AttendanceSyncHandler.execute` with same error categorization
- [ ] T040 [US3] Verify all other sync handlers (Results, Teams, etc.) have proper error handling
- [ ] T041 [P] [US3] Write unit test: enqueue while offline, verify item is in queue
- [ ] T042 [P] [US3] Write unit test: mock connectivity as online but handler throws network error, verify retry logic

---

## Phase 6: User Story 4 - [US4] Integrate Dead Letter Queue (Important)

**Story Goal:** Permanently failed sync items are offloaded to DLQ to prevent queue bloat.  
**Acceptance Criteria:**  
- After max retries, failed items are moved to DLQ and removed from main queue  
- DLQ items are surfaced in UI with a count badge  
- User can manually retry all DLQ items  
- DLQ is capped at a reasonable size (e.g., 100 items) with FIFO eviction  

- [ ] T043 [US4] Modify `SyncService.processQueue` to call `_deadLetterQueue.add(entry)` after max retries
- [ ] T044 [US4] Implement `_deadLetterQueue.add` to remove the entry from the main sync queue box
- [ ] T045 [US4] Add DLQ count indicator to `SyncStatus` model
- [ ] T046 [US4] Update UI (e.g., `SyncStatusIndicator` widget) to display DLQ count badge
- [ ] T047 [US4] Add "Retry All" button in settings or sync status panel
- [ ] T048 [US4] Implement FIFO eviction logic: if DLQ > 100 items, remove oldest
- [ ] T049 [P] [US4] Write unit test: verify failed entry moves to DLQ after max retries
- [ ] T050 [P] [US4] Write unit test: verify DLQ eviction when max size exceeded

---

## Phase 7: User Story 5 - [US5] Reconcile Client-Side and Server-Side RBAC (Important)

**Story Goal:** `CanMutateStudentUseCase` logic perfectly matches `firestore.rules` logic.  
**Acceptance Criteria:**  
- All permission checks in `CanMutateStudentUseCase` are identical to Firestore rules  
- A servant with a single legacy `assignedTeamId` has the same permissions as one with `assignedTeamIds`  
- The app prevents UI actions that Firestore would reject  

- [ ] T051 [US5] Create `lib/docs/rbac_logic.md` documenting the shared RBAC ruleset
- [ ] T052 [US5] Verify `CanMutateStudentUseCase` checks all four scopes: `assignedSectorIds`, `effectiveAssignedTeamIds`, `assignedTeamId` (legacy), `groupId`
- [ ] T053 [US5] Update `CanMutateStudentUseCase` to handle the legacy `assignedTeamId` field consistently with `firestore.rules`
- [ ] T054 [US5] Add visual indicators in UI (e.g., disabled buttons) for actions the user cannot perform based on `CanMutateStudentUseCase`
- [ ] T055 [P] [US5] Write unit test: verify all RBAC permutations match between usecase and a mock of Firestore rules

---

## Phase 8: User Story 6 - [US6] Stabilize BLoC State and Lifecycle (Important)

**Story Goal:** Eliminate race conditions, memory leaks, and UI flickering.  
**Acceptance Criteria:**  
- `RoleUserRoute` BLoCs are created exactly once per feature activation  
- All async operations emit a loading state before the operation  
- Search results show a loading indicator  
- No memory leaks observed in DevTools profiler  

- [ ] T056 [US6] Refactor `RoleUserRoute` to `StatefulWidget`, create BLoCs in `initState`, dispose in `dispose()`
- [ ] T057 [US6] Add `StudentDataSearching` state to `StudentDataState` sealed class
- [ ] T058 [US6] In `_onSearchStudents`, emit `StudentDataSearching` before repository call
- [ ] T059 [US6] Verify all other BLoC async operations have corresponding loading states
- [ ] T060 [US6] Run DevTools memory profiler to verify no leaks after navigation
- [ ] T061 [P] [US6] Write widget test: verify loading state is shown during search

---

## Phase 9: Infrastructure - Composite Index & Performance (No Story Label)

**Goal:** Ensure Firestore queries are optimized and won't trigger collection scans.

- [ ] T062 Add composite index to `firestore.indexes.json` for `Students` collection: `classId` (Ascending), `name` (Ascending)
- [ ] T063 Deploy index: `firebase deploy --only firestore:indexes`
- [ ] T064 Verify `searchStudents` query uses the composite index in Firebase Console (Query Explain)
- [ ] T065 [P] Write a script to monitor Firestore read count during `searchStudents` execution

---

## Phase 10: Type Safety & Code Quality (No Story Label)

**Goal:** Improve long-term maintainability and prevent refactoring errors.

- [ ] T066 [P] Create abstract class `SyncPayload` and concrete implementations: `UpsertStudentPayload`, `ArchiveStudentPayload`, `MarkAttendancePayload`
- [ ] T067 [P] Update `SyncEntry` to hold `SyncPayload` instead of `Map<String, Object?>`
- [ ] T068 [P] Update all `*SyncHandler` classes to accept typed payloads
- [ ] T069 [P] Run `dart analyze` and fix all warnings
- [ ] T070 [P] Add `// coverage:ignore` comments to generated files to improve coverage report accuracy

---

## Phase 11: Verification & Sign-Off (No Story Label)

**Goal:** Confirm all critical issues are resolved before any release.

- [ ] T071 Manual penetration test: log in as servant, attempt to access students outside assigned scope (should fail in both UI and Firestore)
- [ ] T072 Test offline-first flow: create student offline, go online, verify single Firestore document with correct `syncStatus`
- [ ] T073 Monitor Firestore read/write counts during realistic 50-user scenario
- [ ] T074 Verify Spark plan quota is not at risk (reads < 50K/day for church of 50 users)
- [ ] T075 Final code review by senior developer focusing on Phase 1 and Phase 2 changes
- [ ] T076 Tag stable release: `git tag -a v1.0.1-security-remediation -m "Security and data integrity fixes"`

---

## Dependencies & Execution Order

```
Phase 1 (Setup)
    |
    v
Phase 2 (Foundational: Transaction Log)
    |
    v
+-- Phase 3 (US1: searchStudents Auth)
|   |
|   v
+-- Phase 4 (US2: Atomic Writes)
|   |
|   v
+-- Phase 5 (US3: Sync Engine Robustness)
|   |
|   v
+-- Phase 6 (US4: DLQ Integration)
|   |
|   v
+-- Phase 7 (US5: RBAC Reconciliation)
|   |
|   v
+-- Phase 8 (US6: BLoC Stabilization)
|   |
|   v
+-- Phase 9 (Infrastructure: Index)
|   |
|   v
+-- Phase 10 (Type Safety)
|   |
|   v
+-- Phase 11 (Verification)
```

## Parallel Execution Opportunities

The following tasks can be executed in parallel as they touch different files and have no shared dependencies:

1. **T002 (Backup branch)** + **T003 (Index check)** + **T007 (Search audit)**
2. **T018-T021 (US1 search logic)** + **T027-T030 (US2 syncStatus)**
3. **T043-T044 (DLQ logic)** + **T051-T053 (RBAC reconciliation)**
4. **T056 (BLoC lifecycle)** + **T062 (Composite index)**
5. **T066-T068 (Type safety)** + **T069 (Linting)**

## Suggested MVP Scope (First Deliverable)

**Phase 1 + Phase 2 + Phase 3 + Phase 4** (Tasks T001-T035)

This covers the most critical security and data integrity fixes and provides a stable foundation for the remaining user stories.
