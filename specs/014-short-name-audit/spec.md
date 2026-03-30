# Feature Specification: CSMS Production Hardening Remediation

**Feature Branch**: `[014-short-name-audit]`  
**Created**: 2026-03-28  
**Status**: Draft  
**Input**: User description: "Plan to fix all issues except offline sync, using this audit review and another independent audit review as the basis for production hardening."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Restore End-to-End Attendance Operations (Priority: P1)

An admin or servant must be able to complete the full attendance workflow again: open the attendance area, create a session, mark students, review the live roster state, and view student or team attendance history without encountering blank or dead-end screens.

**Why this priority**: Attendance is the app's primary operational purpose. If the workflow remains unusable, the product cannot deliver core value regardless of improvements elsewhere.

**Independent Test**: Can be fully tested by signing in as an authorized user, creating a session, marking multiple students, closing the session where permitted, and reviewing the resulting history from the app without relying on developer tools.

**Acceptance Scenarios**:

1. **Given** an authorized admin or servant opens attendance management, **When** they navigate to create a session, **Then** they can create a valid session through a working screen and proceed to attendance taking.
2. **Given** an open attendance session exists, **When** an authorized servant marks students as present or late and clears a mark where allowed, **Then** the roster updates correctly and the action is reflected in the session history.
3. **Given** a student or authorized staff member opens attendance history, **When** they view prior attendance, **Then** they see accurate historical records through working screens rather than placeholders or blank pages.

---

### User Story 2 - Enforce Safe Access and Account Boundaries (Priority: P1)

An administrator needs confidence that users only access the records and actions allowed by their current role and relationship to the data, and that self-service account flows cannot expand a user's privileges.

**Why this priority**: Security and trust boundaries are mandatory for a church management system that handles member data, attendance history, and privileged administrative actions.

**Independent Test**: Can be fully tested by attempting role-restricted actions with admin, servant, student, archived, and self-registered accounts and verifying the system blocks improper access while allowing legitimate access.

**Acceptance Scenarios**:

1. **Given** a self-registering user creates an account, **When** the registration completes, **Then** the account is created only with the allowed self-service role and cannot self-elevate to privileged roles.
2. **Given** a student is linked to one student profile, **When** the student views records, **Then** they can access only their own allowed data and cannot access another student's profile, attendance, or reports.
3. **Given** an account is archived, restored, or loses privileges, **When** the user attempts restricted actions, **Then** access is enforced consistently and the user cannot continue using stale privileges.

---

### User Story 3 - Preserve Auditability and Data Integrity Under Real Usage (Priority: P2)

Administrators need operational records to remain trustworthy when multiple servants work at once, when accounts are archived or restored, and when attendance marks or team membership change over time.

**Why this priority**: Production readiness depends on being able to explain who changed what, prevent destructive overwrites, and retain trustworthy historical records.

**Independent Test**: Can be fully tested by having multiple authorized users update the same operational area, archive and restore accounts, clear and reapply attendance marks, and confirm that resulting data and audit history remain correct.

**Acceptance Scenarios**:

1. **Given** two authorized staff members work on the same open session, **When** one performs a bulk completion action while another records individual exceptions, **Then** the system preserves the intended final outcome without silently overwriting higher-value manual input.
2. **Given** an administrator archives or restores a servant or student-related record, **When** the action completes, **Then** the system records who performed it and when it occurred.
3. **Given** a mark is removed or changed, **When** the change is saved, **Then** the system retains enough historical context for administrators to understand that the earlier state existed and was intentionally changed.

---

### User Story 4 - Make Reporting and Administration Operationally Useful (Priority: P3)

An administrator or servant needs reporting and operational screens to provide actionable, bounded, and understandable information without requiring excessive wait times or hidden technical knowledge.

**Why this priority**: Reports, audit access, and admin lifecycle tools are necessary for real-world operation, but they are secondary to restoring the core workflow and access safety.

**Independent Test**: Can be fully tested by loading team and student attendance summaries for realistic date ranges, reviewing administrative history, and completing account lifecycle actions from working screens.

**Acceptance Scenarios**:

1. **Given** an administrator requests a team attendance summary for a defined period, **When** the report loads, **Then** it returns an accurate bounded result rather than scanning unlimited history.
2. **Given** an administrator restores a managed account, **When** the restore flow completes, **Then** the system clearly shows the next required action for that account and records the restore event.

### Edge Cases

