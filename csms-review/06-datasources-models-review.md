# Datasources & Models Review

## Scope: Local Datasources and Data Models

---

### 1. Attendance Local Datasource (`attendance_local_datasource.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Local caching | Correctly caches attendance marks in Hive | ✅ |
| **Dual sync queue path** | Writes `MarkSyncEntry` to `attendance_marks_sync_queue_v2` — this is the SECOND queue alongside `SyncService.sync_queue_{userId}` | 🔴 Critical |
| Read strategy | Cache-first with refresh from Firestore | ✅ |
| Data pruning | Integrated with `HivePruningService` | ✅ |

### 2. Attendance Session Local Datasource (`attendance_session_local_datasource.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Session caching | Caches sessions in Hive | ✅ |
| Read strategy | Cache-first | ✅ |
| Write pattern | Local write only (sync via repository) | ✅ |

### 3. Student Local Datasource (`student_local_datasource.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Student caching | Caches students in Hive | ✅ |
| **Missing syncStatus field** | Student model does not track syncStatus in local cache | 🟠 Important |
| Read strategy | Cache-first | ✅ |

### 4. Servant Local Datasource (`servant_local_datasource.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Servant caching | Caches servants in Hive | ✅ |
| Sync status tracking | Tracks sync status properly | ✅ |
| Read strategy | Cache-first | ✅ |

### 5. Team Local Datasource (`team_local_datasource.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **No caching** | Team datasource does NOT cache data locally — all reads go to Firestore | 🟠 Important |
| Write pattern | Direct Firestore writes | 🟠 Important |

### 6. Results Local Datasource (`results_local_datasource.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Results caching | Caches results in Hive | ✅ |
| Write pattern | Local-first write but no sync queue enqueue | 🟠 Important |
| Read strategy | Cache-first | ✅ |

### 7. Data Models

| Model | Serialization | SyncStatus | Offline-ready | Issues |
|-------|--------------|------------|---------------|--------|
| `attendance_mark.dart` | ✅ Proper | ✅ | ✅ | None |
| `attendance_session.dart` | ✅ Proper | ✅ | ✅ | None |
| `student_model.dart` | ✅ Proper | 🔴 Missing | 🟡 Partial | **No syncStatus** |
| `servant_models.dart` | ✅ Proper | ✅ | ✅ | None |
| `team_model.dart` | ✅ Proper | 🟠 Missing | 🟡 Partial | No sync tracking |
| `sync_entry.dart` | ✅ Proper | ✅ | ✅ | Base sync model |
| `mark_sync_entry.dart` | ✅ Proper | ✅ | ✅ | SyncEntry subclass |
| `sync_payload.dart` | ✅ Proper | ✅ | ✅ | Payload model |

---

## Recommendations

1. **🔴 Critical**: Add `syncStatus` field to `StudentModel` and `team_model.dart`.
2. **🔴 Critical**: Eliminate `attendance_marks_sync_queue_v2` and consolidate to single queue path.
3. **🟠 Important**: Add local Hive caching to Team local datasource.
4. **🟠 Important**: Add sync queue entry creation in Results local datasource.
