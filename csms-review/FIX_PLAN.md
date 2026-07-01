# CSMS Fix Plan — Verified Against Current Code

> **Status**: Review re-verified against `lib/` source (June 30, 2026).
> Several claims in the original review are already fixed or less severe.
> This plan includes ONLY genuine issues that remain.

---

## Verification Summary

| # | Original Claim (from review) | Actual Status | See |
|---|------------------------------|---------------|-----|
| C1 | Dual sync queue → data corruption | **Dead code only** — `AttendanceMarkRepository` registered in DI but **never injected into any consumer**. The orphaned `attendance_marks_sync_queue_v2` is written to but **never drained**. The main path (`AttendanceRepository` + `SyncService`) is clean. | P1 |
| C2 | Sync handler bypasses local cache | **Mostly fine** — local cache already has the mark from the initial offline write. Server timestamp divergence is cosmetic. Minor issue at worst. | P2 |
| C3 | Missing `syncStatus` on `StudentModel` | **Already Fixed** — `StudentModel` has `@HiveField(25) SyncStatus syncStatus` with `syncStatus → synced` reset on both online and offline-replay paths. | ✅ |
| C4 | Session creation has no offline-first write | **Already Fixed** — `AttendanceCommandService.createSession()` writes locally + enqueues `SyncEntry` when offline. | ✅ |
| I1 | No reachability check in ConnectivityCubit | **Confirmed** — only `connectivity_plus`, no HTTP ping. | P4 |
| I2 | Wrong auth stream (`idTokenChanges`) | **Confirmed** — `firebase_auth_repository.dart:53` uses `.idTokenChanges` causing unnecessary hourly re-fetches. | P5 |
| I3 | No offline caching for Team BLoC | **Already Fixed** — `TeamRepository` has full cache-first reads + `SyncEntry` writes + handler registered. | ✅ |
| I4 | No offline caching for AdminDashboard | **Partially** — only teams are cached; students/servants/stats hit Firestore directly with `forceRefresh: true` on stats. | P6 |
| I5 | Results edits never sync | **Already Fixed** — `ResultsRepository` creates `SyncEntry` + enqueues; `ResultSyncHandler` registered in DI and handlers map. | ✅ |
| I6 | Double `isActive` check | **Not Found** — no `checkStatus()` method exists in current code. Claim is stale. | ✅ |
| I7 | No Transaction in WriteBatch | **Addressed** — `syncBatchedMarks` uses `WriteBatch` (acceptable — batch is idempotent, LWW protects conflicts). | P7 |
| Min1 | Missing student `isActive` in rules | **Confirmed** — student read rules don't gate on `isActive`/`isArchived`. | P8 |
| Min2 | `sl.reset()` deregisters singletons | **Not Found** — no `sl.reset()` or `getIt.reset()` anywhere. Claim is false. | ✅ |
| Min3 | Missing explicit offline states in BLoCs | **Confirmed** — several BLoCs lack offline-specific states. | P9 |
| Min4 | Missing offline banner on AttendanceTakingScreen | **Not verified** — screen may not have local offline banner (relies on global). | P9 |
| Min5 | Race condition in admin provisioning | **Confirmed** — `AdminUserProvisioningService.createUser()` is NOT in a Firestore Transaction. | P10 |

---

## Priority-Fix Items

### P1: Remove dead `AttendanceMarkRepository` + orphaned sync queue
**Effort: Small** | **Impact: Cleanup + confusion reduction**

- `AttendanceMarkRepository` is registered in `injection.dart:179` but **zero consumers** resolve it
- `attendance_marks_sync_queue_v2` Hive box is opened every init but **never drained** (`getPendingEntries()` has no callers)
- `MarkSyncEntry` model is dead code
- **Action**: Remove `AttendanceMarkRepository` DI registration. Keep the class file as-is (no-op) until next cleanup pass, or delete together with `mark_sync_entry.dart` and `_syncQueueBox` reference in `AttendanceLocalDatasource`.

**Files**: `lib/core/di/injection.dart:179-186`, `lib/features/attendance/data/local/mark_sync_entry.dart`, `lib/features/attendance/data/local/attendance_local_datasource.dart:14,21-23,27-28,93-114`, `lib/features/attendance/data/repos/attendance_mark_repository.dart` (242, 357)

---

### P2: Update local cache after `syncOfflineMark` in AttendanceCommandService
**Effort: Small** | **Impact: Cosmetic (timestamp sync)**

Currently `AttendanceCommandService.syncOfflineMark()` writes to Firestore in a transaction but does NOT refresh the local Hive cache with the server-written data. The local cache retains the original offline mark (with local timestamps vs `FieldValue.serverTimestamp()`). After the `SyncEntry` is deleted from the queue, the next read from cache shows stale timestamps.

**Action**: After the transaction in `syncOfflineMark()` (line 623), call `_attendanceLocalDatasource.cacheMark()` with the server data. The handler doesn't currently have access to `AttendanceLocalDatasource` — inject it or update the cache via the repository layer.

**Alternative**: Accept the cosmetic drift (local timestamps differ from server until the next re-fetch). This is a Minor issue.

---

### P3: Sync handler local cache update (attendance marks)
Same as P2 — the `syncOfflineMark` path in `AttendanceCommandService` is the implementation behind `AttendanceSyncHandler`. No separate fix needed.

---

### P4: Add HTTP reachability check to ConnectivityCubit
**Effort: Small** | **Impact: Prevents silent sync failures on captive WiFi**

`connectivity_cubit.dart` only checks `connectivity_plus` which reports WiFi/cellular as online even when there's no actual internet (captive portals, dead routers, etc.). This causes `SyncService` to attempt syncs that silently fail.

