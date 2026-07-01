# CSMS Security Remediation - Clarifying Specification

**Document Purpose:** This is the "Single Source of Truth" for any AI agent, developer, or reviewer working on the security and data integrity remediation of the CSMS application.  
**Audience:** AI Coding Agents, Senior Developers, Code Reviewers  
**Mandatory Rule:** Before implementing any fix, the agent/reviewer MUST read this document. If anything is unclear, ask for clarification rather than guessing.

---

## 1. The Problem Statement: Why Are We Here?

The CSMS application has been architected with a strong foundation (Clean Architecture, BLoC, Offline-First). However, a comprehensive code review has revealed **10 critical issues** that, if deployed to production, could lead to:  

1. **Data Leakage:** Servants viewing student data outside their assigned scope.  
2. **Data Corruption:** Duplicate student records, lost updates, or orphaned data due to non-atomic writes.  
3. **Unauthorized Access:** Students or malicious users manipulating sync logic to bypass authorization.  
4. **High Costs:** Unoptimized Firestore queries triggering collection scans, exhausting the Spark (free) plan.  
5. **Poor User Experience:** UI flickering, race conditions, and confusing permission errors.  

**The Core Issue:** The application has a gap between its architectural intent (secure, offline-first, robust) and its implementation (client-side trust, missing atomicity, divergent authorization logic).  

---

## 2. Non-Negotiable Constraints (Project Constitution)

These rules are ABSOLUTE. Any suggested fix that violates these must be rejected or re-architected.

### 2.1 Zero Cloud Functions (Spark Plan Compliance)
- **Rule:** NEVER write, plan, or suggest the use of Firebase Cloud Functions, scheduled tasks, or backend triggers.  
- **Reason:** The project operates strictly on the Firebase Spark (Free) Plan without a billing account. All logic must be client-side or via administrative scripts.  
- **Impact on Remediation:** We cannot use Cloud Functions for RBAC, data validation, or scheduled cleanup. All authorization and validation must happen in Firestore Security Rules or client-side code.  

### 2.2 Offline-First & Data Idempotency
- **Rule:** All features MUST work 100% offline. Data must be written to local storage (Hive) first, then queued for synchronization.  
- **Reason:** Target environments (rural churches) have unreliable internet.  
- **Impact on Remediation:**  
  - Every write operation MUST have a local equivalent that works without network.  
  - Sync operations MUST be idempotent (running the same operation twice produces the same result as running it once).  
  - Document IDs MUST be deterministic (e.g., `recordId` = `studentId_sessionId`) to prevent duplicates.  

### 2.3 Absolute Quota Optimization
- **Rule:** NEVER perform unbounded queries or collection scans (`while(hasMore)`, `.snapshots()`, `.watch()`).  
- **Reason:** The Spark Plan allows only 50,000 reads per day.  
- **Impact on Remediation:**  
  - All Firestore queries MUST have a `.limit()`.  
  - Collection group queries should be avoided if possible.  
  - Use single-document lookups or `whereIn` (max 10 items) for joins.  

### 2.4 Document-Based Role-Based Access Control (RBAC)
- **Rule:** Firestore Security Rules MUST read the caller's role from `get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.role`.  
- **Reason:** Custom Claims are NOT available on the Spark Plan.  
- **Impact on Remediation:**  
  - The `Users` collection is the single source of truth for roles.  
  - Client-side code (BLoCs, UseCases) should mirror this logic for UI guards, but the REAL security boundary is Firestore Rules.  

### 2.5 Clean Architecture
- **Rule:** Follow the `Domain -> Data -> Presentation` layer structure using BLoC.  
- **Reason:** Maintainability and testability.  
- **Impact on Remediation:**  
  - Business logic MUST be in UseCases or BLoCs, not in Widgets.  
  - Data access MUST be through Repository interfaces.  
  - NEVER trust the UI for authorization decisions.  

---

## 3. The 10 Critical Issues: Detailed Breakdown

### Issue 1: Data Leakage in `searchStudents` (CRITICAL)
- **Where:** `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart`, line ~412
- **What:** The `_onSearchStudents` event handler calls the repository to search students. However, it does not pass the `actor`'s restricted scope (e.g., `effectiveAssignedTeamIds`) to the repository. The repository then queries Firestore for ALL students matching the search term.
- **Exploit:** A servant with access to Team A can search for students in Team B and view their data, as the Firestore query is not restricted by the servant's team.
- **Why This Violates Constraints:**  
  - Violates **2.4 (Document-Based RBAC)**: The client-side code is not enforcing scope before querying.
  - Violates **2.3 (Quota Optimization)**: The query is effectively a collection scan if the search term is broad.
- **Fix Principle:** The BLoC MUST pass the actor's authorized scope to the repository, and the repository MUST include that scope in the Firestore query.