- What happens when two servants mark the same student or session at nearly the same time?
- How does the system handle a session that crosses midnight or has a title that does not normalize cleanly for identifiers?
- What happens when a user's role or archive status changes while they still have a cached session?
- How does the system handle clearing a previously recorded attendance mark without losing accountability?
- What happens when team membership snapshots and live team membership no longer match?
- How does the system behave when cached list data is incomplete, stale, or filtered differently from current server truth?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide working attendance session creation, attendance taking, attendance history, and student attendance views for authorized users.
- **FR-002**: The system MUST prevent release of placeholder or blank attendance management screens for core operational flows covered by this feature.
- **FR-003**: The system MUST enforce that self-service registration creates only the allowed self-service account type.
- **FR-004**: The system MUST enforce role-based permissions consistently across user session resolution, protected navigation, data access, and privileged operations.
- **FR-005**: The system MUST ensure a student can access only the student's own allowed records and cannot access another student's data through alternate field mappings or stale relationships.
- **FR-006**: The system MUST ensure archived or downgraded accounts cannot continue privileged use through stale cached identity or authorization state.
- **FR-007**: The system MUST record the acting user and action time for archive, restore, create, close, and other high-impact administrative changes.
- **FR-008**: The system MUST preserve an accountable history for attendance mark removal or replacement rather than erasing the existence of prior marked states without traceability.
- **FR-009**: The system MUST protect individual attendance exceptions from being silently overwritten by bulk attendance completion actions.
- **FR-010**: The system MUST prevent conflicting attendance sessions for the same team within the same active time window.
- **FR-011**: The system MUST use a single canonical user-to-student relationship for access control and profile linkage.
- **FR-012**: The system MUST keep session validation rules authoritative in one place so the same duration, time-window, and closure rules apply across creation, editing, and review flows.
- **FR-013**: The system MUST support attendance history and summary reporting for defined date ranges without requiring unbounded historical scans.
- **FR-014**: The system MUST provide working administrator flows for managed account lifecycle actions, including restore follow-up guidance and audit visibility.
- **FR-015**: The system MUST provide searchable student and servant records that behave consistently for the expected languages and name formats used by church staff.
- **FR-016**: The system MUST ensure team membership changes do not leave silently stale fallback data that misstates who belongs to a team.
- **FR-017**: The system MUST reduce unnecessary repeated authorization and data-loading checks in hot operational paths where the same result can be safely reused within a single user action.
- **FR-018**: The system MUST bound administrative and attendance report queries so they remain operationally usable for normal church data volumes.
- **FR-019**: The system MUST provide an audit review surface for administrators to inspect key operational actions covered by this feature.
- **FR-020**: This feature MUST explicitly exclude redesigning the offline write queue, retry engine, or broader offline sync architecture; those concerns remain out of scope for this remediation feature.

### Key Entities *(include if feature involves data)*

- **User Account**: Represents an authenticated person with a current role, lifecycle status, and access scope used to decide what actions are permitted.
- **Student Profile**: Represents a church member student record with a single canonical linked user relationship, class/team membership, and visibility rules.
- **Servant Profile**: Represents a servant's managed account, assignment scope, lifecycle status, and audit trail for administrative actions.
- **Team**: Represents a church class or service team whose membership, attendance sessions, and summaries must stay consistent over time.
- **Attendance Session**: Represents a time-bounded attendance-taking event for one team, including its lifecycle, roster snapshot, and closure state.
- **Attendance Mark**: Represents the current recorded status for one student in one session, together with accountable change history.
- **Attendance Summary**: Represents bounded historical totals for a student or team over a chosen period.
- **Audit Event**: Represents an immutable record of a high-impact operational action, including actor, target, time, and action type.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of core attendance workflows covered by this feature can be completed from the product interface without encountering blank, placeholder, or dead-end screens.
- **SC-002**: 100% of self-service registration attempts create only the allowed self-service role in acceptance testing.
- **SC-003**: 100% of authorization acceptance tests covering admin, servant, student, archived, and restored account scenarios pass with no unauthorized data exposure.
- **SC-004**: In concurrent attendance-marking acceptance tests, manual exception handling outcomes are preserved correctly in 100% of tested race scenarios.
- **SC-005**: 100% of archive, restore, session creation, session closure, and attendance mark change actions covered by this feature produce an attributable audit record.
- **SC-006**: Team and student attendance summaries for a defined reporting period load in under 3 seconds for normal operating volumes of up to 200 active students and 100 sessions in the selected range.
- **SC-007**: At least 90% of administrators participating in acceptance review can complete account lifecycle and attendance review tasks on the first attempt without developer assistance.

## Assumptions

- Existing roles remain administrator, servant, and student.
- The current product direction keeps attendance, reporting, and account lifecycle management as core use cases.
- Server-authoritative enforcement may be introduced where necessary to satisfy security, audit, and concurrency requirements.

## Out of Scope

- Offline write queue design, replay behavior, retry orchestration, sync status tracking, and broader offline-sync architecture redesign.
- Visual redesign goals not required to restore operational logic, access safety, or workflow completeness.
