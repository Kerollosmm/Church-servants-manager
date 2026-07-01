# Critical Findings Summary

## 🔴 Critical Issues (Must Fix Before Merge)

| # | Issue | File(s) | Impact |
|---|-------|---------|--------|
| 1 | **Dual sync queue for attendance marks** — `AttendanceLocalDatasource` writes to `attendance_marks_sync_queue_v2` AND `SyncService.enqueue()` writes `SyncEntry` to `sync_queue_{userId}`. Both process independently → double Firestore writes per mark. | `attendance_local_datasource.dart`, `attendance_mark_repository.dart`, `sync_service.dart` | Data corruption, double writes, Firestore write quota exhaustion |
| 2 | **Sync handler bypasses local cache update** — `AttendanceSyncHandler.execute()` writes directly to Firestore but does not update local Hive cache. Post-sync state mismatch. | `attendance_sync_handler.dart` | Stale local data after sync |
| 3 | **Missing syncStatus on StudentModel** — `StudentModel` has no `syncStatus` field. No client-side awareness of student sync state. | `student_model.dart`, `student_data_repository.dart` | Inconsistent offline UX, no sync feedback |
| 4 | **Session creation has no offline-first write** — `createSession()` writes directly to Firestore with no local cache write and no sync entry. Sessions created offline are silently lost. | `attendance_session_repository.dart`, `attendance_session_create_screen.dart` | Data loss |

## 🟠 Important Issues (Should Fix)

| # | Issue | File(s) | Impact |
|---|-------|---------|--------|
| 1 | **No reachability check in ConnectivityCubit** — WiFi-without-internet reported as online → sync fails silently. | `connectivity_cubit.dart` | Silent sync failures |
| 2 | **Wrong auth stream** — `.idTokenChanges()` causes unnecessary 60-min profile re-fetches vs `.authStateChanges()`. | `firebase_auth_repository.dart` | Wasted Firestore reads |
| 3 | **No offline caching for Team/TeamMembers BLoCs** — Direct Firestore reads only. | `team_repository.dart`, `team_bloc.dart`, `team_members_bloc.dart` | Teams unavailable offline |
| 4 | **No offline caching for AdminDashboard BLoC** — All data from Firestore each load. | `admin_dashboard_bloc.dart` | Dashboard blank offline |
| 5 | **Results edits never sync** — Local Hive writes but no SyncEntry creation. | `results_repository.dart` | Data loss on offline edits |
| 6 | **Double `isActive` check** — `checkStatus()` reads Firestore on every app launch. | `admin_user_provisioning_service.dart` | Wasted reads |
| 7 | **No Transaction in WriteBatch** — Partial batch failure has no rollback. | `attendance_sync_handler.dart` | Partial data loss risk |

## 🟡 Minor Issues (Nice to Fix)

| # | Issue | Severity |
|---|-------|----------|
| 1 | Missing student `isActive` check in Firestore rules | Minor |
| 2 | `sl.reset()` deregisters all singletons on role change | Minor |
| 3 | Missing explicit offline states in multiple BLoCs | Minor |
| 4 | Missing screen-level offline banner on AttendanceTakingScreen | Minor |
| 5 | Race condition in admin user provisioning (no transaction) | Minor |
| 6 | `FirestoreCollections` constant usage inconsistency (some repos hardcode strings) | Minor |

---

## Merge Readiness Decision

| Criteria | Status |
|----------|--------|
| 🔴 Critical issues | **4 open** — NOT merge-ready |
| 🟠 Important issues | **7 open** |
| 🟡 Minor issues | **6 open** |
| Testing coverage | Not yet reviewed |
| Overall | **DO NOT MERGE** until critical issues resolved |

---

## Priority Action Plan

1. **Fix dual sync queue** — Remove `attendance_marks_sync_queue_v2` path, route all marks through single `SyncService` outbox.
2. **Fix sync handler cache update** — Update local Hive cache after successful Firestore write in `AttendanceSyncHandler`.
3. **Add syncStatus to StudentModel** — Add field, update repository and sync handler.
4. **Make session creation offline-first** — Add local cache write + sync entry to `createSession()`.
5. **Address important issues** — Reachability check, team/dashboard caching, results sync.
6. **Review test coverage** — Before final merge decision.
