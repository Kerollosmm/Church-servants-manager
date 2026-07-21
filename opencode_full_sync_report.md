# CSMS Sync Feature Investigation Report

## Part A: Directory Structure

### lib/ (top-level)
```
lib/
├── church_app.dart
├── main.dart
├── role_user_route.dart
├── firebase_options.dart
├── core/
├── features/
├── shared/
└── l10n/
```

### lib/core/
```
core/
├── blocs/
│   ├── connectivity/   (connectivity_cubit.dart, connectivity_state.dart)
│   └── sync/           (sync_cubit.dart, sync_state.dart)
├── constants/         (enums.dart, enums.g.dart, firestore_collections.dart, ...)
├── di/                 (injection.dart)
├── models/             (sync_entry.dart, sync_entry.g.dart, sync_payload.dart)
├── routing/
├── services/           (sync_service.dart, sync_handler.dart, lifecycle_sync_manager.dart, dead_letter_queue.dart, hive_pruning_service.dart, cache_tracker.dart)
├── theme/
├── utils/
└── widgets/            (sync_status_banner.dart, sync_queue_indicator.dart, common/, dialogs/, feedback/, form/, cards/, search/, app_*, not_found_screen.dart)
```

### lib/features/
```
features/
├── admin/
├── attendance/
├── auth/
├── devtools/
├── results/
├── servant/
├── student/
└── team/
```

Each feature follows clean-arch layout: `data/{local,models,repos,services}`, `domain/{entities,failures,relevant_use_cases,usecases}`, `presentation/{bloc,bloc/cubit,widgets,screens}`.

---

## Part B: Sync-Related Files Found

### B.1 Files with "sync" / "Sync" in the name

| # | Path | Description |
|---|------|-------------|
| 1 | `C:\Users\KimoStore\church_managment_system\lib\core\services\sync_service.dart` | Central outbox-pattern sync engine: enqueue, dequeue, processQueue with consecutive-chunking, retry/backoff, DLQ eviction, Workmanager task registration. |
| 2 | `C:\Users\KimoStore\church_managment_system\lib\core\services\sync_handler.dart` | Abstract `SyncHandler` contract with `execute` and `executeBatch`. |
| 3 | `C:\Users\KimoStore\church_managment_system\lib\core\services\lifecycle_sync_manager.dart` | StatefulWidget wrapper that triggers `SyncService.processQueue()` on `AppLifecycleState.resumed`. |
| 4 | `C:\Users\KimoStore\church_managment_system\lib\core\blocs\sync\sync_cubit.dart` | `SyncCubit` bridging `SyncService.statusStream` to UI; `forceSync()` and `retryDlq()` actions. |
| 5 | `C:\Users\KimoStore\church_managment_system\lib\core\blocs\sync\sync_state.dart` | `SyncState` hierarchy: SyncIdle, Syncing, SyncSuccess, SyncFailure, SyncDlqWarning. |
| 6 | `C:\Users\KimoStore\church_managment_system\lib\core\models\sync_entry.dart` | `@HiveType(typeId:100) SyncEntry extends HiveObject` — fields id, actionType, payload, createdAt, retryCount, failedAt, userId, lastErrorMessage. **NOTE: `payload` is typed `Map<String, Object?>` but the model is mutated in place (`entry.failedAt = DateTime.now()` in `dead_letter_queue.dart:33` and `sync_service.dart:557`) — relies on HiveObject live binding.** |
| 7 | `C:\Users\KimoStore\church_managment_system\lib\core\models\sync_entry.g.dart` | Generated `SyncEntryAdapter` (typeId 100). |
| 8 | `C:\Users\KimoStore\church_managment_system\lib\core\models\sync_payload.dart` | Sealed typed-payload hierarchy with `UpsertStudentPayload`, `ArchiveStudentPayload`, `RestoreStudentPayload`. **NOTE: appears unused — repositories build raw `Map<String, dynamic>` payloads directly, not via these typed classes.** |
| 9 | `C:\Users\KimoStore\church_managment_system\lib\core\widgets\sync_status_banner.dart` | Animated banner reacting to SyncCubit states; tappable on DLQ warning. |
| 10 | `C:\Users\KimoStore\church_managment_system\lib\core\widgets\sync_queue_indicator.dart` | AppBar badge showing `syncService.pendingCount`; tapping triggers `forceSync()`. Reads `pendingCount` synchronously via `getIt<SyncService>()` in build. |
| 11 | `C:\Users\KimoStore\church_managment_system\lib\shared\widgets\sync_status_indicator.dart` | Simpler (older) status indicator variant, used in `auth_gate.dart`. |
| 12 | `C:\Users\KimoStore\church_managment_system\lib\features\team\data\services\team_sync_handler.dart` | Delegates CREATE/UPDATE/DELETE/RESTORE_TEAM to `ITeamRepository.syncOffline*`. |
| 13 | `C:\Users\KimoStore\church_managment_system\lib\features\student\data\services\student_sync_handler.dart` | Switch on UPSERT_STUDENT / CREATE_STUDENT_WITH_AUTH / UPDATE_STUDENT / ARCHIVE_STUDENT / RESTORE_STUDENT. |
| 14 | `C:\Users\KimoStore\church_managment_system\lib\features\student\data\services\student_linked_user_sync_service.dart` | Builds linked-user role patch / batch-updates Students + Users collections. Used inside `StudentDataRepository.upsertStudent` online path. |
| 15 | `C:\Users\KimoStore\church_managment_system\lib\features\student\data\services\pastoral_sync_handler.dart` | Routes CREATE_PASTORAL_RECORD to `IPastoralRepository.syncOfflineCreate`. |
| 16 | `C:\Users\KimoStore\church_managment_system\lib\features\servant\data\services\servant_sync_handler.dart` | Direct-Firestore handler for CREATE/UPDATE/ARCHIVE/RESTORE_SERVANT. Reference implementation. |
| 17 | `C:\Users\KimoStore\church_managment_system\lib\features\results\data\services\result_sync_handler.dart` | Routes UPDATE_RESULT to `IResultsRepository.syncOfflineUpdate`. |
| 18 | `C:\Users\KimoStore\church_managment_system\lib\features\attendance\data\services\attendance_sync_handler.dart` | Routes MARK_ATTENDANCE / CLEAR_ATTENDANCE; `executeBatch` groups mark entries by `${teamId}_$sessionId` and calls `syncBatchedMarks`. |
| 19 | `C:\Users\KimoStore\church_managment_system\lib\features\attendance\data\services\attendance_season_sync_handler.dart` | Routes CREATE_SESSION and CLOSE_SESSION to `AttendanceSessionRepository`. |

