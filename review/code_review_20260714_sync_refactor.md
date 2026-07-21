# Review Summary

This is a substantial architectural refactor that moves all student write operations to an offline-first pattern via the sync queue, adds `SyncErrorClassifier` for intelligent retry handling, includes LWW cache-overwrite protection, and hardens Firestore security rules with session-teamId cross-verification. The work is well-structured and addresses several senior code review concerns. However, there are **critical security issues** with password handling and PII exposure, plus functional regression risk in auth provisioning. **Blocked** until fixed.

# What Was Done Well

- **`SyncErrorClassifier` integration** across 6 repositories (`StudentDataRepository`, `ServantDataRepository`, `ResultsRepository`, `PastoralRepository`, `TeamRepository`, `SyncService`) correctly distinguishes non-retriable errors to prevent infinite retry loops and surface permanent failures to the UI
- **LWW cache-overwrite protection** in `syncOfflineUpsert`, `syncOfflineCreateWithAuth`, `syncOfflineArchive`, and `syncOfflineRestore` prevents stale writes from the sync queue overwriting newer local edits (`syncOfflineArchive:660-668`, `syncOfflineRestore:705-713`)
- **Firestore rules cross-verification** (`firestore.rules:366-368, 375-377`) ensures `teamId` on attendance records matches the parent session, preventing cross-team write attacks
- **`AttendanceSyncHandler.executeBatch` filtering** (separating `MARK_ATTENDANCE` from `CLEAR_ATTENDANCE`) prevents non-batchable entries from corrupting the batch pipeline
- **Workmanager auth state restoration** in `main.dart:50-58` handles the race condition where `currentUser` is `null` during background task initialization
- **Silent catch elimination** — all `catchError((_) {})` in `AttendanceSessionRepository` replaced with proper logging (`lines 86-145`)
- **Dynamic `totalEntries` tracking** in `SyncService.processQueue:369-371` correctly accounts for entries added during processing

# Critical Issues

### 1. Password stored in Hive sync payload (P0 — Security)
- **Where**: `StudentDataRepository.createStudent:289-298`, `syncOfflineCreateWithAuth:579-580`
- **Why**: The `CREATE_STUDENT_WITH_AUTH` sync entry includes the raw `password` in the payload. This payload is persisted in the user's Hive sync queue box as a `SyncEntry`. Hive stores data unencrypted by default on disk. A malicious actor with file-system access (rooted device, backup extraction) can extract passwords.
- **Risk**: Password exposure — catastrophic for any user, especially if credentials are reused.
- **Recommended fix**: Never store passwords in Hive. Options:
  a) Move password handling to a separate encrypted store (e.g., `flutter_secure_storage`) that is not part of the sync queue.
  b) Use a server-side pre-auth token flow instead of passing raw passwords through the client.
  c) At minimum, create the Firebase Auth account eagerly during `createStudent` (synchronously online) and only enqueue the student document write for offline. This was the previous pattern — removing it introduced this regression.

### 2. Email used as Firestore document ID (P0 — PII/Security)
- **Where**: `StudentDataRepository.createStudent:266-268`
- **Why**: `docId = email.trim().toLowerCase()` when email is provided. Using email as a document ID exposes the email in the document path, making it trivially enumerable and leaking PII in Firestore URLs, error messages, and logs. Also, if the email changes later, the doc ID becomes invalid.
- **Risk**: PII leakage, non-portable document IDs, Firestore rule bypass potential.
- **Recommended fix**: Always use `const Uuid().v4()` for document IDs. Store email as a field, not as the document identifier. If you need unique-by-email constraint, use a separate `email_uniqueness` subcollection or Firestore `exists` check.

### 3. Auth provisioning is now invitation-only — no actual Firebase Auth user created (P0 — Functional regression)
- **Where**: `ProvisionStudentWithAuthUseCase:33-41` removed `AdminUserProvisioningService.createUser` call; `syncOfflineCreateWithAuth:582-594` only creates an Invitations document
- **Why**: The old flow created a Firebase Auth user via `AdminUserProvisioningService.createUser()`, then created the student doc. The new flow bypasses Auth user creation entirely — it only writes an invitation document. This means students with linked accounts cannot actually sign in. The `CREATE_STUDENT_WITH_AUTH` sync handler does not invoke any Auth creation API.
- **Risk**: Students created with email/password will have no way to authenticate — broken feature.
- **Recommended fix**: The sync handler must invoke `AdminUserProvisioningService` (or Firebase Admin SDK equivalent) to create the actual Auth user. Since Spark plan has no Cloud Functions, you need an in-app Admin SDK proxy or use Firebase Auth REST API with a secure backend. Alternatively, restore the eager-create pattern in `ProvisionStudentWithAuthUseCase` and only enqueue the student doc for offline sync.

