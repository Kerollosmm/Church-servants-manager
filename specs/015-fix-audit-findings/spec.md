# Feature Specification: Production Audit Remediation

**Feature Branch**: `015-fix-audit-findings`  
**Created**: 2026-03-29  
**Status**: Draft  
**Input**: User description: "Fix the production audit findings and errors, excluding offline sync work."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reliable Attendance Actions (Priority: P1)

As a servant or admin, I need attendance actions to succeed only when I currently have permission, produce a trustworthy audit trail, and show clear reasons when an action is blocked so I can manage service attendance confidently.

**Why this priority**: Attendance marking is the core operational workflow. If it is inaccurate, unaudited, or confusing under changing permissions, the system cannot be trusted in live church operations.

**Independent Test**: Can be fully tested by creating, updating, and clearing attendance marks for valid and invalid users and confirming that successful actions are recorded, failed actions do not create false records, and blocked actions show an actionable reason.

**Acceptance Scenarios**:

1. **Given** an authorized servant or admin and an open attendance session, **When** they create or update a student's attendance mark, **Then** the mark is saved and a corresponding audit record is available to authorized reviewers.
2. **Given** an authorized servant or admin and an existing attendance mark, **When** they clear that mark, **Then** the mark is removed and the audit trail reflects the successful removal only after the removal is complete.
3. **Given** a user whose team assignment or role changed after sign-in, **When** they attempt an attendance action they no longer have permission to perform, **Then** the action is rejected with a clear message explaining that their access changed and that their account view is being refreshed.

---

### User Story 2 - Scalable Attendance History And Summaries (Priority: P1)

As an admin, servant, or linked student, I need attendance history and summary views to remain responsive as records grow over time so I can review attendance without delays, failures, or unstable screens.

**Why this priority**: History and reporting screens are high-frequency workflows for follow-up, pastoral review, and parent or student visibility. They must remain usable as teams accumulate months of attendance data.

**Independent Test**: Can be fully tested by loading attendance history and summaries for users with large historical datasets and confirming the views remain responsive, accurate, and stable during routine updates.

**Acceptance Scenarios**:

1. **Given** a student with a full year of attendance sessions, **When** an authorized user opens the student's attendance history, **Then** the recent history and summary load successfully without freezing, crashing, or timing out.
2. **Given** an admin reviewing multiple teams with mature attendance history, **When** they open team-level attendance summaries, **Then** the summaries load within the expected response window and remain accurate.
3. **Given** historical attendance data that is no longer current, **When** a user opens an active-session or current-history view, **Then** only currently relevant information is treated as active work.

---

### User Story 3 - Safe Session And Bulk Attendance Management (Priority: P2)

As a servant or admin, I need session creation, session closure, and bulk attendance actions to enforce business rules consistently so I can manage large teams without duplicates, hidden failures, or stale sessions.

**Why this priority**: Session lifecycle integrity prevents duplicate attendance windows, incorrect rosters, and bulk-marking failures that would undermine trust in attendance totals.

**Independent Test**: Can be fully tested by attempting duplicate session creation, invalid-duration session creation, early session closure, and bulk attendance marking for large teams while confirming correct blocking, completion, and visibility.

**Acceptance Scenarios**:

1. **Given** an existing active session for a team and time window, **When** another user tries to create a duplicate active session, **Then** the system rejects the duplicate and explains the conflict.
2. **Given** an active session that is complete before its planned end time, **When** an authorized servant or admin closes the session, **Then** the session is closed immediately and no longer appears as active work.
3. **Given** a large team with many unmarked students, **When** an authorized user marks all remaining students present, **Then** the action completes successfully without partial results or silent failure.

---

### User Story 4 - Secure Account And Admin Safeguards (Priority: P2)

As an admin or restored privileged user, I need account lifecycle safeguards to protect access, preserve search and linkage accuracy, and prevent self-lockout so administration remains safe and predictable.

**Why this priority**: User lifecycle problems can block legitimate access, expose the wrong records, or leave the system without a functioning administrator.

**Independent Test**: Can be fully tested by restoring a privileged account, creating linked student records, searching newly created students, and attempting to archive the currently signed-in admin account.

**Acceptance Scenarios**:

1. **Given** a restored privileged account using a temporary password, **When** that user signs in, **Then** they are required to change their password before accessing normal application functions.
2. **Given** an admin attempting to archive their own account, **When** they submit the archive action, **Then** the system rejects the request and explains that self-archive is not allowed.
3. **Given** a newly created student with a linked account, **When** the student record is saved, **Then** the student is immediately searchable and the linked user can access only that student's records.

### Edge Cases