### B.2 Files with "offline" or "Offline" in the name
- `C:\Users\KimoStore\church_managment_system\lib\shared\widgets\offline_indicator.dart` — banner bound to `ConnectivityCubit` showing ConnectivityOffline state.
- (No other such files; offline-write logic lives inside the repositories via `_connectivity.checkConnectivity()` checks + `enqueue`.)

### B.3 Files with "queue" / "Queue" in the name
- `C:\Users\KimoStore\church_managment_system\lib\core\services\dead_letter_queue.dart` — DLQ Hive-backed store (`dead_letter_queue_box`, capped at 100, 30-day prune).
- `C:\Users\KimoStore\church_managment_system\lib\core\widgets\sync_queue_indicator.dart` — UI badge (already listed above).

### B.4 "pending" / "upload" files — none exist
Glob returned nothing for `*pending*`, `*Pending*`, `*upload*`, `*Upload*`. "Pending" concept lives in `SyncStatus.pending` enum (see B.6).

---

## Part C: Main Sync Service / Repository / Bloc

### C.1 `lib/core/services/sync_service.dart` (594 lines)
**Role**: Central offline-sync engine using the Outbox pattern. Per-user Hive box `sync_queue_$userId`.

Key surface:
- `enqueue(SyncEntry)` → puts into `_activeBox`, triggers `processQueue()` (or registers a `Workmanager` one-off task when offline).
- `dequeue(entryId)` → removes a successfully-synced entry.
- `processQueue()` → FIFO processing with re-Read of box per iteration, moved-entry protection by capturing local box refs (`final batchBox = _activeBox;`), consecutive-chunking for MARK_ATTENDANCE (batches up to 400 entries), exponential backoff with jitter (capped 30s), DLQ eviction after `_maxRetries=5`.
- `init()` → opens DLQ + starts `connectivity_plus` listener that re-triggers `processQueue()` on network-gained.
- `initAndProcessOnce()` → lightweight bootstrap for the Workmanager background task; calls `setAuthenticatedUser(FirebaseAuth.instance.currentUser?.uid)`.
- `setAuthenticatedUser(userId)` → closes the previous per-user box, opens `sync_queue_$userId`, registers a periodic Workmanager task (15-min, `NetworkType.connected`), cancels tasks on logout.
- `retryDlq()` → re-enqueues all DLQ entries and triggers process.
- `statusStream` → emits `SyncStatus` updates consumed by SyncCubit.

**Notable issues observed:**
1. **Two distinct classes named `SyncStatus`** (idle/processing/success/error/dlqEviction in `sync_service.dart` vs an enum `pending/synced/failed` in `core/constants/enums.dart`). Every repository file imports the sync service with `hide SyncStatus` to disambiguate — fragile and error-prone.
2. **Line 273-307 `retryDlq()`** opens the box dynamically and closes it in `finally`, but the box reference inside `_activeBox` is not assigned — if `retryDlq()` was called while `_activeBox` is null, it opens+closes the box but never updates `_activeBox`. The subsequent `unawaited(processQueue())` then hits the guard `if (_activeUserId == null || _activeBox == null) return;` and **silently no-ops**.
3. **`dequeue(String entryId)` emits `SyncStatus.idle()`** unconditionally regardless of whether items remain in the box — UI reverts to idle even when more entries are pending.
4. **`processQueue()` re-check box iteration model** — each iteration does `targetBox.values.toList()` (full scan & sort) instead of `targetBox.keys.first` style peeking. On large queues this is O(n log n) per item → O(n² log n) total. Acceptable today but worth noting.
5. **DLQ eviction in `processQueue` (line 360)** calls `_evictToDlq(entry, targetBox)` but then recomputes `SyncStatus.processing(...)`. No `SyncStatus.error` or warning is surfaced for the evicted entry before continuing — the warning is only emitted inside `_evictToDlq` itself via `dlqEviction` factory.
6. **No persistent background Workmanager on iOS for periodic 15-min tasks** — `Workmanager().registerPeriodicTask` only fires reliably on Android; iOS background-task semantics are limited. Per-user queue may stall under offline-to-online transitions if app is suspended. Acceptable given constraints (no Cloud Functions).
7. **Line 56-65** expose a `Random _random` for jitter — fine, but combined with the `backoffProvider` fallback it means real retries can stack multiline box processing; in production tests you must inject `backoffProvider`.
8. The `unawaited(processQueue())` pattern appears 5+ times; the `_hasPendingTriggers` re-entry semaphore is well-handled in the `finally` block (lines 504-510). **However**, `_hasPendingTriggers = true` is only set inside `enqueue` (line 213) under the `_isProcessing` branch — if the user triggers `processQueue()` directly (e.g., from `LifecycleSyncManager` or `SyncCubit.forceSync`) while one is already running, the second call quietly returns at the guard and is lost (no `_hasPendingTriggers` flag set), so a freshly-enqueued item between cycles may be missed until the next connectivity event.