### 4. `CREATE_STUDENT_WITH_AUTH` sync handler performs no auth account creation (P0)
- **Where**: `StudentDataRepository.syncOfflineCreateWithAuth:582-607`
- **Why**: The method writes to the `Invitations` collection and creates a student doc, but never creates a Firebase Auth user. The `Invitations` collection write has no corresponding backend consumer — it's just a dead document. No actual Auth account is provisioned.
- **Risk**: Users cannot sign in. Complete feature breakage.
- **Recommended fix**: Implement actual Firebase Auth user creation. On Spark plan without Cloud Functions, you'd need to use either:
  a) Firebase Admin SDK on a trusted server + REST API call from the app (exposes admin creds — not recommended)
  b) Eager auth creation in `ProvisionStudentWithAuthUseCase` (restore old pattern) + only enqueue student doc update for offline

# Important Issues

### 1. `unawaited()` without `.catchError()` handler in StudentDataRepository
- **Where**: `StudentDataRepository` lines 100, 306, 347, 452, 495
- **Why**: AGENTS.md mandates: *"No `unawaited()` without `.catchError()` handler"*. Each `unawaited(_syncServiceGetter().processQueue())` could throw an unhandled async exception.
- **Risk**: Unhandled async exceptions could crash the widget tree or cause silent failures.
- **Recommended fix**: Wrap each call: `unawaited(_syncServiceGetter().processQueue().catchError((e, s) => developer.log('processQueue failed', error: e, stackTrace: s)));`

### 2. Archive/restore sync entry ID collision
- **Where**: `StudentDataRepository:437-438, 481-482` — removed timestamp suffix, now uses `'archive_student_$docId'` and `'restore_student_$docId'`
- **Why**: If a user archives, restores, then archives again, the second archive entry has the same sync entry ID as the first. `SyncService.enqueue` treats same IDs as deduplication, so the second archive may be silently dropped.
- **Risk**: Silent data loss — archive operation may not execute.
- **Recommended fix**: Use a unique suffix: `'archive_student_${docId}_${DateTime.now().millisecondsSinceEpoch}'` as before, or use a UUID.

### 3. Firestore rules `get()` cost on every attendance mark create/update
- **Where**: `firestore.rules:367, 376`
- **Why**: The new rules call `get(/databases/$(database)/documents/AttendanceSessions/$(sessionId))` to verify teamId matches. This consumes 1 Firestore read per mark write (can be hundreds per close-session batch). On Spark plan (50K reads/day), this adds significant cost.
- **Risk**: Rapid quota exhaustion during bulk operations.
- **Recommended fix**: Either (a) embed `sessionTeamId` in the record data and compare against that (zero extra read), or (b) accept the cost but add a comment documenting it.

### 4. `syncOfflineUpdate` delegates to `syncOfflineUpsert` — potential duplicate linked-user sync
- **Where**: `StudentDataRepository:508-510`
- **Why**: `syncOfflineUpdate` simply calls `syncOfflineUpsert`, which may write linked user role patches. But `UPDATE_STUDENT` entries don't carry `previousRole` or `syncLinkedUser` flags, so the payload may lack required fields for linked user sync, causing crashes or silent failures.
- **Risk**: Broken update flow for students with linked auth accounts.
- **Recommended fix**: Either align the `UPDATE_STUDENT` payload shape to match `UPSERT_STUDENT`, or keep `syncOfflineUpdate` as a minimal Firestore `set(merge:true)` call for the student doc only.

### 5. `hide SyncStatus` removed across imports — namespace pollution
- **Where**: `attendance_repository.dart`, `student_data_repository.dart`, `servant_data_repository.dart`, `pastoral_repository.dart`, `team_repository.dart`
- **Why**: The `hide SyncStatus` was removed from imports, but these files import `core/constants/enums.dart` which likely also exports `SyncStatus`. The enum type `SyncStatus` (from enums) and the removed class `SyncStatus` (from sync_service) could cause naming conflicts if both are used.
- **Risk**: Ambiguous references leading to compile errors if both are referenced in the same scope.
- **Recommended fix**: Verify no naming collisions exist. Consider using `hide` or `show` to be explicit.

