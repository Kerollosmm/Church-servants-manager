# Feature Specification: Pre-Deploy Security & Stability Fixes

**Feature Branch**: `004-security-stability-fixes`
**Created**: 2026-03-22
**Status**: Draft
**Input**: Pre-deployment code audit findings (pre_deploy_audit.md), covering 12 issues
across security, performance, stability, and hygiene.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Admin cannot be impersonated by role tampering (Priority: P1)

An admin performs sensitive operations (create attendance session, archive a student).
The system MUST enforce permissions on the server, not just the client, so that a
tampered or replayed request from a non-admin is rejected by Firestore itself.

**Why this priority**: Without server-side rules, any authenticated user can write
arbitrary data to Firestore, bypassing all role checks.

**Independent Test**: Can be fully tested by deploying `firestore.rules` to the Firebase
emulator and attempting unauthorized writes as a servant/student role — writes MUST be
rejected with `permission-denied`.

**Acceptance Scenarios**:

1. **Given** a servant user, **When** they attempt to write to `Classes/{id}/attendance_sessions`,
   **Then** Firestore returns `permission-denied` and the write is rejected.
2. **Given** an admin user, **When** they create an attendance session,
   **Then** the write succeeds normally.
3. **Given** a student user, **When** they attempt to mark another student present,
   **Then** the write is rejected by Firestore.

---

### User Story 2 — Archive/restore operations record who performed them (Priority: P1)

When an admin archives or restores a student, the Firestore document MUST record the
`uid` of the performing admin, not the hardcoded string `'system'`.

**Why this priority**: Without actor identity, compliance audits and abuse investigations
are impossible in production.

**Independent Test**: Archive a student as admin "X"; verify `archivedByUserId` in
Firestore equals X's uid.

**Acceptance Scenarios**:

1. **Given** admin A archives student S, **When** the Firestore document is read,
   **Then** `archivedByUserId` equals A's uid and `archivedAt` is a server timestamp.
2. **Given** admin B restores student S, **When** the Firestore document is read,
   **Then** `restoredByUserId` equals B's uid.

---

### User Story 3 — Logout is safe to call multiple times (Priority: P2)

Calling logout when no user is signed in MUST be a no-op and MUST NOT throw an exception.

**Why this priority**: Race conditions between auth state changes and BLoC event processing
can trigger double-logout, causing unhandled exceptions in production.

**Independent Test**: Call `logOut()` twice in succession; second call completes without
error.

**Acceptance Scenarios**:

1. **Given** no user is signed in, **When** `logOut()` is called,
   **Then** the call completes silently without throwing.
2. **Given** user is signed in, **When** `logOut()` is called,
   **Then** the user is signed out and cache is cleared normally.

---

### User Story 4 — Active session lookup does not download full session history (Priority: P2)

When a dashboard checks for the currently active attendance session, it MUST query
only open (non-closed) sessions from Firestore, not the entire history.

**Why this priority**: Over time, accumulating sessions will degrade performance for all
dashboard users.

**Independent Test**: Monitor Firestore reads from `watchActiveSessionForTeam` — only
documents where `isClosed == false` MUST be returned in the snapshot.

**Acceptance Scenarios**:

1. **Given** a team with 100 historical sessions (99 closed, 1 open), **When**
   `watchActiveSessionForTeam` is called, **Then** Firestore returns only 1 document.
2. **Given** all sessions are closed, **When** `watchActiveSessionForTeam` is called,
   **Then** the stream emits `null`.

---

### User Story 5 — Attendance stats do not issue unbounded Firestore reads (Priority: P2)

Team and student attendance stats MUST NOT issue sequential reads per session.
Team stats MUST parallelize reads; student stats MUST cap sessions to a max window.

**Why this priority**: N+1 sequential reads cause timeout failures and Firestore
quota exhaustion with real data volumes.

**Acceptance Scenarios**:

1. **Given** a team with 50 sessions, **When** `getTeamAttendanceStats` is called,
   **Then** mark reads are issued concurrently (not sequentially), completing in under 5s.
2. **Given** a student with 300 sessions, **When** `getStudentAttendanceStats` is called,
   **Then** at most 180 sessions (6 months) are queried.

---

### User Story 6 — DevTools screen unreachable in release builds (Priority: P3)

The `/devtools` route MUST NOT exist in release (production) builds.

**Acceptance Scenarios**:

1. **Given** a release build, **When** the app tries to navigate to `/devtools`,
   **Then** the route is not matched and the app shows the 404/NotFound screen.
2. **Given** a debug build, **When** an admin navigates to `/devtools`,
   **Then** the DevTools screen is accessible.

---

### Edge Cases

- What if a servant's `assignedTeamIds` list is empty? → `canUserManageAttendance` MUST return `false`.
- What if `deleteStudent` is called for an already-archived student? → Operation MUST be idempotent.
- What if Firestore rules are deployed but the app cache has stale role data? → Write must fail at Firestore layer.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Firestore Security Rules MUST be authored and deployed that enforce:
  - Only admins can create/close attendance sessions.
  - Only admins or assigned servants can write attendance marks for their team.
  - Only admins can archive/restore students or servants.
  - All authenticated users can read their own user document.
- **FR-002**: `deleteStudent` and `restoreStudent` MUST accept a `performedBy` parameter
  (or `AuthUser`) and write it to the `archivedByUserId`/`restoredByUserId` Firestore fields.
- **FR-003**: `logOut()` in `FirebaseAuthProvider` MUST be idempotent — calling it when
  no user is signed in MUST succeed silently.
- **FR-004**: `watchActiveSessionForTeam` MUST filter to `isClosed == false` at the
  Firestore query level, not in-memory.
- **FR-005**: `getTeamAttendanceStats` MUST parallelize all mark sub-collection reads
  using `Future.wait`.
- **FR-006**: `getStudentAttendanceStats` (and `_loadStudentSessions`) MUST apply a
  6-month ceiling on session queries by default.
- **FR-007**: The `devTools` route in `AppRouter` MUST be conditional on `kDebugMode`.

### Non-Functional Requirements

- **NFR-001**: All changes MUST be surgical — only the identified files are touched.
- **NFR-002**: `flutter analyze` MUST return zero issues after changes.
- **NFR-003**: No existing data schema changes — only code-level and rules-level changes.
- **NFR-004**: Firestore rules MUST be tested against the Firebase Local Emulator Suite
  before deployment.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `firestore.rules` file is present and covers all write paths identified in the audit.
- **SC-002**: Firestore rejects unauthorized writes in emulator tests (0 false-negatives).
- **SC-003**: `archivedByUserId` and `restoredByUserId` contain real user UIDs (not `'system'`) in all new operations.
- **SC-004**: `watchActiveSessionForTeam` Firestore reads drop from N (all sessions) to ≤ open sessions count.
- **SC-005**: `getTeamAttendanceStats` completes in under 5 seconds for a team with 50 sessions on device.
- **SC-006**: Calling `logOut()` twice in a row causes zero uncaught exceptions.
- **SC-007**: `flutter analyze` reports 0 issues on the patched codebase.
