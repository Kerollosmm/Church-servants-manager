# Repositories Review

## Scope: Attendance, Student, Pastoral, Servant, Team, Results Repositories

---

### 1. Attendance Repository (`attendance_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Session delegation | Correctly delegates mark writes to `AttendanceMarkRepository` | ✅ |
| Read caching | Uses local datasource for cached reads | ✅ |
| Error handling | Catches and wraps Firestore exceptions | ✅ |

### 2. Attendance Mark Repository (`attendance_mark_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **Dual sync queue (CRITICAL)** | Writes `MarkSyncEntry` to `attendance_marks_sync_queue_v2` AND enqueues `SyncEntry` via `SyncService`. Both queues process independently → double Firestore writes. | 🔴 Critical |
| **Sync handler bypass** | `AttendanceSyncHandler.execute()` writes directly to Firestore without updating local Hive cache. If sync succeeds but local cache update fails, state is inconsistent. | 🔴 Critical |
| Offline-first write | Local Hive write happens first before sync enqueue | ✅ |
| WriteBatch usage | Uses `WriteBatch` in sync handler for batch operations | ✅ |
| **No Transaction** | `WriteBatch` without `Transaction` — partial batch failure has no rollback mechanism for already-applied local deletions | 🟠 Important |

### 3. Attendance Session Repository (`attendance_session_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **No offline-first write** | `createSession()` writes directly to Firestore with NO local cache write and NO sync queue entry. Session creation while offline is silently lost. | 🔴 Critical |
| Read caching | Reads sessions from local datasource | ✅ |
| Error handling | Basic error propagation | ✅ |

### 4. Student Data Repository (`student_data_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **Missing syncStatus** | Does NOT set `syncStatus` on `StudentModel` before sync, unlike other repositories which annotate with `SyncStatus.pending/synced`. No client-side awareness of student sync state. | 🔴 Critical |
| Offline-first write | Local Hive write then sync entry enqueue | ✅ |
| Sync entry creation | Creates `SyncEntry` for student mutations | ✅ |

### 5. Pastoral Repository (`pastoral_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Offline-first write | Local write before sync enqueue | ✅ |
| Read caching | Uses local datasource | ✅ |
| Error handling | Adequate | ✅ |

### 6. Servant Data Repository (`servant_data_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Offline-first write | Local write before sync enqueue | ✅ |
| Read caching | Local datasource with cache-first strategy | ✅ |
| Error handling | Adequate | ✅ |

### 7. Team Repository (`team_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **No offline support** | All reads hit Firestore directly — no local Hive caching. Loading teams while offline yields error state. | 🟠 Important |
| Write pattern | Writes directly to Firestore, no sync entry | 🟠 Important |
| Error handling | Basic | ✅ |

### 8. Results Repository (`results_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **No sync entry creation** | Writes to local Hive but never enqueues a `SyncEntry`. Results edits made offline are silently lost on app restart. | 🟠 Important |
| Read caching | Local Hive reads work | ✅ |
| Write pattern | Local-first write, but no queue for Firestore sync | 🟠 Important |

---

## Recommendations

1. **🔴 Critical**: Eliminate dual sync queue — consolidate mark sync into single `SyncService` outbox.
2. **🔴 Critical**: Add `syncStatus` to `StudentModel` for consistent offline awareness.
3. **🔴 Critical**: Make `createSession()` offline-first (local write + sync entry enqueue).
4. **🟠 Important**: Add local Hive caching to `TeamRepository`.
5. **🟠 Important**: Add `SyncEntry` creation to `ResultsRepository` for offline edits.
6. **🟠 Important**: Replace `WriteBatch` with `Transaction` in sync handler for atomicity.