### C.2 `lib/core/services/sync_handler.dart` (10 lines) — pure interface.
**No issues.** No default `executeBatch` implementation; handlers either sequence-execute or batch-group independently.

### C.3 `lib/core/blocs/sync/sync_cubit.dart` (82 lines)
**Role**: Repository-pattern bridge between SyncService and the UI bloc; converts `SyncStatus` (the service class) → `SyncState` enum-style states.
**Issues**:
1. The `_resetTimer` (3 seconds auto-reset to SyncIdle after SyncSuccess) can fire after `close()` if the cubit is closed mid-timer — the check `if (!isClosed) emit(...)` at line 57 guards this, but the Timer itself is only cancelled on `close()`. Fine.
2. The cubit is registered as `registerFactory` in DI (injection.dart:130), meaning a **new SyncCubit** is built per BlocProvider creation. State is ephemeral across screens — but the underlying `_syncSubscription` listens to the long-lived singleton `SyncService.statusStream`. **The `SyncStatusBanner` widget lives in many different screens**, each with its own BlocProvider creating a new SyncCubit → the global SyncService stream has multiple bloc listeners, each one re-emitting state into a different provider context. This is acceptable but means emitting one state pushes to multiple subscribers.

### C.4 `lib/core/blocs/sync/sync_state.dart` (48 lines) — clean Equatable states. No issues.

---

## Part D: Hive Box Adapters & Registration

### `lib/main.dart` (105-125 — `_registerHiveAdapters`)
Registers 18 adapters:
- `SyncEntryAdapter` (typeId **100**)
- `UserRoleAdapter` (typeId 11)
- `EducationStageAdapter` (typeId 13)
- `SyncStatusAdapter` (typeId 14)
- `GroupAdapter` (typeId 15)
- `StudentModelAdapter`, `ServantModelAdapter`, `TeamModelAdapter`, `ResultsModelAdapter`, `TermModelAdapter`, `VisitationTypeAdapter` (typeId 16), `PastoralRecordModelAdapter`, `PointsLedgerEntryAdapter`, `AnalyticsSummaryModelAdapter`, `AttendanceMarkStatusAdapter`, `AttendanceMarkAdapter`, `AttendanceSessionModelAdapter`.

**Issues:**
1. **No adapter-registration guard** (`if (!Hive.isAdapterRegistered(typeId))`). Calling `registerAdapter` on an already-registered type throws "typeId already in use" at the adapter equality check (`SyncEntryAdapter` has an `operator ==` that compares typeId — so duplicate registration of the **same** class returns ok; but registration of **different** adapters with overlapping typeIds DOES throw). On warm-restart in dev or inside the Workmanager background isolate, this can raise. Specifically, `main()` calls `_registerHiveAdapters()` after `Hive.initFlutter()`, and the Workmanager `callbackDispatcher` also calls `_registerHiveAdapters()` — **two separate isolates** so they don't share registries, this is OK. But: if `initFlutter` is called twice in the same isolate (e.g., background isolate runs `initFlutter` AND main already did), registration crashes. Review for safe re-entry.
2. **Critical**: `main.dart` lines 60-64 and 138-153 delete `attendance_marks_sync_queue`, `attendance_marks_sync_queue_v2`, `students_sync_queue_box`, `servants_sync_queue_box` boxes from disk on **every** startup AND on **every** Workmanager invocation. This is a "schema migration" path — but it will **DELETE UN-PROCESSED OUTBOX ENTRIES** if these old boxes ever contained any. Verify: per FIX_PLAN P1 these boxes are "dead code" (orphaned, never drained) so deletion is safe — but the cleanup is unconditional and noisy.

### Generated adapters
- `lib/core/models/sync_entry.g.dart` — `SyncEntryAdapter extends TypeAdapter<SyncEntry>` (typeId 100). Matches `@HiveType(typeId: 100)`. OK.
- `lib/core/constants/enums.g.dart` — contains adapter definitions for `SyncStatus` (typeId 14), matching `enums.dart` annotations. OK.
- All `.g.dart` and `.freezed.dart` files under each feature's `data/models/` (StudentModel, ServantModel, TeamModel, ResultsModel, TermModel, PastoralRecordModel, PointsLedgerEntry, AnalyticsSummaryModel, AttendanceMark, AttendanceSessionModel).