**Action**: Add a lightweight HTTP HEAD check (e.g., to `https://firestore.googleapis.com` or a known Firebase endpoint) with short timeout (3s). Only emit `ConnectivityOnline` if both connectivity_plus says online AND the reachability check succeeds. Use `ConnectivityOffline` on either failure.

**Files**: `lib/core/blocs/connectivity/connectivity_cubit.dart`

```dart
Future<bool> _isReachable() async {
  try {
    final result = await InternetAddress.lookup('firestore.googleapis.com')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
```

---

### P5: Switch FirebaseAuthRepository from `idTokenChanges()` to `authStateChanges()`
**Effort: Small** | **Impact: Reduces Firestore reads (Spark plan)**

`firebase_auth_repository.dart:53` uses `_identityProvider.idTokenChanges` which fires on every ID token refresh (~hourly) plus sign-in/out. `authStateChanges()` only fires on actual auth state changes (sign-in, sign-out, token refresh when user data changes).

**Action**: Change to `_identityProvider.authStateChanges`. Verify that the `asyncMap` callback still works correctly (it does — the same Firestore profile fetch runs regardless).

**Files**: `lib/features/auth/data/repos/firebase_auth_repository.dart:53`

---

### P6: Cache students, servants, and stats in AdminDashboardBloc
**Effort: Medium** | **Impact: Makes dashboard available offline + reduces reads**

Currently `AdminDashboardBloc` fetches students (`_studentRepository.getAllStudents`) and servants (`_servantRepository.getAllServants`) directly from Firestore each load. Stats are fetched with `forceRefresh: true` bypassing the 1-hour TTL cache in `AdminStatisticsService`.

**Action**: 
1. Change `_statisticsService.getGlobalDashboardStats(forceRefresh: true)` to `forceRefresh: false` (or remove the parameter, letting the service's TTL manage refresh cadence)
2. Add a simple Hive-backed `AdminDashboardLocalDatasource` that caches the dashboard aggregate data (students count, servants count, teams with student counts, stats)
3. Implement cache-first reads with background refresh in the BLoC (same pattern as session cache)

**Files**: `lib/features/admin/presentation/bloc/dashboard/admin_dashboard_bloc.dart:75`, `lib/features/admin/data/services/admin_statistics_service.dart:73-101`

---

### P7: Add local cache write after batch sync in AttendanceCommandService
**Effort: Small** | **Impact: Cache freshness**

`syncBatchedMarks()` writes to Firestore via `WriteBatch` but doesn't update the local `attendance_marks_v2` cache. Same as P2 but for the batch path. After batch sync completes successfully, iterate the payloads and call `_attendanceLocalDatasource.cacheMark()` for each.

**Note**: The command service doesn't have access to `AttendanceLocalDatasource` currently. Either inject it, or handle this in the repository layer (the handler could update cache before delegating).

---

### P8: Add student `isActive` check to Firestore security rules
**Effort: Small** | **Impact: Security consistency**

Student read rules (`firestore.rules:193-198`) allow reading inactive/archived students via `callerManagesStudentSector(resource.data)`. Servant rules gate on `isArchived`. Add consistency:

```javascript
// In student read rule
allow read: if isSignedIn() && (
  studentId == uid() || 
  resource.data.uid == uid() ||
  isAdmin() ||
  (callerManagesStudentSector(resource.data) && !isArchived(resource.data))
);
```

Where `isArchived()` is a helper checking `resource.data.isArchived == true`. This prevents servants from seeing archived students in their sector.

---

### P9: Add screen-level offline banner + explicit offline BLoC states
**Effort: Medium** | **Impact: UX clarity**

**Offline banner on AttendanceTakingScreen**: Add a local banner (different from global `OfflineIndicator`) that shows "يتم حفظ الحضور محلياً وسيتم المزامنة لاحقاً" when offline but marks are being taken. Use `ConnectivityCubit` stream.

**Explicit offline states**: BLoCs currently use implicit offline behavior (data just isn't there). Add dedicated states:
- `AttendanceTakingOffline` / `AttendanceTakingOnline`
- `DataLoadedCached` vs `DataLoadedFresh`
- Surface these in screens with appropriate messaging

**Files**: `lib/features/attendance/presentation/screens/attendance_taking_screen.dart`, multiple BLoC state files

---

### P10: Wrap AdminUserProvisioningService.createUser in Transaction
**Effort: Small** | **Impact: Prevents orphaned auth accounts**

`createUser()` in `admin_user_provisioning_service.dart:44-94` calls `_adminAuthClient.createUser` then `_userProfileStore.saveUser` as two separate operations with only a manual rollback catch. If the app crashes between these two steps, an auth user is created with no Firestore profile document.

**Action**: This is inherently non-atomic (Firestore `runTransaction` can't wrap the external `_adminAuthClient.createUser` call). Instead, improve the compensation: make the profile write idempotent on the auth UID, and add a background reconciliation check. Alternatively, accept the risk as-is (Spark plan limitation — no Cloud Function to reconcile).

---

## Execution Order

```
Week 1: P1 (cleanup), P5 (auth stream), P8 (rules) — safe, isolated changes
Week 2: P4 (reachability), P2/P7 (cache after sync) — sync reliability
Week 3: P6 (dashboard caching) — larger effort, multiple files
Week 4: P9 (offline UX), P10 (admin provisioning) — polish
```

---

## How to Proceed

Each `P#` above is a self-contained unit. Pick one and say:

> "Implement P4: ConnectivityCubit reachability check"

And I'll produce the implementation with tests.
