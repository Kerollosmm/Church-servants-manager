# API Documentation

This application has no REST API surface. All backend interaction is through the **Firebase Client SDK** — Firestore real-time queries and Firebase Auth. Firebase Cloud Functions are provisioned (see `functions/`) but are used for administrative server-side tasks rather than a client-facing API.

The sections below document the Firestore collections as the effective "API contract."

---

## Firestore Collections

### `Users/{userId}`

Stores the authenticated user's profile enriched with app-specific fields.

| Field | Type | Description |
|---|---|---|
| `uid` | `string` | Firebase Auth UID (mirrors document ID) |
| `email` | `string` | User's email |
| `name` | `string` | Display name |
| `role` | `string` | `'admin'` · `'servant'` · `'student'` |
| `isEmailVerified` | `bool` | Mirrors Firebase Auth email verification state |
| `isArchived` | `bool` | Soft-delete flag |
| `archivedAt` | `Timestamp?` | When the account was archived |
| `archivedByUserId` | `string?` | UID of the admin who archived |
| `archiveReason` | `string?` | Free-text reason |
| `restoredAt` | `Timestamp?` | When restored |
| `restoredByUserId` | `string?` | UID of the restoring admin |
| `restorePendingPasswordReset` | `bool` | True when a restored account requires a password reset |
| `groupId` | `string?` | Group/year the servant belongs to |
| `assignedTeamId` | `string?` | Legacy single-team assignment (kept for backwards compatibility) |
| `assignedTeamIds` | `string[]` | Current multi-team assignment list |

**Access Rules:**
- Read: own document or admin
- Create: admin or self (new sign-up; role must be `student`)
- Update: admin or self (restricted to `name`, `email`, `isEmailVerified`, `updatedAt`)
- Delete: admin only

---

### `Students/{studentId}`

Extended profile for users with `role == student`. Document ID is independent of the user's UID.

| Field | Type | Description |
|---|---|---|
| `uid` | `string` | Firebase Auth UID of the linked user account (if any) |
| `docID` | `string` | Firestore document ID |
| `name` | `string` | Full name |
| `imageUrl` | `string?` | Profile photo URL |
| `mobile` | `string` | Student's phone number |
| `group` | `string` | `year1` · `year2` · `year3` |
| `team_name` | `string` | Human-readable team name (denormalised) |
| `mother_number` | `string` | Mother's phone |
| `father_number` | `string` | Father's phone |
| `grade` | `int` | School year/grade |
| `education_stage` | `string` | `preparatory` · `highSchool` · `college` |
| `school_college` | `string?` | School or college name |
| `address` | `string?` | Home address |
| `birthdate` | `Timestamp?` | Date of birth |
| `father_of_confession` | `string` | Name of confession father (priest) |
| `notes` | `string?` | Miscellaneous notes |
| `classId` | `string?` | Team document ID; enables single-query lookup without joins |
| `isArchived` | `bool` | Soft-delete flag |
| `archivedAt` | `Timestamp?` | — |
| `archivedByUserId` | `string?` | — |
| `archiveReason` | `string?` | — |
| `restoredAt` | `Timestamp?` | — |
| `restoredByUserId` | `string?` | — |
| `createdAt` | `Timestamp?` | — |
| `updatedAt` | `Timestamp?` | — |

**Access Rules:**
- Read: admin; servant (own group/team students); student (own doc)
- Create/Update: admin; servant (own group/team, cannot change `role` or `uid`)
- Delete: admin only

---

### `Classes/{teamId}`

Represents a ministry team. Collection name `Classes` is the legacy name; the app treats these as teams.

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Document ID |
| `name` | `string` | Team display name |
| `groupId` | `string` | Group/year (`year1`, `year2`, `year3`) |
| `assignedServantId` | `string?` | Servant UID |
| `assignedServantName` | `string?` | Denormalised servant name |
| `isArchived` | `bool` | Soft-delete |
| `archivedAt` · `archivedByUserId` · `archiveReason` · `restoredAt` · `restoredByUserId` | various | Archive audit trail |

**Access Rules:**
- Read: admin or servant
- Create/Update/Delete: admin only

---

### `Classes/{teamId}/attendance_sessions/{sessionId}`

One attendance session per meeting. Document ID format: `{dateKey}_{timestampMs}_{titleSlug}`.

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Document ID (deterministic from date + time + title) |
| `teamId` | `string` | Parent team ID |
| `teamNameSnapshot` | `string?` | Team name at session creation |
| `title` | `string?` | Optional session label |
| `dateKey` | `string` | `YYYY-MM-DD` string for indexed lookups |
| `startsAt` | `Timestamp` | Session start |
| `endsAt` | `Timestamp` | Session end (= startsAt + durationMinutes) |
| `durationMinutes` | `int` | Duration > 0 |
| `createdByUserId` | `string` | Creator UID |
| `createdByName` | `string` | Creator display name at creation time |
| `createdAt` | `Timestamp` | — |
| `updatedAt` | `Timestamp` | — |
| `isClosed` | `bool` | Set to true by admin to lock the session |
| `isReopenedForAdminEdit` | `bool` | Admin re-opened an otherwise closed session |
| `reopenedAt` · `reopenedByUserId` · `reopenedByName` | various | Reopen audit |
| `studentIdsSnapshot` | `string[]` | Ordered student IDs captured at session creation |
| `studentNameSnapshots` | `map<string,string>` | Student names captured at session creation |

**Access Rules:**
- Read: admin or servant who manages that team
- Create: admin or team's servant; team must be active; payload validated server-side (schema, `createdByUserId == callerUid`, `isReopenedForAdminEdit == false`)
- Update/Delete: admin only

---

### `Classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`

One document per student per session. Document ID == student ID.

| Field | Type | Description |
|---|---|---|
| `studentNameSnapshot` | `string` | Student name at mark time |
| `status` | `string` | `'present'` · `'late'` |
| `markedByUserId` | `string` | UID of person who took attendance |
| `markedByName` | `string` | Their name |
| `markedAt` | `Timestamp` | First mark time (preserved on updates) |
| `updatedAt` | `Timestamp` | Last update time |
| `note` | `string?` | Optional note |

**Effective Statuses:** `present`, `late`, or `absent` (implicit when no mark document exists and session has ended).

**Access Rules:**
- Read: admin or team's servant
- Create/Update: admin or team's servant; session must be open (time-bounded) or reopened by admin; student must be active
- Delete: same conditions as create/update

---

## Firebase Cloud Functions

The `functions/` directory contains server-side logic. From the client's perspective, these are invoked via the `cloud_functions` SDK (`FirebaseFunctions.instance.httpsCallable(...)`). Functions handle operations that require elevated privileges not expressible in Firestore rules (e.g., creating a Firebase Auth user on behalf of an admin, sending custom emails).

Specific function names and payloads are defined in `functions/index.js` (or equivalent). Check `data/services/admin_auth_client.dart` for client call sites.
