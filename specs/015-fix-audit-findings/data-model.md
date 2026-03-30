# Data Model: Production Audit Remediation

## 1. Attendance Session

- **Purpose**: Represents a team-specific attendance window used for marking, clearing, and closing attendance.
- **Key Fields**:
  - `id`: deterministic session identifier
  - `teamId`: owning team/class identifier
  - `startsAt`: session start time
  - `endsAt`: session end time
  - `durationMinutes`: configured duration, constrained to `1..480`
  - `studentIdsSnapshot`: eligible student roster for the session
  - `isClosed`: explicit closure flag
  - `closedAt`: authoritative close timestamp
  - `createdByUserId`: actor who created the session
  - `closedByUserId`: actor who closed the session
  - `updatedAt`: authoritative last-change timestamp
- **Relationships**:
  - One session belongs to one team.
  - One session has many attendance marks.
  - One session has many audit records.
- **Validation Rules**:
  - At most one active session may exist for a team/time window.
  - A session cannot be created with duration greater than 480 minutes.
  - Only authorized servants/admins may close a session early.
- **State Transitions**:
  - `scheduled/open -> closed`
  - `scheduled/open -> expired`

## 2. Attendance Mark

- **Purpose**: Stores one student's attendance result inside a single session.
- **Key Fields**:
  - `studentId`: unique per session
  - `teamId`: owning team/class
  - `sessionId`: parent session reference
  - `status`: present or late
  - `note`: optional attendance note
  - `markedByUserId`: acting user
  - `markedByName`: actor display name snapshot
  - `markedAt`: original authoritative creation time
  - `updatedAt`: authoritative last-change time
- **Relationships**:
  - One mark belongs to one attendance session and one student.
  - Mark writes produce audit records and update summary/history read models.
- **Validation Rules**:
  - Only one mark may exist per student per session.
  - Mark mutations are allowed only while the session accepts marks.
  - Clearing a mark removes the mark before logging a successful clear event.

## 3. Attendance Audit Record

- **Purpose**: Provides a reviewable committed record of successful attendance or privileged lifecycle actions.
- **Key Fields**:
  - `id`: unique audit identifier
  - `teamId`: related team/class
  - `sessionId`: optional related session
  - `studentId`: optional related student
  - `actionType`: create, update, clear, bulk present, session create, session close, archive, restore
  - `actorUserId`: acting user
  - `actorName`: actor display snapshot
  - `before`: optional prior-state snapshot
  - `after`: optional committed-state snapshot
  - `committedAt`: authoritative event time
- **Relationships**:
  - Many audit records may reference the same session, mark, or user account.
- **Validation Rules**:
  - Audit records are written only for successfully committed business actions.
  - Audit readers must satisfy the same parent-team visibility rules as the related action.

## 4. Student Attendance History Entry (Read Model)

- **Purpose**: Provides a stable, bounded-per-student source for history screens without opening one listener per session.
- **Key Fields**:
  - `studentId`: owning student
  - `sessionId`: related session
  - `teamId`: team/class identifier
  - `sessionStartsAt`: session start time
  - `sessionEndsAt`: session end time
  - `sessionState`: open, closed, expired
  - `status`: present, late, or unmarked/absent representation used by the history view
  - `markedAt`: optional mark timestamp
  - `lastSyncedAt`: last read-model update time
- **Relationships**:
  - One student has many history entries.
  - Entries are derived from attendance session and mark changes.
- **Validation Rules**:
  - Exactly one history entry exists per student-session pair in the supported reporting window.
  - History entries must remain readable by the linked student and authorized staff only.

## 5. Student Attendance Summary (Read Model)

- **Purpose**: Supplies low-cost aggregate statistics for a single student profile.
- **Key Fields**:
  - `studentId`: owning student
  - `windowKey`: reporting window identifier
  - `totalSessions`: completed sessions counted
  - `attendedCount`: present + late count
  - `lateCount`: late-only count
  - `absentCount`: eligible-without-mark count
  - `attendanceRate`: aggregate attendance percentage
  - `lastUpdatedAt`: authoritative summary refresh time
- **Relationships**:
  - One student may have one summary per reporting window.

## 6. Team Attendance Summary (Read Model)

- **Purpose**: Supplies low-cost aggregate statistics for servant/admin dashboards.
- **Key Fields**:
  - `teamId`: owning team
  - `windowKey`: reporting window identifier
  - `sessionsCount`: completed sessions counted
  - `studentsCount`: unique eligible students in window
  - `attendanceRate`: aggregate team attendance percentage
  - `lastUpdatedAt`: authoritative summary refresh time
- **Relationships**:
  - One team may have one summary per reporting window.

## 7. User Account

- **Purpose**: Represents an authenticated admin, servant, or linked student user.
- **Key Fields**:
  - `uid`: auth identifier
  - `role`: admin, servant, student
  - `isArchived`: lifecycle state
  - `restorePendingPasswordReset`: restored-account password-change gate
  - `groupId`: group ownership
  - `assignedTeamIds`: canonical team assignment list
  - `assignedTeamId`: legacy team assignment field kept for compatibility
  - `linkedStudentId`: reverse linkage for linked student accounts
  - `updatedAt`: authoritative lifecycle change time
- **Relationships**:
  - One user may manage multiple teams.
  - One linked student user may be attached to at most one student record.
- **Validation Rules**:
  - Restored privileged accounts cannot bypass the password-change gate.
  - A user cannot archive their own admin account through the admin callable.

## 8. Student Record

- **Purpose**: Represents a student profile, search target, and linked-account ownership source.
- **Key Fields**:
  - `docID`: student document identifier
  - `name`: display name
  - `nameLower`: searchable normalized name
  - `classId`: team/class membership
  - `groupId`: group membership
  - `linkedUserId`: canonical linked account owner
  - `uid`: legacy or duplicated auth identifier retained if already present
- **Relationships**:
  - One student belongs to one team/class.
  - One student may be linked to one user account.
- **Validation Rules**:
  - `nameLower` must be present on creation and update.
  - `linkedUserId` must be unique across students.

## 9. Team Assignment

- **Purpose**: Defines which teams a servant or admin can manage.
- **Key Fields**:
  - `userId`: assigned user
  - `teamIds`: canonical set of assigned teams
  - `legacyTeamId`: first/legacy team value retained for compatibility
  - `updatedAt`: authoritative assignment change time
- **Validation Rules**:
  - Canonical and legacy assignment representations must stay synchronized.
  - Assignment changes must propagate consistently to auth profile reads and team-level rule checks.
