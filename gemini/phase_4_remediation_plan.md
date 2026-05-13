# Phase 4 Remediation Plan: Spark Plan & Offline-First Compliance

This plan addresses critical architectural, security, and quota-related flaws identified during the Phase 4 audit of the Church Systems Management System (CSMS).

## 1. Epic: Offline-First Synchronization & Quota Protection
**Goal:** Ensure the offline sync engine operates deterministically, Firebase Spark Plan quotas are strictly protected (no rule-side or massive iterative reads), and RBAC is securely enforced via Custom Claims.
**Definition of Done:**
- `SyncService` processes background queues successfully on network restoration.
- `firestore.rules` performs ZERO document reads for authorization.
- `TeamAttendanceStats` uses a Server-Side Aggregation Document, costing exactly 1 read per query.
- Administrative scripts update the correct collections.

---

## 2. User Stories
1. **As an Admin/Servant**, I want my offline actions (like creating sessions and taking attendance) to automatically sync when I reconnect to the internet, so I don't lose data.
2. **As the System Architect**, I want security rules to rely solely on JWT Custom Claims so that role enforcement consumes zero Firestore reads, protecting our free tier quota.
3. **As an Admin**, I want the team attendance statistics to load instantly using a single Aggregation Document read, keeping the app fast and within Firebase read limits.

---

## 3. Tasks & Subtasks

| Task | Description | Dependencies | Est (hrs) | Priority | Owner |
|---|---|---|---|---|---|
| **T1: Enable Sync Engine** | Initialize `SyncService` in `main.dart` and implement missing `CREATE_SESSION` routing. | None | 1.0 | **P0** | Backend/Flutter |
| **T2: RBAC Custom Claims** | Refactor `firestore.rules` to eliminate `get()` calls and fix `set_custom_claims.js`. | None | 1.5 | **P0** | Backend/DevOps |
| **T3: Auth Token Refresh** | Implement `forceRoleRefresh` in `FirebaseAuthRepository` to trigger token refresh. | T2 | 0.5 | **P1** | Flutter |
| **T4: Results LWW Sync** | Implement Last-Write-Wins conflict resolution in `ResultsRepository.syncOfflineUpdate`. | None | 1.0 | **P1** | Backend/Flutter |
| **T5: Server-Side Aggregation**| Redesign `getTeamAttendanceStats` to read a single stats document updated during `closeSession`. | None | 2.5 | **P0** | Backend/Flutter |

### Subtasks:

#### T1: Enable Sync Engine
- [ ] Add `await getIt<SyncService>().init();` in `lib/main.dart` inside the `runZonedGuarded` block before `runApp`.
- [ ] In `lib/core/services/sync_service.dart`, map the `'CREATE_SESSION'` action to `getIt<AttendanceSessionRepository>().syncOfflineSessionCreation(entry.payload);`.

#### T2: RBAC Custom Claims
- [ ] Update `tools/set_custom_claims.js` to read from the `servants` collection instead of `Users`.
- [ ] Modify `firestore.rules` `isAdmin()` to use `request.auth.token.role == 'admin'`.
- [ ] Modify `firestore.rules` `isServant()` to use `request.auth.token.role == 'servant'`.
- [ ] Modify `firestore.rules` `servantCanManageTeam()` to check `classId in request.auth.token.get('assignedTeamIds', [])`.
- [ ] Add `audit_logs` block to `firestore.rules` allowing read for Admins and write for none (system only).

#### T3: Auth Token Refresh
- [ ] Update `lib/features/auth/data/repos/firebase_auth_repository.dart`.
- [ ] Implement `forceRoleRefresh` to call `await _identityProvider.forceTokenRefresh();` and reload the user.

#### T4: Results LWW Sync
- [ ] Update `lib/features/results/data/repos/results_repository.dart`.
- [ ] In `syncOfflineUpdate`, wrap the write in a transaction.
- [ ] Fetch the existing document and compare `updatedAt` with the payload's `updatedAt` before applying changes.

#### T5: Server-Side Aggregation
- [ ] Refactor `TeamAttendanceStats` logic in `AttendanceQueryService` to fetch from `Classes/{classId}/stats/attendance`.
- [ ] Modify `closeSession` in `AttendanceCommandService` to update the `Classes/{classId}/stats/attendance` document incrementally with the session's present/late/absent counts.

---

## 4. Sprint Mapping
**Sprint:** Phase 4 Remediation Sprint
**Goal:** Seal all quota leaks and activate the offline sync engine.
**Assigned Tasks:** T1, T2, T3, T4, T5.