# Suggestions

### 1. Extract LWW cache-overwrite pattern into a reusable helper
- **Where**: Repeated in `syncOfflineUpsert:554-566`, `syncOfflineCreateWithAuth:609-621`, `syncOfflineArchive:660-668`, `syncOfflineRestore:705-713`
- **Why**: 4 nearly identical blocks of ~10 lines each for the same LWW check. A helper method reduces duplication and risk of inconsistency.
- **Recommended fix**: Extract `Future<void> _applyLwwSyncStatus(String docId, StudentModel syncedStudent, {DateTime? syncTime})`.

### 2. `processQueue` re-reads all entries each iteration
- **Where**: `SyncService.processQueue:358-363`
- **Why**: Every loop iteration calls `targetBox.values.toList()` and re-sorts all entries. For queues with hundreds of entries, this is O(n log n) per iteration.
- **Recommended fix**: Consider a single sorted snapshot with pointer advancement, re-reading only when entries are added mid-flight.

### 3. `markAllPresentForRemainingStudents` enqueues individual entries sequentially
- **Where**: `AttendanceRepository:314-348`
- **Why**: Each student gets a separate `SyncEntry` and a separate `processQueue` call (via `enqueue`). This creates N sync entries instead of a single batch operation, and each enqueue checks connectivity.
- **Recommended fix**: Create all sync entries first, then enqueue them, then call `processQueue` once. Or add a batch action type like `BATCH_MARK_ALL_PRESENT`.

### 4. Test: No test for `syncOfflineClear` or `CREATE_STUDENT_WITH_AUTH` handler
- **Where**: `test/core/services/sync_service_test.dart`
- **Why**: The test file covers `MARK_ATTENDANCE`, `UPSERT_STUDENT`, retry/backoff, and user-switch mid-flight, but has no coverage for `CLEAR_ATTENDANCE`, `CREATE_STUDENT_WITH_AUTH`, `ARCHIVE_STUDENT`, or `RESTORE_STUDENT` action types.

# Offline and Sync Check

| Check | Result |
|-------|--------|
| Local write first | **Pass** — All mutations save to Hive before enqueuing |
| Duplicate-write protection | **Pass** — Same sync entry IDs are deduplicated; LWW protects cache overwrites |
| syncStatus coverage | **Pass** — `SyncStatus.pending` → `SyncStatus.synced` throughout |
| Retry strategy | **Pass** — Exponential backoff with jitter, `SyncErrorClassifier` for retriable vs permanent errors, DLQ eviction at max retries |
| Conflict handling | **Pass** — LWW via `clientUpdatedAt` comparison; non-retriable errors immediately evicted to DLQ |

# Security Check

| Check | Result |
|-------|--------|
| Role-based access | **Pass** — Firestore rules enforce `callerManagesTeam`, `callerManagesSector`, `isAdmin` guards |
| Student data isolation | **Pass** — Rules restrict student reads to self or authorized servant/admin |
| Firestore-rule dependency identified | **Pass** — Rules cross-verify teamId on mark writes |
| Client-side-only authorization avoided | **Pass** — All authorization is in Firestore rules, not client-only |
| Password in Hive sync payload | **FAIL** — Critical gap (see Critical Issue #1) |
| Email as docID | **FAIL** — PII leakage (see Critical Issue #2) |

# Firestore Cost Check

| Check | Result |
|-------|--------|
| Read efficiency | **Warning** — New rules add `get()` per mark write (1 extra read each); `getStudentAttendanceHistory` still fetches subcollection per student |
| Write efficiency | **Good** — Batched operations in close-session and `syncBatchedMarks`; offline queue prevents redundant writes |
| Listener usage | **Good** — No new listeners added; connectivity listener is existing |
| Batch opportunities | Listed — `closeSession` uses transactions/batches; `syncBatchedMarks` batches by teamId+sessionId |

# Testing Gaps

- **Unit**: Missing — `syncOfflineClear`, `CREATE_STUDENT_WITH_AUTH`, `ARCHIVE_STUDENT`, `RESTORE_STUDENT`, DLQ retry
- **Widget**: No widget tests in scope — verify SyncCubit correctly renders DLQ warning, sync failure, and success states
- **Integration**: Missing — end-to-end offline → online sync for student creation with auth credentials

# Merge Decision

**Blocked** — The critical issues (password in Hive, email as docID, broken auth provisioning) must be resolved before merge. These are functional and security regressions introduced by the offline-first refactor.
