# Feature Specification: CSMS Full System

**Feature:** Church Servant & Student Management System (CSMS)
**Short Name:** csms-full-system
**Created:** 2026-04-04
**Status:** Draft
**Author:** Spec-Kit Planning Lead

---

## Clarifications

### Session 2026-04-04

- Q: Should offline writes be queued or blocked? Offline (network down) vs degraded (auth stale) are different states — which write policy applies to each? → A: Queue writes ONLY when network is down but auth was recently valid (<15 minutes). Disable writes entirely when auth is stale (degraded mode). The 15-minute freshness window prevents stale-permission writes while preserving usability during momentary Wi-Fi drops.
- Q: When a mark is toggled off (second tap on same status), what happens to the mark document? → A: The mark document is DELETED from Firestore. The student reverts to "unmarked" (effectively absent if the session ends). This is consistent with BR-07 (absent = no mark document). No sentinel/null status value exists.
- Q: Servant-to-team assignment can touch up to 3 documents (new team, new servant, old servant). What happens on partial failure? → A: All assignment changes MUST use a Firestore transaction (read-then-write) covering all affected documents. If any write fails, the entire transaction rolls back. No partial state is ever persisted.
- Q: When a student self-registers, how is their Users doc linked to their existing Students record? → A: No self-registration for students. ALL user accounts (admin, servant, student) are created by admins via backend functions. The admin creates the Students record and the Users/Auth account together. The linking (Students.uid = Users.uid) is established at creation time. This eliminates the orphan-user problem entirely.
- Q: When a servant or team name changes, do denormalized copies update? → A: Eager update on source change. When a servant's name is edited, all teams referencing that servant update assignedServantName immediately (same operation or triggered function). When a team name changes, the team document updates but session-level snapshots (teamNameSnapshot, studentNameSnapshots, createdByName) remain IMMUTABLE — they are historical records.

---

## 1. Problem Statement

A Coptic Orthodox church needs to manage its Sunday school operations:
tracking which servants (teachers) are assigned to which teams (classes),
which students are enrolled in which teams, and recording weekly
attendance for each session. Today, this process is either manual
(paper-based) or scattered across spreadsheets and messaging apps,
leading to:

- **Lost attendance data** — no single source of truth for who attended.
- **No accountability** — servants cannot verify their own attendance
  records; admins cannot audit across teams.
- **Roster confusion** — students move between groups/grades, and the
  information is not consistently propagated.
- **No access control** — anyone with access to a spreadsheet can modify
  anyone's data.
- **No archive/restore** — when a student or servant leaves, their
  history is lost or left in an inconsistent state.

---

## 2. Business Goal

Provide a single, role-based mobile application that:

1. Gives **admins** full operational control over servants, students,
   teams, and attendance with audit trails.
2. Gives **servants** the ability to manage their assigned teams, take
   attendance, and view student details.
3. Gives **students** read-only access to their own profile and
   attendance history.
4. Ensures **data integrity** through enforced business rules that
   cannot be bypassed by any client.
5. Supports **offline-first** read access for unreliable church
   Wi-Fi environments.
6. Enables **audit and accountability** for all privileged operations.

---

## 3. User Value

| Actor    | Value Delivered                                                |
| -------- | ------------------------------------------------------------- |
| Admin    | Single dashboard to oversee all church school operations       |
| Admin    | Confidence that data is consistent and tamper-proof            |
| Admin    | Ability to archive/restore users without losing history        |
| Servant  | Quick, tap-based attendance taking during sessions             |
| Servant  | View of assigned team members and their attendance records     |
| Student  | Self-service access to own profile and attendance summary      |
| Church   | Permanent, auditable record of attendance across years         |

---

## 4. Actors and Roles

### 4.1 Admin

- Full read/write access to all data in the system.
- Can create, edit, archive, and restore servants and students.
- Can create, edit, archive, and restore teams.
- Can create, close, reopen, and delete attendance sessions for
  any team.
- Can assign/unassign servants to teams.
- Can view the aggregated dashboard with live counts and activity.
- Admin screens are protected by both route guards and server-side
  rules.

### 4.2 Servant

- Can view students assigned to their team(s).
- Can create attendance sessions for their assigned team(s) only.
- Can mark students present or late in sessions they manage.
- Can view attendance history for their team(s).
- Cannot create or modify teams, other servants, or admin settings.
- Cannot access other teams' data unless explicitly assigned.

### 4.3 Student

- Read-only access to their own profile.
- Read-only access to their own attendance history.
- Cannot view other students' data.
- Cannot modify any data.

### 4.4 System (Backend)

- Executes privileged operations: user creation, custom claims,
  audit logging, materialized view updates.
- Enforces data access rules independently of the client.

---

## 5. Scope

### 5.1 In Scope