### Issue 2: Duplicate Write Risk & State Inconsistency (CRITICAL)
- **Where:** `lib/features/student/data/repos/student_data_repository.dart`, `createStudent` and `updateStudent`
- **What:** The `createStudent` method first writes to Firestore, then writes to local Hive cache. If the Firestore write succeeds but the local cache write fails (e.g., disk full, app crash), the app is left with a student in Firestore but NOT in local cache. On next sync, the app might try to create the student again (duplicate) or fail to find them locally.
- **Exploit:** A malicious user could repeatedly create a student, causing the write to Firestore to succeed but the local cache to fail, potentially creating multiple records.
- **Why This Violates Constraints:**  
  - Violates **2.2 (Offline-First & Idempotency)**: The write is not atomic. The system is not idempotent.
  - Violates **2.5 (Clean Architecture)**: The repository is not handling failures gracefully.
- **Fix Principle:** Use a "Transaction Log" in Hive. Write to the log first (status: `pending`), then attempt Firestore write, then local cache. If any step fails, the log can be used for rollback or retry.

### Issue 3: Client-Side Connectivity Check is Unreliable (CRITICAL)
- **Where:** `lib/core/services/sync_service.dart`, `enqueue` method
- **What:** The `SyncService` checks `ConnectivityResult` to decide whether to write to the sync queue or directly process online. A rooted/jailbroken device can fake connectivity state.
- **Exploit:** A malicious user can force the app to think it's offline, bypassing online validation and queuing malicious operations. Or, they can force it online, triggering immediate sync of incomplete data.
- **Why This Violates Constraints:**  
  - Violates **2.5 (Clean Architecture)**: UI/BLoC should not dictate sync engine behavior.
  - Violates **2.2 (Offline-First)**: The sync engine should be the sole authority on when to sync.
- **Fix Principle:** REMOVE all connectivity checks from `SyncService`. Always write to the local sync queue. Let the sync engine process the queue whenever it runs, handling network errors gracefully.

### Issue 4: `syncStatus` Missing from Firestore (CRITICAL)
- **Where:** `lib/features/student/data/models/student_model.dart`, `toMap()` and `toJson()`
- **What:** The `StudentModel` has a `syncStatus` field (e.g., `pending`, `synced`, `failed`) in the Hive local model, but this field is NOT included in the `toMap()` or `toJson()` methods used for Firestore writes.
- **Exploit:** The server has no knowledge of a record's sync state. Conflict resolution (Last-Write-Wins) is impossible. If two devices modify the same student offline, there's no server-side mechanism to determine which write is newer.
- **Why This Violates Constraints:**  
  - Violates **2.2 (Offline-First & Idempotency)**: Cannot resolve conflicts without sync metadata.
  - Violates **2.3 (Quota Optimization)**: Without `syncStatus`, the app might perform unnecessary reads to determine if data is up-to-date.
- **Fix Principle:** ALWAYS include `syncStatus` and `clientUpdatedAt` in Firestore writes. Read these back from Firestore when loading data to maintain a consistent state.

### Issue 5: BLoC State Logic Complexity and Race Conditions (CRITICAL)
- **Where:** `lib/features/student/presentation/bloc/student_data/student_data_bloc.dart`
- **What:** The `_onSearchStudents` method directly modifies the state without emitting an intermediate `loading` state. If the user types quickly, multiple searches can be in flight simultaneously, and the results might arrive out of order, causing the UI to show stale data.
- **Exploit:** Race condition, not a security exploit, but leads to poor UX and potential data corruption if the user acts on stale data.
- **Why This Violates Constraints:**  
  - Violates **2.5 (Clean Architecture)**: BLoC state transitions should be predictable and atomic.
- **Fix Principle:** Emit a `StudentDataSearching` state immediately upon starting a search. Debounce or cancel previous searches to prevent race conditions.

### Issue 6: Client-Side RBAC Diverges from Firestore Rules (IMPORTANT)
- **Where:** `lib/features/student/domain/usecases/can_mutate_student_usecase.dart`
- **What:** The `CanMutateStudentUseCase` checks `actor.effectiveAssignedTeamIds.contains(existing.classId)`. However, the Firestore rules also check the legacy `assignedTeamId` field.
- **Exploit:** A servant whose role is defined by the legacy `assignedTeamId` (not `assignedTeamIds`) will see the UI allowing them to edit a student, but the Firestore write will be rejected. This is a confusing UX and a potential security gap.
- **Why This Violates Constraints:**  
  - Violates **2.4 (Document-Based RBAC)**: Client-side logic must be a perfect mirror of server-side rules.
- **Fix Principle:** Extract the RBAC logic into a shared function or documentation. Ensure `CanMutateStudentUseCase` perfectly matches `firestore.rules`.

