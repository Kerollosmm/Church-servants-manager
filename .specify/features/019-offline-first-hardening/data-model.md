# Data Model: Offline-First Architecture Hardening

## Entities

### SyncEntry (Existing — No Changes)
- `id`: String (deterministic dedup key)
- `actionType`: String (e.g., `MARK_ATTENDANCE`, `UPDATE_STUDENT`)
- `payload`: Map<String, dynamic>
- `createdAt`: DateTime
- `retryCount`: int

### New Action Types (for SyncEntry.actionType)
| Action Type | Payload Keys | Target |
|------------|-------------|--------|
| `MARK_ATTENDANCE` | teamId, sessionId, studentId, markData | AttendanceMarkRepository |
| `UPDATE_STUDENT` | studentId, updatedData, updatedAt | IStudentRepository |
| `ARCHIVE_STUDENT` | docId, performedByUid, uid | IStudentRepository |
| `RESTORE_STUDENT` | docId, performedByUid, uid | IStudentRepository |
| `CREATE_SESSION` | id, teamId, ...sessionPayload | AttendanceSessionRepository |
| `CLOSE_SESSION` | teamId, sessionId, isClosed | AttendanceSessionRepository |
| `UPDATE_SERVANT` | docId, servantData, updatedAt | IServantRepository |
| `CREATE_SERVANT` | servantData | IServantRepository |
| `ARCHIVE_SERVANT` | docId | IServantRepository |
| `UPDATE_RESULT` | studentId, termId, ...resultData | IResultsRepository |

---

## Hive Boxes Inventory

### Existing Boxes
| Box Name | Type | Feature | Purpose |
|----------|------|---------|---------|
| `sync_queue_box` | `SyncEntry` | Core | Central sync queue |
| `students_box` | `StudentModel` | Student | Student cache |
| `students_sync_queue_box` | `StudentModel` | Student | Student mutation queue |
| `servants_box` | `ServantModel` | Servant | Servant cache |
| `servants_sync_queue_box` | `ServantModel` | Servant | Servant mutation queue |
| `attendance_marks_cache` | `String` (JSON) | Attendance | Mark cache |
| `attendance_marks_sync_queue` | `String` (JSON) | Attendance | Mark sync queue |

### New Boxes Needed
| Box Name | Type | Feature | Purpose |
|----------|------|---------|---------|
| `teams_cache_box` | `TeamModel` | Team | Team read cache |
| `attendance_sessions_cache_box` | `String` (JSON) | Attendance | Session read cache |
| `results_cache_box` | `String` (JSON) | Results | Results read cache |

---

## State Transitions

### SyncStatus per Record
```
pending → syncing → synced
pending → syncing → failed → (retry) → syncing → synced
pending → syncing → failed → (max retries) → dead_letter
```

### Connectivity State
```
online → offline → online (triggers queue drain)
app_foreground + online → immediate sync
app_background + online → workmanager periodic sync (15min)
app_killed + online → workmanager one-off sync (when network available)
```