| ID     | Area                      | Description                                              |
| ------ | ------------------------- | -------------------------------------------------------- |
| S-01   | Authentication            | Email/password login, forgot password (no self-register) |
| S-02   | Email verification        | Mandatory before entering the app                        |
| S-03   | Role-based routing        | Admin, servant, student see different home screens        |
| S-04   | User profile management   | Admins manage Users; students view own profile            |
| S-05   | Student CRUD              | Full lifecycle for student records                        |
| S-06   | Servant CRUD              | Full lifecycle for servant accounts                       |
| S-07   | Team management           | Create, edit, archive, restore teams                      |
| S-08   | Servant-to-team assignment| Assign/unassign servants with cascading updates           |
| S-09   | Student-to-team enrollment| Assign students to teams via classId                      |
| S-10   | Attendance sessions       | Create, view, close, reopen sessions                      |
| S-11   | Attendance marking        | Mark present/late; absent is implicit                     |
| S-12   | Attendance history        | Per-team and per-student historical views                 |
| S-13   | Admin dashboard           | Aggregated live metrics                                   |
| S-14   | Archive/restore lifecycle | Soft-delete with audit trail for users, students, teams   |
| S-15   | Degraded mode             | Read-only access with stale data when offline             |
| S-16   | Audit trail               | Backend-written logs for privileged operations            |
| S-17   | Forced password reset     | After account restoration                                 |

### 5.2 Out of Scope

| ID     | Area                      | Reason                                                    |
| ------ | ------------------------- | --------------------------------------------------------- |
| OS-01  | Push notifications        | Not required for MVP; can be added later                  |
| OS-02  | Multi-church/tenant       | Single church deployment only                             |
| OS-03  | Reporting/PDF export      | Future improvement; not blocking                          |
| OS-04  | Image/photo upload        | Profile photos are URL-based only, no upload flow         |
| OS-05  | Messaging/chat            | Out of app scope                                          |
| OS-06  | Web admin portal          | Mobile-only for current scope                             |
| OS-07  | Attendance streaks/badges | Gamification is future scope                              |
| OS-08  | SSO/OAuth                 | Email/password only                                       |
| OS-09  | Multi-language i18n       | Arabic-only for MVP                                       |

---

## 6. User Stories

### US-01: Admin — Sign In

**As an** admin, **I want to** sign in with my email and password,
**so that** I can access the admin dashboard.

**Acceptance Criteria:**
- AC-01.1: Given valid credentials, the admin is routed to the admin
  dashboard within 3 seconds.
- AC-01.2: Given invalid credentials, an Arabic error message is shown
  without exposing internal details.
- AC-01.3: Given an unverified email, the admin is routed to the email
  verification screen, not the dashboard.
- AC-01.4: Given an archived account, the admin sees the archived
  account screen with a message explaining their account is disabled.

### US-02: Admin — Create Servant Account

**As an** admin, **I want to** create a new servant account with a
name, email, and group assignment, **so that** new servants can access
the system.

**Acceptance Criteria:**
- AC-02.1: The backend creates the Firebase Auth user, sets custom
  claims (role=servant), and writes the Users document atomically.
- AC-02.2: The new servant appears in the servant list within 5
  seconds of creation.
- AC-02.3: If the email already exists, an error is returned and no
  partial data is created.
- AC-02.4: The servant receives a password setup email.

### US-03: Admin — Manage Teams

**As an** admin, **I want to** create, edit, archive, and restore
teams, **so that** the church's class structure is always current.

**Acceptance Criteria:**
- AC-03.1: A new team requires a name and group assignment. Duplicate
  names within the same group are rejected.
- AC-03.2: Archiving a team sets isArchived=true and records audit
  fields (archivedAt, archivedByUserId, archiveReason).
- AC-03.3: Archived teams do not appear in active team lists by
  default but are viewable via an archive toggle.
- AC-03.4: Archived teams cannot have new attendance sessions created.
- AC-03.5: Restoring a team clears the archive flag and records
  restoredAt and restoredByUserId.
- AC-03.6: Restoring a team does NOT automatically restore archived
  students within that team.

### US-04: Admin — Assign Servant to Team

**As an** admin, **I want to** assign a servant to a team, **so that**
the servant can manage attendance for that team.

**Acceptance Criteria:**
- AC-04.1: Assigning a servant updates the team's assignedServantId
  and assignedServantName.
- AC-04.2: The servant's Users document assignedTeamIds array is
  updated to include the new team ID.
- AC-04.3: If the servant was previously assigned to a different team,
  the old team's assignment is cleared and the old team ID is removed
  from their assignedTeamIds.
- AC-04.4: Only active (non-archived) servants can be assigned.
- AC-04.5: Only active (non-archived) teams can receive assignments.

### US-05: Servant — Take Attendance

**As a** servant, **I want to** create a session for my team and mark
each student as present or late, **so that** attendance is recorded
accurately.

**Acceptance Criteria:**
- AC-05.1: The servant can only create sessions for teams in their
  assignedTeamIds.
- AC-05.2: Session creation captures a roster snapshot of all active,
  non-archived students in the team at that moment.
- AC-05.3: Students can be marked "present" or "late" with a single
  tap. A second tap on the same status DELETES the mark document,
  reverting the student to "unmarked" (absent if session ends).
  Tapping a different status (e.g., tapping "late" when already
  "present") updates the existing mark document's status field.
- AC-05.4: The attendance screen updates in real-time if another
  servant/admin modifies the same session concurrently.
- AC-05.5: Marking is only possible while the session is open (current
  time is between startsAt and endsAt, and isClosed is false).
- AC-05.6: After the session time window closes, unmarked students
  are effectively "absent" (no mark document exists).
- AC-05.7: A session cannot overlap with another session for the same
  team on the same date with overlapping time ranges.

### US-06: Servant — View Attendance History

**As a** servant, **I want to** view past sessions for my team with
per-student attendance records, **so that** I can track patterns.

**Acceptance Criteria:**
- AC-06.1: Sessions are listed in reverse chronological order.
- AC-06.2: Each session shows: date, title, count of present/late/
  absent.
