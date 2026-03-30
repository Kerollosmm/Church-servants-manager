# Data Model: CSMS Production Hardening Remediation

## 1. User Account Authority

**Purpose**: Represents the authoritative account identity used to decide coarse access and lifecycle state.

**Key Fields**:
- `uid`
- `role`
- `isArchived`
- `groupId`
- `assignedTeamIds`
- `linkedStudentId` or canonical equivalent
- lifecycle metadata for archive/restore

**Validation Rules**:
- Self-service registration may create only the self-service role.
- Archive state must immediately revoke privileged behavior.
- Canonical student linkage must resolve to one allowed student profile only.

**Relationships**:
- One user account may link to one student profile.
- One servant/admin account may operate across allowed teams only.

## 2. Student Profile

**Purpose**: Represents a managed student record visible to authorized staff and, where allowed, to the linked student user.

**Key Fields**:
- `studentId`
- `name`
- canonical linked user reference
- `classId`
- `group`
- archive and restore metadata

**Validation Rules**:
- Only one canonical user link is allowed.
- Membership fallback data must not be treated as silent truth when stale.

**Relationships**:
- Belongs to zero or one current team/class.
- Appears in team membership projections and session snapshots.

## 3. Servant Profile

**Purpose**: Represents a managed staff account with assigned operational scope.

**Key Fields**:
- `uid`
- `name`
- `assignedTeamIds`
- `groupId`
- archive and restore metadata

**Validation Rules**:
- Archive/restore actions require actor attribution.
- Team assignments must remain consistent with server-side scope.

## 4. Team

**Purpose**: Represents a church team/class used for attendance and assignment scoping.

**Key Fields**:
- `teamId`
- `name`
- `groupId`
- membership projection fields
- archive state

**Validation Rules**:
- Team membership projections must reflect current active members.
- Archived teams must not accept new attendance sessions.

## 5. Attendance Session

**Purpose**: Represents one time-bounded attendance-taking event.

**Key Fields**:
- `sessionId`
- `teamId`
- `title`
- `dateKey`
- `startsAt`
- `endsAt`
- `isClosed`
- roster snapshots (`studentIdsSnapshot`, `studentNameSnapshots`)
- actor and lifecycle timestamps

**Validation Rules**:
- No overlapping active session may exist for the same team.
- Duration and closure rules must be validated consistently in one authoritative place.
- Session access must align with current role and relationship rules.

**State Transitions**:
- `Open` -> `Closed`
- `Open` -> `Expired-but-unclosed view state` for display logic only

## 6. Attendance Mark Current State

**Purpose**: Represents the latest effective recorded mark for one student in one session.

**Key Fields**:
- `studentId`
- `sessionId`
- current mark status
- `markedAt`
- `updatedAt`
- actor metadata
- optional note/reason

**Validation Rules**:
- Only one current mark exists per student per session.
- Bulk completion actions must not silently overwrite manual exception states.
- Removal/change operations must preserve accountability.

## 7. Attendance Audit Event

**Purpose**: Represents an immutable history entry for attendance or lifecycle changes.

**Key Fields**:
- `eventId`
- `eventType`
- actor reference
- target entity reference
- `occurredAt`
- before/after summary
- optional reason

**Validation Rules**:
- Events are append-only.
- High-impact actions must produce one attributable event.

## 8. Attendance Summary

**Purpose**: Represents bounded historical totals for team or student reporting.

**Key Fields**:
- scope reference (`teamId` or `studentId`)
- reporting window
- totals (`totalSessions`, `attended`, `late`, `absent`)
- derived percentage

**Validation Rules**:
- Summaries must be bounded by explicit reporting windows.
- Summary data must not require unlimited historical scanning for routine usage.