- What happens when a servant's team assignment changes while the app is already open and they try to mark attendance before manually refreshing?
- How does the system handle two users trying to create the same team session at nearly the same time?
- What happens when a user tries to bulk mark attendance for a very large team during a busy service window?
- How does the system treat expired sessions that were never explicitly closed when users open active-session views later?
- What happens when a privileged account is restored but the user dismisses the password-change flow?
- How does the system prevent a single linked account from being attached to multiple student records?

## Assumptions

- Offline sync, offline retry, and offline queue capabilities are explicitly out of scope for this feature.
- The existing role model remains limited to admins, servants, students, and linked student accounts.
- Attendance history and reporting continue to focus on the current operational windows already used by the product unless a separate reporting feature expands them.
- Existing name-based student search behavior remains in place, but newly created records must participate in that search immediately.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow only currently authorized admins and servants to create, update, or clear attendance marks for teams and sessions they are allowed to manage at the time of action.
- **FR-002**: The system MUST create a reviewable audit record for every successful attendance mark creation, update, clearance, session creation, session closure, privileged account archive, and privileged account restore action.
- **FR-003**: The system MUST NOT create or keep a false-success audit record when the underlying business action fails.
- **FR-004**: The system MUST show a clear, user-facing explanation when an attendance or session action is blocked because the user's permissions or team assignments changed since sign-in.
- **FR-005**: The system MUST refresh the user's effective access context after a blocked authorization attempt so repeated actions are evaluated against current assignments.
- **FR-006**: The system MUST prevent more than one active attendance session for the same team and overlapping time window.
- **FR-007**: The system MUST enforce a maximum attendance session duration of 480 minutes for every session creation path.
- **FR-008**: The system MUST allow authorized servants and admins to close an attendance session early when attendance work is complete.
- **FR-009**: The system MUST ensure expired or closed sessions do not appear to users as currently active work.
- **FR-010**: The system MUST complete bulk "mark remaining students present" actions for large teams without partial results, hidden failure, or loss of already confirmed marks.
- **FR-011**: The system MUST provide student attendance history and summary views that remain responsive and stable as each student's session count grows over time.
- **FR-012**: The system MUST provide team attendance summary views that remain responsive and accurate for teams with mature attendance history.
- **FR-013**: The system MUST require restored privileged accounts to change their temporary password before reaching normal application navigation.
- **FR-014**: The system MUST prevent an administrator from archiving their own account.
- **FR-015**: The system MUST make newly created students discoverable through supported name search immediately after creation.
- **FR-016**: The system MUST establish linked student access during student creation so linked users can read only their own records immediately after linkage.
- **FR-017**: The system MUST prevent a single linked user account from being attached to more than one student record at the same time.
- **FR-018**: The system MUST preserve consistent servant-to-team assignment data across all business rules and user views that rely on both current and legacy assignment fields.
- **FR-019**: The system MUST use authoritative timestamps for session closure and privileged account lifecycle events so audit review reflects the true committed event time.
- **FR-020**: The system MUST show a neutral loading or access-resolution state instead of a student-only experience until a signed-in user's actual role is confirmed.

### Key Entities *(include if feature involves data)*

- **Attendance Session**: A team-specific attendance window with a start time, end time, lifecycle state, allowed duration, and eligible roster snapshot.
- **Attendance Mark**: A student's presence record within a session, including status, optional note, actor, and authoritative event time.
- **Attendance Audit Record**: A reviewable record of a completed attendance or administrative action, including actor, action type, target record, and committed time.
- **User Account**: An authenticated person in the system with a role, lifecycle state, team assignments, and possible password-reset or archive restrictions.
- **Student Record**: A student profile containing searchable identity data, optional linked account information, team or class membership, and attendance visibility rules.
- **Team Assignment**: The relationship that defines which teams a servant or admin can manage and which permissions apply in attendance workflows.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successful attendance mark, mark removal, session creation, session closure, privileged account archive, and privileged account restore actions generate a reviewable audit record during acceptance testing.
- **SC-002**: 0 false-success audit records are produced for failed attendance or privileged-account actions during acceptance testing.
- **SC-003**: In a test dataset containing at least 52 sessions for one student, authorized users can open the student's attendance history and summary in under 3 seconds for at least 95% of attempts.
- **SC-004**: In a test dataset containing 10 mature teams, authorized admins can open team attendance summaries in under 5 seconds for at least 95% of attempts.
- **SC-005**: For a team with 200 unmarked students, the bulk "mark remaining students present" action completes successfully with no partial result in at least 99% of test runs.
- **SC-006**: 100% of restored privileged accounts are redirected to password change before accessing normal application navigation during acceptance testing.
- **SC-007**: 100% of self-archive attempts by the current admin are rejected with an explanatory message during acceptance testing.
- **SC-008**: Newly created students are searchable and, when linked, can access only their own records within 1 minute of creation in 100% of acceptance-test scenarios.