- AC-06.3: Tapping a session shows the full roster with each
  student's mark (present, late, or absent).
- AC-06.4: The servant can only view sessions for their assigned
  team(s).

### US-07: Student — View Own Profile

**As a** student, **I want to** see my profile information,
**so that** I can verify my data is correct.

**Acceptance Criteria:**
- AC-07.1: The profile shows: name, mobile, parent contacts, grade,
  education stage, team name, and father of confession.
- AC-07.2: All fields are read-only. The student cannot edit.
- AC-07.3: If the student has no linked Users account, they cannot
  access the app (they only exist as a Students document managed by
  admins/servants).

### US-08: Student — View Own Attendance

**As a** student, **I want to** see my attendance record across all
sessions, **so that** I can know if I am meeting expectations.

**Acceptance Criteria:**
- AC-08.1: The student sees a list of sessions they were part of, with
  their status (present, late, absent) for each.
- AC-08.2: The student can only see their own attendance data.
- AC-08.3: Summary statistics (total sessions, % present, % late, %
  absent) are shown.

### US-09: Admin — Archive/Restore User

**As an** admin, **I want to** archive a servant or student account
when they leave, and restore it if they return, **so that** historical
data is preserved and access is controlled.

**Acceptance Criteria:**
- AC-09.1: Archiving sets isArchived=true on the Users document and
  disables the Firebase Auth user.
- AC-09.2: An archived user cannot sign in. Existing tokens are
  revoked.
- AC-09.3: Archiving records: archivedAt, archivedByUserId,
  archiveReason.
- AC-09.4: Restoring re-enables the Firebase Auth user, sets a random
  temporary password, and sends a password reset email.
- AC-09.5: The restored user is marked with
  restorePendingPasswordReset=true. The app forces them to complete
  password reset before accessing any data.
- AC-09.6: Restoring a servant does NOT restore previous team
  assignments. An admin must re-assign manually.
- AC-09.7: Historical attendance records remain readable after
  archive and after restore.

### US-10: Admin — View Dashboard

**As an** admin, **I want to** see an aggregated overview of active
students, servants, teams, and recent attendance activity,
**so that** I can monitor the health of church school operations.

**Acceptance Criteria:**
- AC-10.1: The dashboard shows: total active students, total active
  servants, total active teams, sessions this month, and recent
  attendance audit entries.
- AC-10.2: Counts update in real-time as data changes.
- AC-10.3: Pending restore accounts (restorePendingPasswordReset=true)
  are highlighted for admin follow-up.

### US-11: System — Degraded Mode

**As a** user with unreliable connectivity, **I want to** continue
viewing previously loaded data when offline, **so that** the app
does not become unusable during Sunday school.

**Acceptance Criteria:**
- AC-11.1: When offline, the app shows cached data with a visible
  "offline" or "degraded" indicator.
- AC-11.2: When network connectivity is lost but the user's auth
  session was validated within the last 15 minutes ("offline mode"),
  write operations (marking attendance, creating sessions) are queued
  locally and synced when connectivity resumes.
- AC-11.3: When the user's auth session cannot be validated and the
  last successful validation was >15 minutes ago ("degraded mode"),
  all write operations MUST be disabled. The user sees a warning
  banner and can only view cached data.
- AC-11.4: If a queued write fails server-side (e.g., session already
  closed), the user is notified of the failure after sync.
- AC-11.5: Neither offline mode nor degraded mode grants additional
  permissions beyond what the user had when last online.
- AC-11.6: When network is down AND last auth validation >15 minutes
  (combined offline + degraded condition), degraded mode takes precedence:
  all write operations MUST be disabled (no queuing), and the UI must
  show the degraded-mode warning banner. This overrides the offline-mode
  queuing behavior described in AC-11.2.

---

## 7. Functional Requirements

### FR-01: Authentication

- FR-01.1: The system MUST support email/password authentication.
- FR-01.2: There is NO public self-registration. All user accounts
  (admin, servant, student) are created by an admin via backend
  Cloud Functions. The backend function creates the Firebase Auth
  user, sets the appropriate custom claims (role), and writes the
  Users document. For students, the backend also creates or links
  the Students document in the same operation.
- FR-01.3: Email verification MUST be completed before the user can
  access any app functionality beyond the verification screen.
- FR-01.4: The system MUST support "forgot password" via email link.
- FR-01.5: The system MUST monitor the auth session and react to
  token revocation, sign-out, or permission changes within 15 seconds
  or on the next app foreground event.

### FR-02: Role Resolution

- FR-02.1: The user's effective role MUST be determined by merging:
  Firebase Auth user, Firestore Users profile, and ID token custom
  claims.
- FR-02.2: When custom claims and Firestore profile disagree on role,
  custom claims MUST take precedence.
- FR-02.3: An archived user (isArchived=true in claims or profile)
  MUST be treated as having no role and routed to the archived screen.
- FR-02.4: If the Firestore profile fetch fails but a cached user
  exists matching the current Firebase UID, the app MUST enter
  degraded mode instead of signing the user out.

### FR-03: Student Management

