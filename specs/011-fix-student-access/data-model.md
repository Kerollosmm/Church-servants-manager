# Data Model: Protect Student Attendance Access

**Branch**: `011-fix-student-access` | **Date**: 2026-03-24

No new entities are introduced. This feature changes how existing records are used during
authorization.

## Entities

### 1. Student Profile

Represents the ministry-side identity for a student.

| Field | Type | Purpose | Validation / Notes |
|-------|------|---------|--------------------|
| `studentId` | String | Document identifier used in attendance mark paths | Does not need to match the authenticated user ID |
| `linkedUser` | String | Ownership bridge to the authenticated account | Required for student self-read authorization |
| `isArchived` | Boolean | Existing student activity flag | Archived handling remains unchanged for this feature |

**Relationship**:
- One student profile links to one authenticated user for self-read authorization.

### 2. Authenticated User

Represents the signed-in account making the Firestore request.

| Field | Type | Purpose | Validation / Notes |
|-------|------|---------|--------------------|
| `uid` | String | Request identity used in rule evaluation | Must match `StudentProfile.linkedUser` for self-read |
| `role` | String | Existing authorization role | Servant and admin behavior remain governed by current role checks |

### 3. Attendance Mark

Represents a student-specific attendance record stored under a session.

| Field | Type | Purpose | Validation / Notes |
|-------|------|---------|--------------------|
| `studentId` | String | Document key for the mark | Must correspond to the owning student profile ID |
| `status` | String | Existing attendance outcome | No schema or validation change in this feature |
| `markedByUserId` | String | Existing writer audit field | No change |

**Relationship**:
- Each attendance mark is keyed by `studentId` under `classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`.
- A student may read a mark only when the associated student profile links back to the requesting authenticated user.

## Authorization State Rules

### Student self-read
- Allowed when `StudentProfile.linkedUser == AuthenticatedUser.uid`.

### Student cross-read
- Denied when `StudentProfile.linkedUser != AuthenticatedUser.uid`.

### Missing link
- Denied when the student profile has no `linkedUser` value.

### Servant read
- Unchanged; still governed by existing team-based access checks.
