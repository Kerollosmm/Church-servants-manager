# Research: CSMS Implementation Decisions

## R-01: AttendanceRepository Refactoring Strategy

**Decision:** Split into 3 components: `AttendanceSessionRepository`, `AttendanceMarkRepository`, `AttendanceSessionService`.
**Rationale:** Current file is 1002 lines violating P02 (SRP). Session CRUD, mark CRUD, and history queries are independent responsibilities. The service handles cross-repo orchestration (e.g., creating session with roster snapshot requires reading students then writing session).
**Alternatives Considered:**
- Keep as-is, just add tests → Rejected: file will grow with new features, making maintenance harder.
- Split into 2 (session + marks) → Too coarse. Session lifecycle orchestration is distinct from session CRUD.

## R-02: Offline/Degraded Mode Architecture

**Decision:** Track `lastAuthValidatedAt` timestamp in `AuthService`. `AuthFreshnessPolicy` computes `canPerformWrites` from the 15-minute window.
**Rationale:** Firestore SDK handles offline caching and sync transparently. The app only needs to track auth freshness to decide whether to allow queued writes. No additional connectivity library needed beyond `connectivity_plus` for offline detection.
**Alternatives Considered:**
- Use `connectivity_plus` + periodic reauth → Rejected: reauth is expensive and Firestore SDK already handles connection state.
- Disable writes immediately on any offline signal → Rejected: too aggressive for momentary Wi-Fi drops at church.

## R-03: Student Provisioning Flow

**Decision:** New Cloud Function `createStudentUser` that creates Auth user + Users doc + Students doc atomically.
**Rationale:** Per clarification Q4, no self-registration. All accounts are admin-provisioned. The Cloud Function uses Admin SDK to bypass Firestore rules and create all three artifacts in one call.
**Alternatives Considered:**
- Client-side creation with Firestore transaction → Rejected: cannot create Auth users from client.
- Create Auth user from client, then Students doc → Rejected: violates P05 (server-authoritative mutations).

## R-04: Transaction vs Batch for Team Assignment

**Decision:** Firestore `runTransaction()` for all servant-to-team assignments.
**Rationale:** Assignment requires reading current state (old servant) before writing. Batch writes don't support reads. Transaction ensures read-then-write atomicity with automatic retry on contention.
**Alternatives Considered:**
- Batched write with pre-fetch → Rejected: race window between fetch and batch commit.
- Cloud Function for assignment → Overkill: no Admin SDK needed, just Firestore writes.

## R-05: Denormalized Field Update Strategy

**Decision:** Eager update on source change for live references (`assignedServantName`, `team_name` on Students). Immutable for session snapshots (`studentNameSnapshots`, `teamNameSnapshot`, `createdByName`).
**Rationale:** Eager updates prevent stale displays in admin views. Session snapshots are historical records that must not change (attendance report for 2026-03-15 should show the names as they were on that date).
**Alternatives Considered:**
- Lazy (query-time join) for all → Rejected: expensive read-time joins for lists.
- All immutable → Rejected: admin sees stale servant name on team list until reassignment.