- FR-03.1: Admins and servants (for their own team's students) MUST
  be able to create, read, update, and archive student records.
- FR-03.2: Students MUST have: name, mobile, parent contacts (mother,
  father), grade, education stage, group, team assignment (classId),
  father of confession.
- FR-03.3: When a student record is updated and that student has a
  linked Users document (by uid), the system MUST synchronize the
  name and email fields to the Users document.
- FR-03.4: Archived students MUST be excluded from new attendance
  session rosters.
- FR-03.5: A student list MUST support search by name prefix and
  filtering by group and team.
- FR-03.6: Student lists MUST support lazy loading for churches with
  >100 students.

### FR-04: Servant Management

- FR-04.1: Only admins can create, edit, archive, and restore servant
  accounts.
- FR-04.2: Servant creation MUST go through a backend function that
  creates the Firebase Auth user, sets custom claims (role=servant),
  and writes the Users document.
- FR-04.3: A servant list MUST show: name, email, assigned team(s),
  and group.
- FR-04.4: Archiving a servant MUST: set isArchived=true, disable the
  Auth user, revoke refresh tokens, and remove the servant from all
  team assignments (clear assignedServantId on affected teams and
  clear assignedTeamIds on the servant).
- FR-04.5: Restoring a servant MUST: re-enable the Auth user, set a
  random temporary password, mark restorePendingPasswordReset=true,
  and send a password reset email. It MUST NOT restore previous team
  assignments.

### FR-05: Team Management

- FR-05.1: Only admins can create, edit, archive, and restore teams.
- FR-05.2: A team has: name, groupId, assignedServantId(s),
  assignedServantName, and archive fields.
- FR-05.3: Team names MUST be unique within a group.
- FR-05.4: Archiving a team MUST prevent new session creation for that
  team but MUST NOT delete or archive students in that team.
- FR-05.5: The team list MUST support an archive toggle to show/hide
  archived teams.

### FR-06: Servant-to-Team Assignment

- FR-06.1: An admin assigns a servant to a team by selecting from a
  list of active, non-archived servants.
- FR-06.2: Assignment MUST use a Firestore transaction that reads
  the current state of all affected documents and then writes all
  changes atomically. The transaction covers: (a) the team document
  (set assignedServantId and assignedServantName), (b) the new
  servant's Users document (add team ID to assignedTeamIds), and
  (c) the previous servant's Users document if one existed (remove
  team ID from assignedTeamIds). If any write fails, the entire
  transaction rolls back.
- FR-06.3: If the team already had a different servant assigned, the
  previous servant's assignedTeamIds MUST be updated to remove the
  old team within the SAME transaction.
- FR-06.4: An admin can unassign a servant from a team, clearing the
  assignment on both documents within a single transaction.
- FR-06.5: If a transaction fails due to contention (another admin
  modifying the same team concurrently), the operation MUST retry
  automatically up to 3 times before surfacing an error to the user.

### FR-07: Attendance Session Lifecycle

- FR-07.1: An admin or assigned servant can create a session for an
  active team.
- FR-07.2: Session creation MUST: (a) capture a roster snapshot of
  active students currently in the team, (b) generate a deterministic
  session ID from a canonicalized ISO 8601 datetime (including full year
  and timezone offset, e.g. YYYY-MM-DDTHH:MM:SS±HH:MM), a normalized
  title string (trimmed, lowercased, whitespace-collapsed), and a stable
  hash or separator to ensure global uniqueness and idempotency across
  annual recurrences, (c) validate no overlapping session exists for the
  same team.
- FR-07.3: A session is "open" when the current time is between
  startsAt and endsAt AND isClosed is false.
- FR-07.4: An admin can manually close a session by setting
  isClosed=true, regardless of the time window.
- FR-07.5: An admin can reopen a closed session for editing by setting
  isReopenedForAdminEdit=true. This records reopenedAt,
  reopenedByUserId, and reopenedByName.
- FR-07.6: A reopened session accepts mark modifications only from
  admins (not from the originally assigned servant).
- FR-07.7: A session requires: teamId, title, startsAt, durationMinutes
  (>0). Title is REQUIRED (used in deterministic session ID generation).
- FR-07.8: Duplicate sessions (same team, same date, same start time,
  same title) MUST be rejected idempotently.

### FR-08: Attendance Marking

- FR-08.1: Only admins and the servant assigned to the session's team
  can write marks.
- FR-08.2: A mark can only be written for a student who is in the
  session's studentIdsSnapshot.
- FR-08.3: A mark document records: status ("present" or "late"),
  markedByUserId, markedByName, markedAt (first mark time, preserved),
  updatedAt, and optional note.
- FR-08.4: "absent" is never written as a mark. It is derived: if no
  mark document exists for a student when the session has ended, the
  student is absent.
- FR-08.5: Marks can only be written when the session is writable:
  (a) the session is open (within time window and not closed), OR
  (b) the session is reopened for admin edit (and the actor is admin).
- FR-08.6: The attendance-taking screen MUST display the roster in
  real-time. Changes by concurrent actors MUST appear within 5
  seconds.
- FR-08.7: Removing a mark (toggle-off) MUST delete the mark document
  entirely. There is no "cleared" or null status. The only valid
  mark statuses are "present" and "late". The absence of a mark
  document means the student is unmarked (absent after session ends).

### FR-09: Attendance History Views

- FR-09.1: Per-team history: list of sessions for a team in reverse
  chronological order, showing date, title, present/late/absent
  counts.
- FR-09.2: Per-student history: list of sessions the student
  participated in, with their mark for each session.
- FR-09.3: Per-student summary statistics: total sessions, count and
  percentage of present/late/absent.
- FR-09.4: Servants can view history only for their assigned team(s).
- FR-09.5: Students can view only their own history.
- FR-09.6: Admins can view history for all teams.

