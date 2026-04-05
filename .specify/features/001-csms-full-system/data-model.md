# Data Model: CSMS Full System

## Firestore Collections

### Users (Top-Level)

| Field | Type | Required | Mutable By | Notes |
| ----- | ---- | -------- | ---------- | ----- |
| uid | string | Yes | Backend only | Matches Firebase Auth UID |
| name | string | Yes | Admin, Self | Snapshotted to teams/sessions (immutable). See session `createdByName` and `studentNameSnapshots`. |
| email | string | Yes | Admin, Self | Matches Firebase Auth email |
| role | string (enum) | Yes | Backend only | "admin", "servant", "student" |
| isArchived | bool | Yes | Backend only | Default: false |
| isEmailVerified | bool | Yes | Self, Backend | Synced from Firebase Auth |
| assignedTeamId | string? | No | Admin (service) | Legacy single-team field |
| assignedTeamIds | string[] | No | Admin (service) | Multi-team support |
| groupId | string? | No | Admin | Group category (year1, year2, year3) |
| restorePendingPasswordReset | bool | No | Backend only | Set on restore, cleared on password change |
| createdAt | Timestamp | Yes | Backend only | Server timestamp |
| updatedAt | Timestamp | Yes | Any updater | Server timestamp |
| provisionedBy | string? | No | Backend only | Admin UID who created this user |

**Update Contract:** Backend Cloud Functions own `role`, `isArchived`, `restorePendingPasswordReset`, `createdAt`, `provisionedBy`. Client-side writes are limited to `name`, `email`, `isEmailVerified`, `updatedAt` (for self-updates).

### Students (Top-Level)

| Field | Type | Required | Mutable By | Notes |
| ----- | ---- | -------- | ---------- | ----- |
| id | string | Yes | System | Auto-generated doc ID |
| uid | string? | No | Backend only | Linked Users UID (null if no app account) |
| name | string | Yes | Admin, Servant | Full name |
| phone | string? | No | Admin, Servant | |
| email | string? | No | Admin, Servant | |
| group | string? | No | Admin | "year1", "year2", "year3" |
| classId | string? | No | Admin | Reference to Classes doc |
| team_name | string? | No | Admin (eager sync) | Denormalized from Classes. EAGER UPDATE on team rename. |
| isArchived | bool | Yes | Admin | Default: false |
| role | string | Yes | System | Always "student" |
| createdAt | Timestamp | Yes | System | Server timestamp |
| updatedAt | Timestamp | Yes | System | Server timestamp |

**Update Contract:** `team_name` is eagerly updated when the referenced team is renamed (owner: `TeamRepository.rename()`).

### Classes / Teams (Top-Level, Collection: "Classes")

| Field | Type | Required | Mutable By | Notes |
| ----- | ---- | -------- | ---------- | ----- |
| id | string | Yes | System | Auto-generated doc ID |
| name | string | Yes | Admin | Team display name |
| group | string? | No | Admin | "year1", "year2", "year3" |
| assignedServantId | string? | No | Admin (service) | UID of assigned servant |
| assignedServantName | string? | No | Admin (service) | Denormalized. EAGER UPDATE on servant rename AND on reassignment. When assignedServantId changes, the Admin service must atomically fetch and write the new servant's name alongside the ID change. If the servant record is not found, the reassignment fails. |
| isArchived | bool | Yes | Admin | Default: false |
| createdAt | Timestamp | Yes | System | Server timestamp |
| updatedAt | Timestamp | Yes | System | Server timestamp |

**Update Contract:** `assignedServantName` is eagerly updated when the servant's name changes (owner: `AdminTeamService` or servant rename handler).

### Classes/{teamId}/attendance_sessions/{sessionId} (Subcollection)

| Field | Type | Required | Mutable By | Notes |
| ----- | ---- | -------- | ---------- | ----- |
| teamId | string | Yes | System | Parent team reference |
| teamNameSnapshot | string | Yes | System | IMMUTABLE. Team name at creation time. |
| title | string | Yes | Creator | Session title |
| dateKey | string | Yes | System | "YYYY-MM-DD" for indexing |
| startsAt | Timestamp | Yes | Creator | Session start time |
| endsAt | Timestamp | Yes | Creator | Session end time |
| durationMinutes | int | Yes | Creator | Must be > 0 |
| createdByUserId | string | Yes | System | UID of session creator |
| createdByName | string | Yes | System | IMMUTABLE. Creator name at creation time. |
| isClosed | bool | Yes | Admin | Default: false |
| studentIdsSnapshot | string[] | Yes | System | IMMUTABLE. Roster frozen at creation time. |
| studentNameSnapshots | Map<string, string> | Yes | System | IMMUTABLE. {studentId: name} at creation time. |
| createdAt | Timestamp | Yes | System | Server timestamp |
| updatedAt | Timestamp | Yes | System | Server timestamp |
| reopenedByUserId | string? | No | Admin | UID of admin who reopened |
| reopenedByName | string? | No | Admin | IMMUTABLE snapshot of reopener name |
| reopenedAt | Timestamp? | No | Admin | When session was reopened |

**ID Generation:** Deterministic: `{dateKey}_{startsAt.toUtc().millisecondsSinceEpoch}_{sanitized_title}` where `dateKey` is "YYYY-MM-DD" derived from the session's start datetime, and `sanitized_title` is the title trimmed, lowercased, with non-alphanumeric characters (preserving Arabic Unicode \u0600-\u06FF) replaced by dashes. For collision resistance, a SHA-256 hash of `(teamId + title + startsAt)` truncated to 8 hex characters may be appended as an additional suffix.

### Classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId} (Subcollection)

| Field | Type | Required | Mutable By | Notes |
| ----- | ---- | -------- | ---------- | ----- |
| studentNameSnapshot | string | Yes | System | IMMUTABLE. Student name at mark time. |
| status | string (enum) | Yes | Servant, Admin | "present" or "late". No null/cleared. |
| markedByUserId | string | Yes | System | UID of marker |
| markedByName | string | Yes | System | IMMUTABLE. Marker name at first mark time. |
| markedAt | Timestamp | Yes | System | Server timestamp. First mark time, preserved on update. |
| updatedAt | Timestamp | Yes | System | Server timestamp. Updated on every change. |
| note | string? | No | Servant, Admin | Optional note for mark |

**Toggle-Off:** Document is DELETED (not set to null). Absence = no document (BR-07, FR-08.7).

### audit_logs (Top-Level, Backend-Only)

| Field | Type | Required | Notes |
| ----- | ---- | -------- | ----- |
| action | string | Yes | "user.create", "user.archive", "user.restore", etc. |
| actorUid | string | Yes | UID of admin who performed action |
| targetUid | string? | No | UID of affected user (if applicable) |
| details | Map | No | Additional context (role, email, etc.) |
| timestamp | Timestamp | Yes | Server timestamp |

**Access:** Read: admin only. Write: backend functions only (INV-07).

## State Transitions

### User Lifecycle

```
[Created by Admin CF] → Active → Archived → Restored (pending password reset) → Active
                                     ↑                         |
                                     └─────────────────────────┘ (can re-archive)
```

### Session Lifecycle

```
[Created] → Open (within time window) → Ended (past time window) → Closed (admin)
                                                                         ↓
                                                                    Reopened (admin) → Open
```

### Mark Lifecycle

```
[No Mark] → Present ←→ Late
     ↑          |          |
     └──────────┘          |
     └─────────────────────┘
     (toggle-off = delete document)
```