### Issue 7: `searchStudents` Query Requires Missing Composite Index (IMPORTANT)
- **Where:** `lib/features/student/data/services/student_query_service.dart`
- **What:** The `searchStudents` method uses `.where('classId', isEqualTo: classId).orderBy('name')` and `.startAt(query).endAt('$query\uf8ff')` for prefix search.
- **Exploit:** Without a composite index on `classId` + `name`, Firestore will either reject the query or perform a collection scan (expensive, slow).
- **Why This Violates Constraints:**  
  - Violates **2.3 (Quota Optimization)**: A collection scan reads every document in the collection, exhausting the 50K read quota instantly.
- **Fix Principle:** Define and deploy a composite index in `firestore.indexes.json`.

### Issue 8: Dead Letter Queue (DLQ) is Decoration-Only (IMPORTANT)
- **Where:** `lib/core/services/sync_service.dart`
- **What:** The `SyncService` has a `_deadLetterQueue` dependency, but it is never used. When a sync entry fails, it is retried until it succeeds or the app is closed. Permanently failed entries are never removed.
- **Exploit:** Not a direct exploit, but a malicious user could create a large number of records that fail to sync, filling up local storage and causing the app to crash.
- **Why This Violates Constraints:**  
  - Violates **2.2 (Offline-First)**: The sync engine should be self-healing and not leave the system in an unrecoverable state.
- **Fix Principle:** After `maxRetries`, move the entry to the DLQ and remove it from the main queue. Surface DLQ items in the UI.

### Issue 9: `RoleUserRoute` Creates BLoCs in `build()` (IMPORTANT)
- **Where:** `lib/role_user_route.dart`
- **What:** `RoleUserRoute` is a `StatelessWidget` that creates `BlocProvider` instances inside its `build` method. In Flutter, `build` can be called multiple times, potentially recreating the BLoC.
- **Exploit:** Not a direct exploit, but can lead to memory leaks, state loss, and confusing behavior if the user navigates quickly.
- **Why This Violates Constraints:**  
  - Violates **2.5 (Clean Architecture)**: BLoC lifecycle should be managed by a `StatefulWidget` or a higher-level provider.
- **Fix Principle:** Convert `RoleUserRoute` to a `StatefulWidget`. Create BLoCs in `initState` and dispose in `dispose()`.

### Issue 10: `SyncEntry.payload` Lacks Type Safety (SUGGESTION)
- **Where:** `lib/core/models/sync_entry.dart`
- **What:** `SyncEntry` uses `Map<String, Object?> payload`. This is flexible but loses all compile-time type checking.
- **Impact:** Any refactoring of the payload structure (e.g., renaming a field) will not be caught by the compiler. Runtime errors are likely.
- **Fix Principle:** Use a sealed class or union type for `SyncPayload` to ensure type safety.

---

## 4. Cross-Cutting Concerns (Apply to ALL Fixes)

### 4.1 Error Handling
- ALWAYS catch exceptions at the repository level.
- NEVER let a Firestore or Hive error crash the app.
- Use specific error types (e.g., `FirestorePermissionDenied`, `HiveWriteFailure`) rather than generic `Exception`.

### 4.2 Logging
- Use the `developer.log` (from `dart:developer`) for all sync and security-related events.
- Include context: user ID, document ID, operation type, and success/failure status.
- Avoid logging PII (Personally Identifiable Information) like student names or phone numbers. Log document IDs instead.

### 4.3 Testing
- Every fix MUST have a corresponding unit test.
- Every fix MUST have a corresponding integration test if it touches Firestore or Hive.
- Mock external dependencies (Firestore, Hive, Connectivity).
- Use `fake_cloud_firestore` for Firestore mocking.
- Use `mocktail` for general mocking.

### 4.4 Documentation
- Update inline documentation (`///`) for any changed public API.
- Update `lib/docs/rbac_logic.md` if RBAC rules change.
- Update this `clarifying_spec.md` if the problem space changes (e.g., new critical issues found).

---

## 5. Agent Execution Guide

### For AI Agents Implementing Fixes:
1. **Read this document FIRST.** Ensure you understand the constraints.
2. **Read the task in `tasks.md` assigned to you.**
3. **Identify the specific files to change.** The tasks have file paths.
4. **Look for `// CRITICAL:` or `// TODO(SECURITY):` comments in the code.** These were added during the code review to mark exact locations.
5. **Implement the fix.**
6. **Write tests.** Unit tests are mandatory. Integration tests are highly encouraged.
7. **Verify against the Project Constitution.** Does your fix violate any non-negotiable rules?
8. **Run `dart analyze` and fix all warnings.**
9. **Submit your changes for review.**

### For AI Agents Reviewing Fixes:
1. **Read this document.** Understand the expected behavior.
2. **Read the code changes.**
3. **Verify the fix addresses the root cause, not just the symptom.**
4. **Check for test coverage.** Are there tests for success AND failure cases?
5. **Check against the Project Constitution.** Is the fix Spark-plan compliant? Does it follow Clean Architecture?
6. **Verify no new issues were introduced.** (e.g., did fixing a race condition create a memory leak?)