### FR-13: Admin Takeover of Orphaned Sessions

- FR-13.1: When a servant is archived, all open sessions they created
  MUST be flagged with `originalServantArchived=true` to indicate they
  are orphaned and require admin attention.
- FR-13.2: Admins MUST be able to view and edit marks in flagged
  (orphaned) sessions, regardless of the original servant's permissions.
- FR-13.3: Ownership of orphaned sessions does NOT transfer
  automatically. An admin must explicitly claim or acknowledge the
  session before editing.
- FR-13.4: Orphaned sessions remain editable by admins. The UI MUST
  display a warning indicator showing the session is orphaned.
  In-progress marks are preserved and are NOT auto-committed or
  auto-closed when the servant is archived.

### FR-10: Admin Dashboard

- FR-10.1: The dashboard MUST show: count of active students, count of
  active servants, count of active teams, count of sessions this
  month, and recent audit activity.
- FR-10.2: All counts MUST update in real-time.
- FR-10.3: The dashboard MUST highlight accounts with
  restorePendingPasswordReset=true as requiring admin follow-up.

### FR-11: Archive/Restore Operations

- FR-11.1: All archive operations MUST record: archivedAt,
  archivedByUserId, archiveReason.
- FR-11.2: All restore operations MUST record: restoredAt,
  restoredByUserId.
- FR-11.3: Archiving a user MUST revoke existing tokens and disable
  the Auth account within the same backend operation.
- FR-11.4: Restoring a user MUST trigger a forced password reset flow
  before the user can access the app.
- FR-11.5: Historical data (attendance records, audit logs) MUST
  remain intact after archive and restore.

### FR-12: Privileged Backend Operations

- FR-12.1: User creation (servant provisioning) MUST be a callable
  Cloud Function.
- FR-12.2: Role changes MUST be a callable Cloud Function that
  updates both Firestore and custom claims.
- FR-12.3: Archive/restore MUST be callable Cloud Functions.
- FR-12.4: All callable functions MUST re-verify the caller's current
  role AND archive state from Firestore before executing.
- FR-12.5: Audit logs MUST be written by backend functions only.
  Client writes to audit collections MUST be denied.

---

## 8. Non-Functional Requirements

### NFR-01: Performance

- NFR-01.1: Screen-to-content time MUST be <3 seconds on a mid-range
  Android device (Snapdragon 600-series equivalent) on a 4G
  connection.
- NFR-01.2: Attendance marking (tap to confirmed visual update) MUST
  feel instant (<300ms perceived latency) via optimistic local
  updates.
- NFR-01.3: The app MUST handle churches with up to 500 students and
  50 servants without degradation.

### NFR-02: Offline Behavior

- NFR-02.1: Read-only data (student lists, attendance history, own
  profile) MUST be available from local cache when offline.
- NFR-02.2: Write operations MUST be queued locally and synced when
  connectivity resumes, but ONLY if the user's auth session was
  validated within the last 15 minutes. If auth is stale (>15 min
  since last validation), writes MUST be disabled until the auth
  session is successfully re-validated.
- NFR-02.3: The app MUST show a visible indicator when operating in
  degraded/offline mode.

### NFR-03: Security

- NFR-03.1: All data access MUST be enforced by server-side Firestore
  rules and Cloud Function authorization, independent of client code.
- NFR-03.2: Custom claims MUST be used for role enforcement in
  Firestore rules.
- NFR-03.3: Token revocation MUST be executed on archive to prevent
  stale-token access.

### NFR-04: Data Integrity

- NFR-04.1: No orphan references: if a student is deleted from a team,
  their classId MUST be cleared.
- NFR-04.2: Denormalized field update contract:
  (a) `assignedServantName` on `Classes/{teamId}` — EAGER UPDATE.
      When a servant's name is edited, all teams where that servant
      is assigned MUST update assignedServantName atomically within
      the same Firestore transaction or via a triggered Cloud Function.
      Failures are detected via function error logs/metrics and a DLQ;
      retries use exponential backoff; monitoring alerts fire on
      repeated failures; an automated reconciliation job scans Classes
      to repair stale denormalized fields. Stale fields after
      retry/reconciliation are acceptable temporary degradation with
      an SLA of 5 minutes for repair.
  (b) `team_name` on `Students/{studentId}` — EAGER UPDATE.
      When a team is renamed, all students with classId pointing to
      that team MUST have their team_name updated via the same
      transactional approach as (a).
  (c) `studentNameSnapshots` on attendance sessions — IMMUTABLE.
      These are historical records captured at session creation.
      They MUST NOT be updated when a student's name changes.
  (d) `teamNameSnapshot` on attendance sessions — IMMUTABLE.
      Historical record of team name at session creation time.
  (e) `createdByName`, `markedByName`, `reopenedByName` — IMMUTABLE.
      Historical records of who performed the action.
- NFR-04.3: Server timestamps MUST be used for all createdAt/updatedAt
  fields. Client-derived timestamps are forbidden.

### NFR-05: Usability

- NFR-05.1: The app MUST use Arabic as the primary language for all
  UI text and error messages.
- NFR-05.2: Error messages MUST be human-readable and actionable.
  No raw exception strings or error codes.
- NFR-05.3: Destructive operations (archive, close session) MUST
  require a confirmation dialog.

---

## 9. Business Rules

