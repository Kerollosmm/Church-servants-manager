# CSMS Security & Data Integrity Remediation Plan

## Verdict: No-Go for Production

**Date:** 2026-06-28
**Prepared by:** AI Code Review Agent
**Scope:** Entire CSMS Flutter + Firebase Codebase
**Plan Status:** Actionable, Phased Implementation

---

## 1. Executive Summary

This plan addresses critical security vulnerabilities and data integrity risks identified in a comprehensive code review of the Church Servants Management System (CSMS). The review found significant issues in Firestore security rules, offline synchronization logic, and client-side authorization that could lead to data leakage, unauthorized access, and data corruption.

## 2. Critical Security & Data Integrity Issues Summary

| ID | Severity | Issue | Primary File(s) | Impact |
|----|----------|-------|-----------------|--------|
| SEC-001 | **CRITICAL** | Data leakage risk in `searchStudents` | `student_data_bloc.dart` | Servants can search students outside their assigned scope |
| SEC-002 | **CRITICAL** | Duplicate write risk and state inconsistency | `student_data_repository.dart` | Network failure between Firestore write and local cache update causes data divergence |
| SEC-003 | **CRITICAL** | Client-side connectivity check is unreliable | `sync_service.dart` | Malicious clients can force offline behavior, bypassing online validation |
| SEC-004 | **CRITICAL** | `syncStatus` missing from Firestore writes | `student_model.dart`, `student_data_repository.dart` | Server cannot verify sync state; conflict resolution is impossible |
| SEC-005 | **CRITICAL** | BLoC state logic complexity and lack of loading states | `student_data_bloc.dart` | UI flickering, race conditions, incorrect data display |
| SEC-006 | **IMPORTANT** | Client-side RBAC logic diverges from Firestore rules | `can_mutate_student_usecase.dart` | Users see different permissions in UI vs. what Firestore enforces |
| SEC-007 | **IMPORTANT** | `searchStudents` query requires missing composite index | `student_query_service.dart` | Collection scan risk, high Firestore cost, potential query failures |
| SEC-008 | **IMPORTANT** | Dead Letter Queue (DLQ) not integrated into sync loop | `sync_service.dart` | Permanently failed entries never offloaded, storage bloat |
| SEC-009 | **IMPORTANT** | BLoC instances recreated on widget rebuild | `role_user_route.dart` | Potential memory leaks, state inconsistencies |
| SEC-010 | **SUGGESTION** | `SyncEntry.payload` lacks type safety | `sync_entry.dart` | Refactoring payload structure is error-prone |

---

## 3. Phased Remediation Plan

### Phase 1: Immediate Security Hardening (Critical - Must Fix Before Any Release)

**Goal:** Close critical security gaps and prevent data leakage or unauthorized access.

#### Step 1.1: Harden `searchStudents` Authorization (SEC-001)
**Objective:** Ensure servants can only search for students within their assigned teams/classes.
**File:** `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart`
**Action:**
1. Modify `_onSearchStudents` to explicitly pass the `actor`'s authorized scopes (`groupId`, `effectiveAssignedTeamIds`) to the repository.
2. Update `IStudentRepository.searchStudents` signature to include a `List<String> authorizedClassIds` parameter.
3. In `StudentDataRepository.searchStudents`, add a filter to the Firestore query: `where('classId', whereIn: authorizedClassIds)`.
4. **Constitution Check:** This uses single-document lookups and `whereIn` queries. `whereIn` is limited to 10 elements. Ensure `effectiveAssignedTeamIds` is capped at 10. If a servant manages more than 10 teams, this requires a different query strategy (e.g., a `ServantGroup` document containing all assigned student IDs, or splitting the query).
**Verification:** Unit test with a servant assigned to Team A. Searching for a student in Team B should return an empty list.

#### Step 1.2: Implement Atomic Writes with Rollback (SEC-002)
**Objective:** Ensure that a Firestore write and a local Hive write are treated as a single atomic unit, or have a robust rollback mechanism.
**Files:** `lib/features/student/data/repos/student_data_repository.dart`
**Action:**
1. Refactor `createStudent` and `updateStudent` to use a "Transaction Log" pattern.
2. Before any write, create a log entry in a separate Hive box (`write_log_box`) with status `pending`, the operation (create/update), and the data.
3. Attempt the Firestore write inside a `try-catch` block.
4. If Firestore write succeeds, update the local Hive cache. If local cache fails, retry up to 3 times. If it still fails, mark the log entry as `local_fail` and alert the user.
5. If Firestore write fails, the log entry remains `pending`. The sync engine will pick it up on the next run.
6. **Constitution Check:** This fully aligns with the Offline-First principle. The write log is the single source of truth for pending operations.
**Verification:** Mock a Firestore success and a Hive failure. The app should be in a known, recoverable state.

