# Infrastructure Review

## Scope: DI, Sync Engine, Connectivity, Firestore Rules, Route Gating

---

### 1. Dependency Injection (`injection.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Module organization | Well-structured with feature-based modules | ✅ |
| Singleton registration | Proper use of `sl.registerSingleton` for services | ✅ |
| Factory registration | Factories used for BLoCs and repositories | ✅ |

### 2. Sync Engine (`sync_service.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Outbox pattern | Correctly implements offline-first outbox: local write → enqueue → process online → mark synced | ✅ |
| Retry logic | Exponential backoff with max 5 retries before DLQ | ✅ |
| Concurrency | Limit of 3 concurrent sync operations | ✅ |
| Batch processing | Processes sync queue entries in batches | ✅ |
| **CRITICAL: Dual sync queue** | `SyncService.enqueue()` writes `SyncEntry` with `actionType: MARK_ATTENDANCE` to `sync_queue_{userId}` AND `AttendanceLocalDatasource` writes `MarkSyncEntry` to `attendance_marks_sync_queue_v2`. Single mark mutation enqueues in BOTH queues, risking double Firestore writes. | 🔴 Critical |

### 3. Sync Handler (`sync_handler.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Abstract contract | Clean abstract base class for feature-specific handlers | ✅ |
| Handler registration | Properly registered in DI | ✅ |

### 4. Dead Letter Queue (`dead_letter_queue.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Persistence | Persistent DLQ with Hive storage | ✅ |
| Capacity cap | 100-entry maximum | ✅ |
| TTL | 30-day TTL with FIFO eviction | ✅ |

### 5. Connectivity (`connectivity_cubit.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **Missing reachability check** | Only monitors `connectivity_plus` for network state. WiFi-without-internet is reported as online, causing silent sync failures. | 🟠 Important |
| State emission | Proper `ConnectivityOnline` / `ConnectivityOffline` states | ✅ |
| Stream subscription | Properly disposed on cubit close | ✅ |

### 6. Sync Cubit (`sync_cubit.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| DLQ warning | `SyncDlqWarning` emitted when entries hit DLQ | ✅ |
| Reset behavior | Resets to `SyncIdle` after 5 seconds | ✅ |
| State coverage | Covers syncing, idle, error, DLQ warning states | ✅ |

### 7. Firestore Rules (`firestore.rules`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| RBAC enforcement | Document-based RBAC with `getCallerData()` helper | ✅ |
| `isActive` check | Enforced for servants (inactive servants cannot read/write) | ✅ |
| Team-based access | Per-team doc patterns for access control | ✅ |
| **Missing student `isActive`** | Student rules do NOT check `isActive`, unlike servant rules | 🟡 Minor |
| Zero Cloud Functions | Rules-only security model (Spark plan compliant) | ✅ |

### 8. Route Gating (`role_user_route.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Role-split routing | Correctly splits routing by role (servant/admin vs student) | ✅ |
| **`sl.reset()` risk** | Calls `sl.reset()` on role change, which deregisters ALL singletons. If re-registration order matters or any singleton is missed, runtime failures occur. | 🟡 Minor |

---

## Recommendations

1. **🔴 Critical**: Eliminate dual sync queue — consolidate to single `SyncService` outbox. Remove `attendance_marks_sync_queue_v2` path and route all mark syncs through `SyncEntry`.
2. **🟠 Important**: Add reachability check (HTTP ping to Firebase or known endpoint) before declaring online.
3. **🟡 Minor**: Add student `isActive` check to Firestore rules for consistency.
4. **🟡 Minor**: Replace `sl.reset()` with targeted unregister/re-register of only role-specific modules.