| ID     | Rule                                                                    | Enforcement Point        |
| ------ | ----------------------------------------------------------------------- | ------------------------ |
| BR-01  | A user's effective role is: custom claims > Firestore profile > default | Auth resolution logic    |
| BR-02  | Only admins can create servant accounts                                  | Backend function         |
| BR-03  | No self-registration; all accounts are admin-provisioned          | Backend function + rules |
| BR-04  | Archived users cannot sign in                                            | Firebase Auth disabled   |
| BR-05  | Archived teams cannot have new sessions                                  | Repository + rules       |
| BR-06  | Archived students are excluded from new session rosters                  | Session creation logic   |
| BR-07  | "Absent" is never written; it is derived from the absence of a mark     | Domain logic             |
| BR-08  | A session's roster is frozen at creation time                            | Session document         |
| BR-09  | Marks are only writable during an open session window                    | Repository + rules       |
| BR-10  | Restoring a servant does NOT restore team assignments                    | Backend function logic   |
| BR-11  | Restoring any user requires a forced password reset                      | Backend + client guard   |
| BR-12  | Servant name on team: eagerly updated on servant name change     | AdminTeamService         |
| BR-13  | Session snapshots (studentNames, teamName, createdBy): IMMUTABLE | Immutable by design      |
| BR-14  | Audit logs are backend-only; clients cannot write or delete them         | Firestore rules          |
| BR-15  | Session IDs are deterministic from date+time+title for idempotency      | Repository logic         |
| BR-16  | Student team_name: eagerly updated on team rename                | Team update logic        |

---

## 10. Invariants (Must Never Be Violated)

| ID     | Invariant                                                                       |
| ------ | ------------------------------------------------------------------------------- |
| INV-01 | A user document's role field MUST match the user's custom claims role           |
| INV-02 | A team's assignedServantId MUST correspond to a user whose assignedTeamIds     |
|        | includes that team's ID, or both must be null                                   |
| INV-03 | A student with classId=X MUST belong to team X's enrolled roster                |
| INV-04 | A mark document MUST only exist for a studentId present in the session's        |
|        | studentIdsSnapshot                                                              |
| INV-05 | createdAt and updatedAt fields MUST use server timestamps, never client time    |
| INV-06 | An archived user's Firebase Auth account MUST be disabled                       |
| INV-07 | Read-model collections (audit_logs, attendance_history, attendance_stats)       |
|        | MUST have zero client writes                                                    |
| INV-08 | Every attendance session for a team on a given date MUST have non-overlapping   |
|        | time ranges                                                                     |
| INV-09 | A user with restorePendingPasswordReset=true MUST NOT access any screens       |
|        | beyond the forced password reset flow                                           |

---

## 11. Permissions Matrix

| Operation                    | Admin | Servant (own team) | Servant (other team) | Student |
| ---------------------------- | ----- | ------------------ | -------------------- | ------- |
| View all students            | ✅     | ❌                  | ❌                    | ❌       |
| View own-team students       | ✅     | ✅                  | ❌                    | ❌       |
| View own profile             | ✅     | ✅                  | ✅                    | ✅       |
| Create student               | ✅     | ✅ (own team only)  | ❌                    | ❌       |
| Edit student                 | ✅     | ✅ (own team only)  | ❌                    | ❌       |
| Archive student              | ✅     | ✅ (own team only) ⚠️ | ❌                    | ❌       |
| Create servant               | ✅     | ❌                  | ❌                    | ❌       |
| Edit servant                 | ✅     | ❌                  | ❌                    | ❌       |
| Archive/restore servant      | ✅     | ❌                  | ❌                    | ❌       |
| Create team                  | ✅     | ❌                  | ❌                    | ❌       |
| Edit team                    | ✅     | ❌                  | ❌                    | ❌       |
| Archive/restore team         | ✅     | ❌                  | ❌                    | ❌       |
| Assign servant to team       | ✅     | ❌                  | ❌                    | ❌       |
| Create session               | ✅     | ✅ (own team only)  | ❌                    | ❌       |
| Mark attendance              | ✅     | ✅ (own team only)  | ❌                    | ❌       |
| Close session                | ✅     | ❌                  | ❌                    | ❌       |
| Reopen session               | ✅     | ❌                  | ❌                    | ❌       |
| View team attendance history | ✅     | ✅ (own team only)  | ❌                    | ❌       |
| View own attendance history  | ✅     | ✅                  | ✅                    | ✅       |
| View admin dashboard         | ✅     | ❌                  | ❌                    | ❌       |

---

## 12. Error Cases

| ID     | Trigger                                  | Expected Behavior                                               |
| ------ | ---------------------------------------- | --------------------------------------------------------------- |
| E-01   | Login with wrong password                | Arabic error: "البريد الإلكتروني أو كلمة المرور غير صحيحة"    |
| E-02   | Login with archived account              | Route to archived screen, not a generic error                    |
| E-03   | Create servant with existing email       | Error returned, no partial user created                          |
| E-04   | Create session overlapping existing one  | Error with message identifying the conflicting session           |
| E-05   | Mark attendance on closed session        | Error: session is closed; mark is rejected                       |
| E-06   | Mark student not in roster snapshot      | Error: student is not part of this session                       |
| E-07   | Servant tries to access other team       | Firestore rules reject; UI shows permission error                |
| E-08   | Network failure during write             | Write queued locally; synced on reconnect; failure shown if       |
|        |                                          | server rejects on sync                                           |
| E-09   | Token revoked mid-session                | AuthBloc detects; routes to login screen                         |
| E-10   | Assign archived servant to team          | Rejected; only active servants shown in selection                 |
| E-11   | Archive a team with active sessions      | Allowed; existing sessions remain readable but no new ones        |
| E-12   | Concurrent session creation (same team)  | Transaction detects conflict; second attempt receives error       |
| E-13   | Firestore profile fetch fails on login   | Degraded mode with cached user, visible warning                   |