#### Step 1.3: Remove Client-Side Trust in Connectivity Checks (SEC-003)
**Objective:** Make the sync engine robust against tampered or incorrect connectivity states.
**File:** `lib/core/services/sync_service.dart`
**Action:**
1. In `enqueue`, do not gate the sync queue based on `_connectivity.checkConnectivity()`.
2. Instead, always write to the Hive sync queue.
3. `processQueue` should always attempt to process the queue when triggered (e.g., on app start, on user action, or periodically).
4. The handlers (e.g., `StudentSyncHandler`) should be responsible for catching network-related exceptions and deciding whether to retry or move to the DLQ.
5. **Constitution Check:** The sync engine now acts as a transparent pipe. It doesn't make assumptions about the network, aligning with the offline-first mandate.
**Verification:** Write a test where `ConnectivityResult` is `none`, but a mock `SyncHandler` still executes and handles a mock `FirebaseException` correctly.

#### Step 1.4: Synchronize `syncStatus` with Firestore (SEC-004)
**Objective:** Make `syncStatus` a first-class citizen on both client and server for reliable conflict detection.
**Files:** `lib/features/student/data/models/student_model.dart`, `lib/features/student/data/repos/student_data_repository.dart`
**Action:**
1. Ensure `StudentModel.toMap()` always includes the `syncStatus` field (e.g., `'syncStatus': 'pending'`).
2. In `StudentDataRepository.createStudent` and `updateStudent`, when writing to Firestore, include `syncStatus` and `clientUpdatedAt`.
3. In `StudentModel.fromMap`, map the `syncStatus` from Firestore back to the local model.
4. **Constitution Check:** This enables server-side Last-Write-Wins (LWW) resolution. Firestore rules can be updated to check if `request.resource.data.clientUpdatedAt > resource.data.clientUpdatedAt`.
**Verification:** Create a student offline. Check Firestore. The document should have `syncStatus: 'pending'`. After sync, it should be `syncStatus: 'synced'`.

#### Step 1.5: Stabilize BLoC State Transitions (SEC-005)
**Objective:** Ensure every user action has a clear, predictable state machine (Loading -> Success/Error) and prevent race conditions.
**File:** `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart`
**Action:**
1. For `_onSearchStudents`, emit a `StudentSearchLoading` state immediately before calling the repository.
2. Ensure the repository call is `await`ed before the next state is emitted.
3. Use `copyWith` carefully or switch to a sealed class for states to prevent invalid state combinations.
4. **Constitution Check:** Clean Architecture mandates predictable state management.
**Verification:** Widget test that searches for a student. The UI should show a loading indicator, then the results.

---

### Phase 2: Data Integrity & Robustness (Important)

**Goal:** Eliminate subtle bugs that could lead to data corruption, high costs, or poor user experience.

#### Step 2.1: Reconcile Client-Side and Server-Side RBAC (SEC-006)
**Objective:** Ensure `CanMutateStudentUseCase` is a perfect mirror of the `firestore.rules` logic.
**Files:** `lib/features/student/domain/usecases/can_mutate_student_usecase.dart`, `firestore.rules`
**Action:**
1. Extract the `callerManagesTeam` and `callerManagesSector` logic from `firestore.rules` into a shared documentation file (e.g., `lib/docs/rbac_logic.md`).
2. Update `CanMutateStudentUseCase` to exactly match the documented, server-side logic. This is a UI guard, not a security boundary, but it must be consistent.
3. Add a CI step (if available) or a test that parses `firestore.rules` and compares the logic strings.
**Verification:** A unit test that iterates through permutations of roles, sectors, and teams, verifying that the usecase and a mock of the Firestore rule logic yield the same result.

#### Step 2.2: Add Required Composite Index for `searchStudents` (SEC-007)
**Objective:** Prevent collection scans and ensure the `searchStudents` query is performant.
**File:** `firestore.indexes.json` (or Firebase Console)
**Action:**
1. Create a composite index on the `Students` collection for fields: `classId` (Ascending), `name` (Ascending).
2. Deploy the index using `firebase deploy --only firestore:indexes`.
3. **Constitution Check:** This is a critical quota optimization. Without it, `startsWith` on `name` would require a collection scan.
**Verification:** In the Firebase Console, verify the index is building or has finished building.