### `lib/core/services/dead_letter_queue.dart` (104 lines)
Uses Hive box `dead_letter_queue_box` storing `SyncEntry`. `init()` opens the box with compaction strategy, then prunes entries older than 30 days.
**Issues:**
1. **Line 33** `entry.failedAt = DateTime.now();` — mutates the `SyncEntry` HiveObject in place AFTER it has been removed from the sync_queue box but before being put into the DLQ. Because `SyncEntry extends HiveObject`, mutating a detached HiveObject's field after `box.delete(entry.id)` was called in `_evictToDlq` may attempt to write to the now-closed/original box relation. The comment in `sync_service.dart` (`// Create a clean copy to prevent HiveObject internal binding errors`) confirms the team is aware — they sidestep this in `_evictToDlq` by creating `cleanCopy`. So DLQ-side `entry.failedAt = DateTime.now()` line 33 of `dead_letter_queue.dart` may attempt a write-back to the original box; harmless if the box is open, but a latent bug.
2. `_maxEntries = 100` cap with sort by `failedAt ?? DateTime.fromMillisecondsSinceEpoch(0)` — fine.

### `lib/core/services/hive_pruning_service.dart` (214 lines)
Walks the Hive home directory for boxes whose name starts with `sync_queue_`, opens each, moves entries older than 30 days to the DLQ. Also prunes `attendance_marks_v2`, `attendance_sessions_cache_box`, and the DLQ itself.
**Issues:**
1. **`(Hive as dynamic).homePath`** (line 40) — uses dynamic access to a private Hive field. Works across hive 2.2.3 (`homePath` is exposed on `HiveImpl`), but is brittle and undocumented.
2. **`pruneAll` line 164** uses box name `'sync_queue_box'` as the per-box key — but per-user boxes are named `sync_queue_$userId`. Cosmetic only (key name doesn't affect pruning behaviour).

---

## Part E: Firestore Repository Implementations (write paths / enqueue sites)

### E.1 `lib/features/attendance/data/repos/attendance_repository.dart` (693 lines)
**Sync integration**: builds a `SyncEntry` in `markStudentPresent/late/clearStudentMark/markAllPresentForRemainingStudents`, saves to local cache via `_attendanceLocalDatasource.cacheMark(...)`, then `_syncServiceGetter().enqueue(...)`.
`SyncEntry.id = 'mark_${sessionId}_$studentId'` — deterministic key, so re-marks overwrite (idempotent up to payload).
`syncOfflineMark` and `syncBatchedMarks` perform Firestore writes and best-effort update the local cache.
**Issues:**
1. `clearStudentMark` action type is `'CLEAR_ATTENDANCE'` and the matching handler `AttendanceSyncHandler.execute` calls `_attendanceRepository.clearStudentMark(...)` directly (NOT `syncOfflineClear`). Looking at the handler line 20-30: it calls `clearStudentMark` with `AuthUser(uid: requestedByUid, name: 'System', ...)`. But the original `clearStudentMark` (line 272-298) **does NOT write to Firestore** — it only removes the cached mark + enqueues the SyncEntry. So when the handler runs `clearStudentMark` during sync, it just ... enqueues ANOTHER SyncEntry?! **CHECK THIS** — looking more carefully: actually line 569+ `_attendanceRepository.clearStudentMark(...)` is what the handler invokes — and that method removes the local cache mark AND **enqueues another sync entry**: infinite loop / never actually deletes anything from Firestore! The handler would call `clearStudentMark`, which (a) deletes the local cache, and (b) enqueues a NEW `'CLEAR_ATTENDANCE'` SyncEntry. **No Firestore delete is ever executed for CLEAR_ATTENDANCE**.
   - Cross-check `attendance_command_service.dart`: there's a `clearStudentMark` method (line 568-580) that DOES call `.delete()` on the `_markDoc`. That command service `clearStudentMark` is what the repository SHOULD call (when online). But the **handler routes through the repository** (`IAttendanceRepository.clearStudentMark`), which redirects to the repository's `clearStudentMark` that only enqueues! This is the **critical loop** preventing CLEAR_ATTENDANCE from ever reaching Firestore.

### E.2 `lib/features/attendance/data/repos/attendance_session_repository.dart` (392 lines)
Writes local cache first, then either enqueues a `CLOSE_SESSION` entry (when offline) or `_sessionDoc(teamId, sessionId).update(...)` (when online). `syncOfflineCloseSession`/`syncOfflineSessionCreation` execute the remote write. Both handler mappings registered.
**Issues:** None apparent — cleanest example.

### E.3 `lib/features/student/data/repos/student_data_repository.dart` (714 lines)
Paths: `updateStudent`, `updateStudentAndSyncLinkedUserRole`, `createStudent`, `archiveStudent`, `restoreStudent`, `upsertStudent`.
**Issues:**
1. **`upsertStudent` is a dual-path**: tries online write via `_linkedUserSyncService.updateStudentAndSyncLinkedUserRole` / `_studentsCollection.doc().set()`, and **only on catch** enqueues the SyncEntry. So in the offline case where Firestore throws `unavailable`, the entry gets enqueued — good. But `updateStudent` (line 314) and `archiveStudent` (line 411) **enqueue the SyncEntry unconditionally without trying online first** (line 343 `await _syncServiceGetter().enqueue(syncEntry); unawaited(_syncServiceGetter().processQueue());`) — there's no connectivity check, no online attempt. Means online edits are always routed through the offline queue first even when the user is online — bypassing the synchronous failure signalling path. **Inconsistent with team/servant/repository which check connectivity first.**
2. **`syncOfflineCreateWithAuth`** writes an `invitations` doc and uses `runTransaction`. If the transaction fails (e.g., student already exists), it throws, and the SyncService will keep retrying 5 times → each retry will re-write the invitation doc (idempotent via `set`) and re-attempt the transaction. Behavior is acceptable.
3. **`clientUpdatedAt` Last-Write-Wins protection (lines 551-562, 606-617, 657-663, 702-708)** — fine. Compares payloadTime vs localTime to avoid overwriting fresher local edits.
4. **`syncOfflineUpdate` redirects to `syncOfflineUpsert`** (line 504-507) — handlers using `'UPDATE_STUDENT'` actionType will receive full upsert behavior; the `'UPDATE_STUDENT'` case in the handler (line 18-19) calls `syncOfflineUpdate` which calls `syncOfflineUpsert`. Fine but the actionType `'UPDATE_STUDENT'` is never enqueued by any repository code (only `UPSERT_STUDENT` is enqueued), so this switch arm is dead.

### E.4 `lib/features/student/data/repos/pastoral_repository.dart` (231 lines)
**Issues:**
1. **`createPastoralRecord`** has a `try/catch` that catches ANY non-network exception (line 93-99, just `catch (e)`), and unconditionally enqueues the sync entry. So even a permissions failure (PERMISSION_DENIED) or validation error in Firestore will enqueue the entry — and the SyncService will retry 5 times before evicting to DLQ. **No rethrow on errors that aren't network-related**. Contrast with StudentDataRepository.upsertStudent which is similar. Bad pattern.

### E.5 `lib/features/team/data/repos/team_repository.dart` (1102 lines)
**Issues:**
1. `createTeam`, `updateTeam`, `deleteTeam`, `restoreTeam` all check connectivity first; enqueue only when offline OR when online write fails. After successful online write, mark local cache as `synced`. Cleanest path.
2. **All online transaction errors except `StateError` (duplicate name) and `TeamNotFoundFailure`** silently enqueue as fallback (line 457-473, 574-591, 706-720, 815-832). So a permissions-denied error enqueues the entry → it will retry 5 times → DLQ. Same bad pattern as pastoral.
3. **`syncTeamNameReferences`** uses `Source.server` reads and chunked batches — this runs AFTER the team transaction commits, outside the transaction. If the second batch fails partway, students/users retain stale `team_name` field. Not a sync-queue issue per se but worth noting.

### E.6 `lib/features/results/data/repos/results_repository.dart` (286 lines)
**Issues:**
1. `updateResult` has the right pattern — check connectivity, enqueue if offline, online write with `unavailable`/`deadline-exceeded` fallback to queue, generic `catch` enqueues as last resort (line 235-242). The non-network `catch (e)` will enqueue errors that are not actually network-related — same retry-storm pattern.
2. `syncOfflineUpdate` uses runTransaction with LWW check (lines 261-280) — clean.

### E.7 `lib/features/servant/data/repo/servant_data_repository.dart` (661 lines)
**Issues:**
1. `createServant`, `upsertServant`, `updateServantFields`, `deleteServant`, `restoreServant` — consistent two-path pattern (try-online → on `catch (_)`, enqueue). All non-network errors silently enqueue → retry storm.
2. **Uses `SyncService` directly (no `Function() getter`)**: `final SyncService _syncService;` (line 26). This is the only repository that takes a direct instance instead of a getter. Inconsistent DI shape — if SyncService were ever async-resolved (e.g., lazy registration), this would break. As SyncService is a `registerLazySingleton` this is OK today.

---

## Part F: Network Connectivity Checking Code

### F.1 `lib/core/blocs/connectivity/connectivity_cubit.dart` (57 lines)
**Issue resolved**: The `FIX_PLAN.md` claims "no reachability check" (P4) — but the **current code already implements** `_isReachable()` DNS lookup at lines 26-36 with `InternetAddress.lookup('firestore.googleapis.com').timeout(3s)`. So P4 / I1 is **already addressed**. (Note: this FIX_PLAN docs file is dated June 30, 2026 — older than current implementation, the fix landed in commit `4e490b0` / `bfbf799` / later.)

### F.2 `lib/core/blocs/connectivity/connectivity_state.dart` (17 lines) — clean.

### F.3 `lib/shared/widgets/offline_indicator.dart` (40 lines)
Bound to ConnectivityCubit. No issues.

### F.4 Note on `connectivity_plus` semantics
`SyncService` and each repository use `connectivity.checkConnectivity()` returning `List<ConnectivityResult>` (API changed in `connectivity_plus` 6.x — returns List). All comparisons correctly use `results.contains(ConnectivityResult.none)`. OK.

---

## Part G: DI / Service Locator Setup

### `lib/core/di/injection.dart` (326 lines) — uses **`get_it` (^9.2.1)**, NOT injectable.
Despite `pubspec.yaml` listing `injectable: ^2.7.1+4` and `injectable_generator`, **the only DI file is `injection.dart`** — pure hand-written `getIt` calls. **No `@Injectable`/`@LazySingleton` annotations** appear anywhere; the injectable package is unused at the moment.

**Sync-related registrations:**
- All 7 sync handlers are `registerLazySingleton` (lines 80-100).
- `Map<String, SyncHandler>` literal passed to `SyncService` with 14 action → handler entries (lines 109-127). **Conspicuous gap**: `'CLEAR_ATTENDANCE'` is mapped to `AttendanceSyncHandler` (line 111) — and per §E.1 that handler routes back into the repository's `clearStudentMark` which re-enqueues. So this mapping confirms the loop.
- `DeadLetterQueue`, `HivePruningService`, `SyncService` are all `registerLazySingleton`.
- `SyncCubit` is `registerFactory` (line 130) — fresh instance per BlocProvider.
- `ConnectivityCubit` is `registerLazySingleton` (line 133) but `church_app.dart` line 25 uses `BlocProvider(create: (context) => getIt<ConnectivityCubit>())` — fine; but the singleton streams from a BlocProvider scope means closing the cubit when its provider is disposed would also close the singleton's subscription stream. **Check**: `ConnectivityCubit.close()` cancels the connectivity subscription; if BlocProvider disposes a singleton, subsequent app re-launches calling `ConnectivityCubit()` would NOT recreate it because `registerLazySingleton` caches — but the subscription is already gone! Latent bug if `SyncCubit`/`ConnectivityCubit` get disposed and re-provided (e.g., on hot-reload during dev).
- Repositories take `syncServiceGetter: getIt.call` — meaning the getter invokes `getIt<SyncService>` fresh each call. This defers resolution until call time and is the safer pattern. **Note**: `ServantDataRepository` takes `syncService: getIt<SyncService>()` directly (eager resolution) — inconsistent.

### `lib/church_app.dart` (31 lines)
- Builds `AuthBloc` with `syncService: getIt<SyncService>()` directly in the BlocProvider (eager resolution).
- BlocProvider for `SyncCubit` (factory) and `ConnectivityCubit` (singleton-as-factory).

### `lib/features/auth/presentation/bloc/auth_bloc.dart` (434 lines)
- **Line 425**: `unawaited(_syncService.setAuthenticatedUser(uid));` — this is on the `AuthBloc.onTransition` hook (every state transition). For `AuthAuthenticated`/`AuthDegraded`/`AuthRoleUpdated` states it passes the user's uid; for any other state (`AuthUnauthenticated`, `AuthInitial`, etc.), `uid` stays null and `setAuthenticatedUser(null)` runs, which closes the active box, cancels Workmanager tasks, and resets state. **OK**, but `unawaited` means if `setAuthenticatedUser` throws (e.g., Hive open fails), the error is swallowed. Should be `await` (or wrapped with catchError).
- On `AuthRoleUpdated` state (line 422-423), `nextState.user.uid` is captured — but I should verify that `AuthRoleUpdated` actually carries a `user` field. Not investigated further here; flag for review.

---

## Part H: pubspec.yaml Dependencies Related to Sync

From `C:\Users\KimoStore\church_managment_system\pubspec.yaml`:

### Sync/Hive/Firestore/Connectivity dependencies
- `cloud_firestore: ^6.2.0` — Firestore SDK
- `connectivity_plus: ^7.1.1` — network state
- `hive: ^2.2.3` + `hive_flutter: ^1.1.0` — local SSOT store
- `firebase_auth: ^6.2.0` + `firebase_core: ^4.5.0`
- `get_it: ^9.2.1` — service locator (note: `injectable: ^2.7.1+4` and `injectable_generator` are listed but unused)
- `workmanager: ^0.9.0+3` — background execution (Android/iOS only!)
- `uuid: ^4.5.3` — SyncEntry IDs
- `rxdart: ^0.28.0` — likely for stream operations (not seen directly in sync code)
- Dev: `hive_generator: ^2.0.1`, `build_runner: ^2.4.13`, `fake_cloud_firestore: ^4.0.1`, `mocktail: ^1.0.4`, `freezed: ^2.5.2`, `freezed_annotation: ^2.4.4`.

### Specific observations
- **`workmanager` 0.9.0** has known limitations: only Android (full), iOS (best-effort one-off), no Web/desktop. Peruser `main.dart` callbackDispatcher is `@pragma('vm:entry-point')` correctly set. The callback verifies `payloadUid == currentUid` (line 44-52) — **will silently terminate on every background task run when the background isolate lacks/firebase auth hasn't restored the user**, which on a cold device reboot is the common case! Firebase Auth persists sessions, but the inherently asynchronous `FirebaseAuth.instance.currentUser` may be null in the first ms after isolate spawn. This is a **probable root cause of "sync never happens in the background"** symptoms.
- `injectable` declared but **unused** (no `@Injectable` anywhere in the codebase per `Grep "TODO"` empty result and review of injection.dart — confirmed no annotations).

---

## Part I: TODO/FIXME/HACK Comments

A grep for `TODO`, `FIXME`, `HACK`, `XXX` in `lib/**/*.dart` returned **NO matches**. The codebase currently has zero outstanding inline-TODO comments related to sync (or anything else) in lib/.

---

## Part J: Existing Review Documentation Found

Beyond the requested file classes, the project contains a `csms-review/` directory with 10 markdown files. Most relevant:

| File | Path |
|------|------|
| Sync Handlers Review | `C:\Users\KimoStore\church_managment_system\csms-review\04-sync-handlers-review.md` |
| Critical Findings Summary | `C:\Users\KimoStore\church_managment_system\csms-review\09-critical-findings-summary.md` |
| Fix Plan | `C:\Users\KimoStore\church_managment_system\csms-review\FIX_PLAN.md` |

**Important note**: The `FIX_PLAN.md` (dated June 30, 2026) explicitly says "Verified Against Current Code" but my investigation found several claims are **already stale / partially fixed**:
- P4 / I1 (ConnectivityCubit reachability) — **ALREADY IMPLEMENTED** in `connectivity_cubit.dart` lines 26-36.
- I5 (Results edits never sync) — **ALREADY FIXED** per the doc's own verification row; ResultsRepository has full enqueue path (file §E.6 above).
- C3 (StudentModel missing syncStatus) — **ALREADY FIXED** (verified by grep finding `syncStatus: SyncStatus.pending/synced` usage in repositories).
- C4 (Session creation offline-first) — **ALREADY FIXED** (`AttendanceCommandService.createSession` enqueues when offline; seeattendance_command_service.dart:141-150).
- Min2 (sl.reset()) — confirmed **not present**.

So when debugging the sync feature, the FIX_PLAN P1 ("dual sync queue") claim about `attendance_marks_sync_queue_v2` should be investigated separately — the box deletion code in `main.dart:62-64,151-153` strongly suggests the team already cleans it from disk on startup, but you should verify whether **the orphaned write path to `attendance_marks_sync_queue_v2`** still exists in the current `AttendanceLocalDatasource`. Per my read of `attendance_local_datasource.dart` (101 lines, listed above), **the box reference is gone** — the only box used now is `attendance_marks_v2` (line 9). So **P1 is also resolved at the datasource level**.

---

## Part K: Summary of Most Likely Sync-Breaking Issues (ranked)

This is the evidence-gathering summary; no fixes attempted.

1. **🔴 CLEAR_ATTENDANCE handler loops back into the repository's enqueue-only `clearStudentMark` method** (`attendance_sync_handler.dart` line 20 calls `_attendanceRepository.clearStudentMark(...)` which at `attendance_repository.dart` lines 272-298 only removes local cache and enqueues a new `'CLEAR_ATTENDANCE'` SyncEntry — never invokes a Firestore delete). This creates a **self-feeding queue** where the entry is never actually cleared from Firestore, and depending on retry semantics may match the original entry ID and increment retry counts toward DLQ. Coordinate with `attendance_command_service.dart` `clearStudentMark` (line 568-580) which DOES do `.delete()` — the handler should call the command service, not the repository.

2. **🔴 `_activeBox` not assigned inside `retryDlq()`** when `_activeBox` is null on entry (`sync_service.dart` lines 275-307). The function opens a dynamic box reference, populates it, then closes — but `_activeBox` stays null. The subsequent `unawaited(processQueue())` hits the guard at line 312 and silently aborts. **DLQ retry will never resume syncing** until something else opens `_activeBox` (i.e., next `setAuthenticatedUser` after re-login).

3. **🔴 `setAuthenticatedUser` is fire-and-forget (`unawaited`) from `auth_bloc.dart` line 425** — if its `Hive.openBox<SyncEntry>` throws (e.g., adapter mismatch on schema drift, or Hive file corruption), the error is swallowed and the active user's queue will never be mounted. `_activeBox` remains null, so every subsequent `enqueue` opens the box **dynamically** (line 192-196) but won't help if HappensBefore the first enqueue; and `processQueue` immediately returns (line 312).

4. **🔴 Workmanager background isolate frequently cannot resolve `FirebaseAuth.instance.currentUser`** in `main.dart` callbackDispatcher lines 43-46 — if Firebase Auth hasn't restored its session yet on a cold-booted background isolate, the task silently returns `true` without processing the queue. The `initAndProcessOnce` check at `sync_service.dart` lines 173-177 (`if (firebaseUid != null)`) compounds this — the queue only processes for **currently-logged-in users**, which means offline edits queued by user A can NEVER sync if A is logged out (by design — per-user box).

5. **🔴 Two classes named `SyncStatus`** (sync_service.dart:13 — idle/processing/success/error/dlqEviction + dlqEntryId; enums.dart:26 — pending/synced/failed). Every repository uses `hide SyncStatus` to mask the sync_service class. The Repository files use the enum (`SyncStatus.pending`). The `sync_cubit.dart` StreamSubscription is typed `<SyncStatus>` resolving to the **service-class** variant. If anyone imports sync_service **without `hide SyncStatus`** AND wants to use the enum, they get the wrong class — easily missed.

6. **🔴 Repositories catch generic `catch (e)` and enqueue** even on PERMISSION_DENIED or schema-validation errors (`pastoral_repository.dart` lines 93-100; `team_repository.dart` all four mutations; `results_repository.dart` 235-242; `servant_data_repository.dart` all mutations). Non-network errors silently enqueue. With `_maxRetries=5` and 30s cap backoff, a permanent permission error will burn 5 retries per entry then DLQ-evict — and the DlqWarning UI just says "tap to retry", which will re-enqueue and re-fail.

7. **🔴 `unawaited(processQueue())` re-entry gap** — only `enqueue()` sets `_hasPendingTriggers = true` (line 213) under the `_isProcessing` branch. Direct external callers of `SyncService.processQueue()` (LifecycleSyncManager line 34, SyncCubit.forceSync line 68, init lines 166) — if any fire WHILE `_isProcessing` is true, the call returns silently at line 311 and no `_hasPendingTriggers` flag is set → a freshly-enqueued item may go unprocessed until the next connectivity event or enqueue call.

8. **🟡 Adapter registration without `isRegistered` guard** — high-churn dev environments with hot restart may crash if `_registerHiveAdapters` is called twice in the same isolate. Currently it isn't (main path once, callbackDispatcher in separate isolate) but worth hardening.

9. **🟡 `SyncCubit` registered as `registerFactory`** in DI but `SyncService` is a singleton. Each screen BlocProvider creates a new cubit with a new subscription to the long-lived `statusStream`. The 3-second `_resetTimer` in sync_cubit fires only on the most recently created cubit's SyncSuccess — older cubits (from earlier screens still on the stack) won't reset to idle.

10. **🟡 `SyncPayload` typed hierarchy in `sync_payload.dart` appears unused** — repositories build raw `Map<String, dynamic>` payloads inline; no `UpsertStudentPayload` etc are instantiated. Type-safety loss; possible refactoring artifact.

11. **🟡 `processQueue` re-scans entire box per iteration** — O(n² log n) on a 50-entry queue. Latency not correctness.

12. **🟡 `dead_letter_queue.dart` line 33 mutates `entry.failedAt`** of a possibly-still-bound HiveObject. The `_evictToDlq` caller in `sync_service.dart` already creates a `cleanCopy` to avoid this, but DLQ's internal `add` re-mutates — defensive copy should be made in the add() method.

---

## Part L: Files Grep Results — Complete sync/queue/pending/upload Matches in lib/

The grep for `sync|queue|pending|upload` in `lib/**/*.dart` returned **100+ matches** (truncated). Distribution summary:
- `lib/core/services/sync_service.dart` — primary engine (every relevant keyword).
- `lib/core/services/lifecycle_sync_manager.dart` — calls `processQueue`.
- `lib/core/services/dead_letter_queue.dart` and `hive_pruning_service.dart` — queue contents.
- `lib/core/di/injection.dart` — handler registrations + SyncServiceGetters.
- `lib/core/widgets/sync_*.dart` and `lib/shared/widgets/sync_*.dart` — UI.
- `lib/core/blocs/sync/sync_cubit.dart` + `sync_state.dart` — bloc.
- `lib/main.dart` — adapter registration + Workmanager dispatcher + cleanup of orphaned queue boxes.
- `lib/church_app.dart` — BlocProvider for SyncCubit + ConnectivityCubit + AuthBloc wiring.
- `lib/features/{attendance,student,servant,team,results}/data/{services,repos}/...` — repository enqueue sites and handler implementations.
- `lib/features/auth/presentation/bloc/auth_bloc.dart` — `setAuthenticatedUser` hook.
- `lib/features/auth/presentation/widgets/auth_gate.dart` — SyncStatusIndicator at line 68.
- `lib/features/attendance/presentation/screens/*` — SyncStatusBanner embedded.
- `lib/features/servant/presentation/screens/servant_list_screen.dart:205` — SyncStatusBanner.
- `lib/features/team/presentation/screens/team_management_screen.dart:267` — SyncStatusBanner.
- `lib/features/{team,servant,student}/domain/entities/*.dart` and `data/models/*.freezed.dart|g.dart` — `syncStatus`-field declarations and enum maps.

---

## Conclusion (evidence only — no fixes applied)

The CSMS sync engine has a sound outbox-pattern architecture (per-user Hive boxes, sequential FIFO with consecutive-chunking for MARK_ATTENDANCE, DLQ, exponential backoff, Workmanager periodic task, lifecycle resume, connectivity streams). Most of the originally-flagged critical issues in `csms-review/FIX_PLAN.md` are **already resolved** in current code (StudentModel syncStatus, session offline create, results enqueue, connectivity reachability, removal of the dual-queue orphan).

The most probable **broken-sync** causes the user should investigate first, based on this evidence:
- **#1 CLEAR_ATTENDANCE handler → repository re-enqueue loop** (no Firestore delete ever fires for clears).
- **#2 `retryDlq()` doesn't update `_activeBox`** — DLQ retry attempts from UI will fail silently.
- **#3 `setAuthenticatedUser` invoked `unawaited`** from AuthBloc — open-box failures swallowed; active queue never mounts.
- **#6 Generic catch-and-enqueue** in pastoral/team/results/servant repositories — non-network errors silently retry-storm into DLQ.
- **#4 Workmanager callback warding on currentUser.uid** — background sync rarely fires when foreground session is unavailable.