---

## 13. Edge Cases

| ID     | Scenario                                             | Expected Behavior                                      |
| ------ | ---------------------------------------------------- | ------------------------------------------------------ |
| EC-01  | Team has zero students when session created           | Session creation ALLOWED with visible warning to the    |
|        |                                                      | creator; allowed only if start time is >24 hours in the |
|        |                                                      | future OR creator confirms admin override               |
| EC-02  | Student added to team after session created           | Student NOT in that session's roster (snapshot frozen)  |
| EC-03  | Student archived between session creation and marking | Mark still possible (student is in snapshot);           |
|        |                                                      | student excluded from future sessions only              |
| EC-04  | Servant archived while session open                   | Servant can no longer mark; admin must take over        |
| EC-05  | Admin demoted to servant while on admin screen        | Next auth check redirects to servant dashboard          |
| EC-06  | Two admins edit same student simultaneously           | Last write wins (Firestore default); both see live      |
|        |                                                      | updates via stream                                     |
| EC-07  | Very long student/servant name (>100 chars)           | UI truncates with ellipsis; full name in detail view    |
| EC-08  | Student has no linked Users document                  | Student exists only in Students collection; cannot log  |
|        |                                                      | in; managed by admin/servant only                       |
| EC-09  | Session duration set to 0 or negative                 | Rejected; durationMinutes MUST be >0                    |
| EC-10  | App opened after months offline                       | Auth re-check on next connection; cached data shown;    |
|        |                                                      | permissions re-validated before mutations allowed       |
| EC-11  | Arabic text in names with mixed LTR/RTL               | Layout handles bidi text without breaking               |
| EC-12  | Restore user — password reset email fails             | User marked with restorePendingPasswordReset;           |
|        |                                                      | admin notified; user cannot access app until resolved   |

---

## 14. Offline and Cache Expectations

| Scenario                          | Read Behavior              | Write Behavior                          |
| --------------------------------- | -------------------------- | --------------------------------------- |
| Offline, auth fresh (<15 min)     | Cache served for all reads | Writes queued, synced on reconnect      |
| Offline, auth stale (>15 min)     | Cache served, warning shown| Writes DISABLED until auth re-validated |
| Degraded (Firestore profile fail) | Cache served, warning shown| Writes DISABLED                         |
| Intermittent connection           | Streams auto-reconnect     | Writes may queue temporarily            |
| After app restart (online)        | Cache then server data     | Writes allowed after auth check         |
| After app restart (offline)       | Cache re-hydrated          | Subject to 15-min freshness rule        |

- Cache MUST NOT grant access to data the user was never authorized
  to see. Cache only persists data that was previously fetched with
  valid permissions.
- After sign-out, local cache SHOULD be cleared to prevent data
  leakage on shared devices. (This is a SHOULD because Firestore SDK
  does not support selective cache clearing per user — full
  clearPersistence on sign-out is the recommended approach.)

---

## 15. Observability Expectations

- All privileged backend operations (user create, archive, restore,
  role change) MUST produce an audit log entry in the `audit_logs`
  collection, written by Cloud Functions only.
- Attendance session lifecycle events (create, close, reopen) SHOULD
  produce audit events in the session's `audit_events` subcollection.
- Client-side errors MUST be caught by global error handlers and
  logged (at minimum debugPrint in development; future: Crashlytics
  integration).
- Backend function errors MUST be logged with the caller UID,
  function name, and error type.

---

## 16. Key Entities

| Entity              | Storage                                          | Owner        |
| ------------------- | ------------------------------------------------ | ------------ |
| User Profile        | `Users/{uid}`                                    | Auth module  |
| Student Record      | `Students/{studentId}`                           | Student mod. |
| Team/Class          | `Classes/{teamId}`                               | Team module  |
| Attendance Session  | `Classes/{teamId}/attendance_sessions/{sessionId}`| Attendance   |
| Attendance Mark     | `.../marks/{studentId}`                          | Attendance   |
| Audit Log           | `audit_logs/{logId}`                             | Backend only |
| Audit Event         | `.../audit_events/{eventId}`                     | Backend only |
| Attendance History  | `attendance_history/{studentId}/sessions/{sid}`   | Backend only |
| Attendance Stats    | `attendance_stats/{studentId}`                   | Backend only |

---

## 17. Assumptions

