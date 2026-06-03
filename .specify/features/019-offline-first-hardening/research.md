# Research: Offline-First Architecture Hardening

## 1. Current State Audit Results

### Decision: Feature-by-feature gap matrix
### Rationale: Systematic analysis of every data layer to identify exact gaps

| Feature | Local DS | Hive-First Reads | Write-Through (Hive→Firestore) | Sync Queue on Failure | SyncService Route | UI Banner |
|---------|----------|------------------|-------------------------------|----------------------|-------------------|-----------|
| **Student** | ✅ `StudentLocalDatasource` | ⚠️ Partial — `create/update` use Hive, but `getAll/search/getByClass` delegate to `StudentQueryService` which hits Firestore directly | ✅ `create/update` save to Hive first | ✅ `queueForSync` called | ✅ `UPDATE_STUDENT` routed | ✅ Added |
| **Servant** | ✅ `ServantLocalDatasource` | ✅ All read methods check Hive first | ✅ `update` caches first, `create` caches first | ⚠️ Only on `updateServant` catch — `create/archive/restore/delete` crash offline | ⚠️ No `UPDATE_SERVANT` route | ✅ Added |
| **Attendance Marks** | ✅ `AttendanceLocalDatasource` | ⚠️ `getMarkForStudent` uses `_cachedGet` (Firestore SDK cache) NOT Hive | ✅ `createMark/updateMark` enqueue to local sync queue | ✅ Internal queue via `MarkSyncEntry` | ✅ `MARK_ATTENDANCE` routed | ✅ (on taking screen) |
| **Attendance Sessions** | ❌ No local DS | ⚠️ Uses Firestore SDK `Source.cache` fallback — not Hive | ❌ `setSessionClosed()` hits Firestore directly — crashes offline | ⚠️ Only `CREATE_SESSION` has stub route (TODO) | ⚠️ `CREATE_SESSION` route is a no-op stub | ✅ Added |
| **Team** | ❌ No local DS | ❌ `_cachedGet` only uses Firestore SDK cache | ❌ All mutations hit Firestore directly — crash offline | ❌ No queueing | ❌ No route | ✅ Added |
| **Results** | ❌ No local DS | ⚠️ `getResultsForServant` tries Firestore cache first | ❌ `updateResult` hits Firestore directly — crashes offline | ❌ No queueing (only `syncOfflineUpdate` for replay) | ✅ `UPDATE_RESULT` routed | ❌ Not added |

---

## 2. Background Sync Strategy

### Decision: Use `workmanager` package for Android background task execution
### Rationale: 
- Only package that supports periodic background tasks on Android without Cloud Functions
- Compatible with Spark plan (client-side only)
- The current `connectivity_plus` listener only fires when the app is active in memory
- If the app is killed and the user reconnects to Wi-Fi, data sits in Hive queue until manual app launch

### Alternatives Considered:
- **`flutter_background_service`**: Keeps a foreground service running (battery drain, user-visible notification required)
- **`isolate` approach**: Cannot run Hive/Firestore in background isolate without complex setup
- **Firebase Cloud Messaging (data message)**: Requires backend to send push — violates Spark constraint
- **Do nothing (status quo)**: Unacceptable — users lose data if they close app before sync

### Implementation Notes:
- Register a `oneOffTask` when enqueuing a SyncEntry (if app is backgrounding)
- Register a `periodicTask` (minimum 15min on Android) as safety net
- The callback must re-initialize Hive + Firebase since it runs in a separate isolate
- Use `Constraints(networkType: NetworkType.connected)` to only run when online

---

## 3. Missing Local Datasources

### Decision: Create `TeamLocalDatasource`, `AttendanceSessionLocalDatasource`, `ResultsLocalDatasource`
### Rationale: Without Hive-backed local storage for these features, reads always require network and writes crash offline

### Alternatives Considered:
- **Rely on Firestore SDK offline cache**: Unreliable — cache can be evicted, limited query support, and Source.cache throws if nothing cached
- **SharedPreferences**: Not suitable for structured/relational data or large datasets

---

## 4. SyncService Routing Gaps

### Decision: Complete the `_executeEntry` switch statement for all action types
### Rationale: Currently `CREATE_SESSION` is a stub (TODO comment) and `UPDATE_SERVANT`, `CREATE_TEAM`, `UPDATE_TEAM`, `ARCHIVE_STUDENT`, `RESTORE_STUDENT` etc. have no routes at all

### New Action Types Needed:
| Action Type | Target Repository | Method |
|------------|-------------------|--------|
| `CREATE_SESSION` | `AttendanceSessionRepository` | `syncOfflineSessionCreation()` (exists) |
| `CLOSE_SESSION` | `AttendanceSessionRepository` | New: `syncOfflineSessionClose()` |
| `UPDATE_SERVANT` | `IServantRepository` | New: `syncOfflineUpdate()` |
| `CREATE_SERVANT` | `IServantRepository` | New: `syncOfflineCreate()` |
| `ARCHIVE_SERVANT` | `IServantRepository` | New: `syncOfflineArchive()` |
| `CREATE_TEAM` | `ITeamRepository` | `createTeam()` (replay) |
| `UPDATE_TEAM` | `ITeamRepository` | `updateTeam()` (replay) |
| `ARCHIVE_TEAM` | `ITeamRepository` | `deleteTeam()` (replay) |
| `ARCHIVE_STUDENT` | `IStudentRepository` | New: `syncOfflineArchive()` |
| `RESTORE_STUDENT` | `IStudentRepository` | New: `syncOfflineRestore()` |
| `UPDATE_RESULT` | `IResultsRepository` | `syncOfflineUpdate()` (exists) |

---

## 5. UI State Gaps

### Decision: Standardize all BLoC states to include an `isOffline` flag and `syncStatus` indicator
### Rationale: Users need clear feedback when operating offline vs online, and when data shown is stale (from cache)

### Current UI State Issues:
1. **No "Offline Mode" indicator** — user doesn't know they're offline until a write fails
2. **No "Data from cache" badge** — stale data looks identical to fresh data
3. **Empty states show generic messages** — should distinguish "no data" from "offline, showing cached data" from "offline, no cached data available"
4. **SyncStatusBanner only shows during active sync** — no persistent offline indicator

---

## 6. Write-Through Pattern Gaps

### Decision: Every mutation must follow the pattern: Hive → try Firestore → catch → enqueue SyncEntry
### Rationale: Consistency. Currently only Student create/update and Attendance mark create/update follow this pattern.

### Methods That Crash Offline (need fixing):
| Repository | Method | Current Behavior |
|-----------|--------|-----------------|
| `StudentDataRepository` | `upsertStudent()` | Direct Firestore `.set()` — crashes |
| `StudentDataRepository` | `archiveStudent()` | Direct Firestore batch — crashes |
| `StudentDataRepository` | `restoreStudent()` | Direct Firestore batch — crashes |
| `ServantDataRepository` | `createServant()` | Writes Hive but still throws on Firestore failure |
| `ServantDataRepository` | `archiveServant()` | Direct Firestore `.update()` — crashes |
| `ServantDataRepository` | `deleteServant()` | Direct Firestore `.delete()` — crashes |
| `ServantDataRepository` | `restoreServant()` | Direct Firestore `.update()` — crashes |
| `TeamRepository` | ALL mutations | Direct Firestore transactions — all crash |
| `ResultsRepository` | `updateResult()` | Direct Firestore `.set()` — crashes |
| `AttendanceSessionRepository` | `setSessionClosed()` | Direct Firestore `.update()` — crashes |