#### Step 2.3: Integrate Dead Letter Queue (DLQ) into Sync Loop (SEC-008)
**Objective:** Prevent permanently failed sync entries from blocking or bloating the queue.
**File:** `lib/core/services/sync_service.dart`
**Action:**
1. In the `processQueue` loop, when a `SyncHandler` throws an unrecoverable error (e.g., `PermissionDeniedException`), call `_deadLetterQueue.add(failedEntry)`.
2. Remove the failed entry from the main sync queue (Hive box).
3. Expose a UI indicator (e.g., a badge on the sync button) showing the number of items in the DLQ.
4. Provide a manual "Retry All" button in the UI to re-queue DLQ items.
**Verification:** Mock a sync entry that always throws a `PermissionDeniedException`. Verify it is moved to the DLQ and removed from the main queue.

#### Step 2.4: Cache BLoC Instances (SEC-009)
**Objective:** Prevent memory leaks and ensure BLoC lifecycle is tied to the feature, not the widget tree.
**File:** `lib/role_user_route.dart`
**Action:**
1. Refactor `RoleUserRoute` to a `StatefulWidget`.
2. Create the `StudentDataBloc` and `ServantDataBloc` in `initState`.
3. Dispose of them in `dispose()`.
4. Alternatively, elevate the BLoC creation to the top-level `AppRouter` or `MyApp` if their lifecycle is app-wide.
**Verification:** Run the app in profile mode, navigate to a screen with a BLoC, and back out. The BLoC should be disposed of (can be verified with a `print` in the `close()` method).

---

### Phase 3: Architecture & Maintainability (Suggestions)

**Goal:** Improve long-term code health and reduce technical debt.

#### Step 3.1: Type-Safe Sync Entries (SEC-010)
**Objective:** Replace the `Map<String, Object?> payload` with a sealed class for compile-time safety.
**Files:** `lib/core/models/sync_entry.dart`, all `*sync_handler.dart` files
**Action:**
1. Define an abstract class `SyncPayload`.
2. Create concrete classes: `UpsertStudentPayload`, `ArchiveStudentPayload`, `MarkAttendancePayload`, etc.
3. Update `SyncEntry` to hold a `SyncPayload`.
4. Update all handlers to accept the typed payload.
**Verification:** The Dart analyzer will catch any payload mismatches at compile time.

#### Step 3.2: Implement Comprehensive Unit and Widget Tests
**Objective:** Cover the critical paths of the sync engine, BLoCs, and repositories.
**Action:**
1. Add `test/` directories under `lib/core/services/`, `lib/features/*/data/repos/`, and `lib/features/*/presentation/bloc/`.
2. Use `mocktail` for mocking dependencies.
3. Target 70% coverage for business logic.
4. Specifically test: sync queue processing (success, failure, retry, DLQ), Firestore write failures, BLoC state transitions, and repository authorization logic.

---

## 4. Action Checklist

- [ ] 1.1: Harden `searchStudents` Authorization
- [ ] 1.2: Implement Atomic Writes with Rollback
- [ ] 1.3: Remove Client-Side Trust in Connectivity Checks
- [ ] 1.4: Synchronize `syncStatus` with Firestore
- [ ] 1.5: Stabilize BLoC State Transitions
- [ ] 2.1: Reconcile Client-Side and Server-Side RBAC
- [ ] 2.2: Add Required Composite Index for `searchStudents`
- [ ] 2.3: Integrate Dead Letter Queue (DLQ) into Sync Loop
- [ ] 2.4: Cache BLoC Instances
- [ ] 3.1: Type-Safe Sync Entries
- [ ] 3.2: Implement Comprehensive Unit and Widget Tests

---

## 5. Verification & Sign-Off

Before any release, the following must be completed:
1.  All items in **Phase 1** are implemented, tested, and verified.
2.  A manual penetration test is performed where a user with a `servant` role attempts to access/modify data outside their scope.
3.  The app is tested in airplane mode to ensure the offline-first flow is robust and data is not lost.
4.  Firestore read/write counts are monitored during a realistic usage scenario to ensure Spark plan quotas are not at risk.
5.  Code review by a second senior developer focusing on the changes made in Phases 1 and 2.