| ID     | Assumption                                                       |
| ------ | ---------------------------------------------------------------- |
| A-01   | The church has a single admin who provisions ALL accounts         |
|        | (servants AND students) via backend functions. There is no       |
|        | public self-registration. The initial admin is seeded manually.  |
| A-02   | Groups are fixed categories (year1, year2, year3) and do not     |
|        | need to be dynamically managed.                                  |
| A-03   | A servant can be assigned to multiple teams (multi-team support   |
|        | via assignedTeamIds array).                                      |
| A-04   | Attendance sessions have a fixed duration set at creation time.  |
|        | There is no "extend session" operation.                          |
| A-05   | The "late" threshold is not time-based (e.g., "10 min after      |
|        | start"); it is a manual classification by the servant who marks  |
|        | the student as "late" vs "present" at their discretion.          |
| A-06   | The app is Arabic-first. All UI strings, validation messages,    |
|        | and error messages are in Arabic.                                |
| A-07   | Firebase Firestore offline persistence is enabled with          |
|        | cacheSizeBytes=100MB.                                           |
| A-08   | The app targets Android primarily, with iOS as secondary. Web    |
|        | and desktop are not production targets for MVP.                  |
| A-09   | Student-to-user linking is ALWAYS established at creation time   |
|        | by the admin. The backend function creates both the Students     |
|        | doc and the Users/Auth account together. A student CAN exist     |
|        | without a linked Users account (admin-managed only, no app       |
|        | login), but a student CANNOT self-create a Users account.        |
| A-10   | The Firestore collection named "Classes" is the canonical        |
|        | storage for teams. The legacy name is kept for backward          |
|        | compatibility.                                                   |

---

## 18. Open Questions

| ID     | Question                                                         | Impact    |
| ------ | ---------------------------------------------------------------- | --------- |
| OQ-01  | Should the system support attendance "seasons" (e.g., Fall 2026, | Scope     |
|        | Spring 2027) to group sessions and generate seasonal reports?    |           |
|        | Current design has no season concept. If yes, this requires a    |           |
|        | new entity and affects session queries, history views, and stats.|           |
| OQ-02  | **RESOLVED**: Servants CAN archive students in their own team.    | Authz     |
|        | The permissions matrix has been updated to reflect this.          |           |
| OQ-03  | What should happen to a servant's in-progress session if the     | Edge case |
|        | servant's account is archived mid-session? Should the session    |           |
|        | auto-close, remain open for admin, or error out?                 |           |

---

## 19. Blockers / Prerequisites

The following items MUST be fixed before any feature work begins. They are blocking prerequisites with no acceptable workarounds.

| ID     | Blocker                                                          | Severity  | Acceptance Criteria |
| ------ | ---------------------------------------------------------------- | --------- | ------------------- |
| D-01   | `firestore.rules` MUST be wired into `firebase.json` for         | HIGH      | SC-09: All firestore.rules are deployed and enforced before any servant/student provisioning occurs. |
|        | deployment. Currently missing (SEC-01).                          | (MUST FIX)| |
| D-02   | Backend callable functions (`functions/src/index.ts`) MUST       | HIGH      | SC-10: All backend callable functions re-validate caller state against Firestore on every call (not rely solely on token claims). |
|        | re-validate caller state from Firestore, not just token claims   | (MUST FIX)| |
|        | (SEC-02).                                                        |           | |

---

## 20. Dependencies on Existing Code / Data / Migrations

| ID     | Dependency                                                       | Risk      |
| ------ | ---------------------------------------------------------------- | --------- |
| D-01   | **RESOLVED**: See Blockers section (Section 19). Wired into      | HIGH      |
|        | `firebase.json` and deployed.                                    | (RESOLVED)|
| D-02   | **RESOLVED**: See Blockers section (Section 19). requireAdmin()  | HIGH      |
|        | now reads Firestore Users doc and checks isArchived.             | (RESOLVED)|
| D-03   | `injectable` package is declared but unused. Should be removed   | LOW       |
|        | to avoid confusion.                                              |           |
| D-04   | `hive`/`hive_flutter` declared but unused. Should be removed or  | LOW       |
|        | implemented for local caching.                                   |           |
| D-05   | `attendace_recourd/` directory (stale typo) should be deleted.   | LOW       |
| D-06   | The existing `AttendanceRepository` is 1002 lines. Any changes   | MEDIUM    |
|        | to attendance logic MUST account for this complexity and test     |           |
|        | coverage gaps.                                                   |           |
| D-07   | `StudentLinkedUserSyncService` sync invariant is not covered     | MEDIUM    |
|        | by tests and can silently break.                                 |           |
| D-08   | The `AuthService`/`AuthBloc` degraded mode path has limited      | MEDIUM    |
|        | test coverage.                                                   |           |
| D-09   | Denormalized fields: `studentNameSnapshots` and `teamNameSnapshot` | MEDIUM   |
|        | are IMMUTABLE snapshots (no sync needed). `assignedServantName`    |           |
|        | is eagerly updated per NFR-04.2(a). See FR-14 for implementation.  |           |

---

## 20. Success Criteria

| ID     | Criterion                                                         |
| ------ | ----------------------------------------------------------------- |
| SC-01  | An admin can provision a servant account and the servant can      |
|        | sign in and take attendance within 5 minutes.                     |
| SC-02  | A servant can create a session, mark 30 students, and close the  |
|        | session in under 3 minutes.                                       |
| SC-03  | A student can view their attendance history within 5 seconds of  |
|        | opening the app.                                                  |
| SC-04  | 100% of write operations that require admin privilege are         |
|        | rejected by server-side rules when attempted by non-admin users. |
| SC-05  | The app remains usable (read-only) during a 30-minute Wi-Fi      |
|        | outage at the church.                                             |
| SC-06  | Archive and restore operations complete without orphaned data    |
|        | or inconsistent role state.                                       |
| SC-07  | All attendance marks for a 50-student session are visible in     |
|        | real-time to concurrent viewers within 5 seconds.                 |
| SC-08  | No attendance data is lost or corrupted after an archive/restore |
|        | cycle for any user type.                                          |
