# Data Model: Fix Attendance Mark Document ID

## Entity: Attendance Session

- **Purpose**: Parent record that owns all attendance marks for one team session.
- **Key fields**:
  - `id`: stable session identifier
  - `teamId`: owning team/class identifier
  - `studentIdsSnapshot`: frozen roster for the session
  - `studentNameSnapshots`: name fallback source for mark display
  - `startsAt` / `endsAt` / `isClosed`: controls whether marks can still be edited
- **Relationships**:
  - One session has many attendance marks.
- **Validation rules**:
  - Marks may only be written for students present in `studentIdsSnapshot`.
  - Marks may only be edited while the session is writable.

## Entity: Attendance Mark

- **Purpose**: Canonical per-student attendance result for a single session.
- **Business key**:
  - `studentId` within the parent session
- **Stored fields**:
  - `studentId` (derived from document identity)
  - `studentNameSnapshot`
  - `status` (`present` or `late` in the current persisted model)
  - `markedByUserId`
  - `markedByName`
  - `markedAt`
  - `updatedAt`
  - `note` (optional)
- **Relationships**:
  - Belongs to one attendance session.
  - Corresponds to one roster item for the same student and session.
- **Validation rules**:
  - Only one mark may exist per `studentId` within a session.
  - Re-marking the same `studentId` updates the existing mark.
  - `markedAt` remains the original mark time when a mark is updated.
  - `updatedAt` reflects the most recent successful write.

## Entity: Attendance Roster Item

- **Purpose**: Derived view model shown in the attendance-taking workflow.
- **Key fields**:
  - `studentId`
  - `sessionId`
  - `manualStatus`
  - `effectiveStatus`
  - `isMarked`
  - `markedAt`
  - `markedByName`
- **Relationships**:
  - Built from one session plus zero or one attendance mark.
- **Validation rules**:
  - `effectiveStatus` remains `present` or `late` when a mark exists.
  - `effectiveStatus` becomes `absent` only when the session is effectively closed with no mark.
  - `effectiveStatus` becomes `unmarked` while the session is open and no mark exists.

## Entity: Local Attendance Record

- **Purpose**: Device-side representation of a session mark used for continuity and offline-friendly retries when such a model exists in the implementation layer.
- **Business key**:
  - `recordId = studentId`
- **Relationships**:
  - Mirrors one attendance mark for one student in one session.
- **Validation rules**:
  - Must use the same student-based identity as the server-side attendance mark.
  - Must not generate a second business ID for the same student/session mark.

## Entity: Sync Queue Item

- **Purpose**: Tracks queued synchronization work independently from the attendance mark's business identity.
- **Business key**:
  - Unique queue item identifier
- **Relationships**:
  - May reference one local attendance record.
- **Validation rules**:
  - Queue item identity stays independent from `studentId`.
  - Multiple queue operations can still be correlated without changing the canonical attendance mark identity.

## State Transitions

- **Unmarked -> Present**: first successful present mark write creates or updates the student-keyed mark.
- **Unmarked -> Late**: first successful late mark write creates or updates the student-keyed mark.
- **Present -> Late**: re-mark updates the existing student-keyed mark and keeps one stored record.
- **Late -> Present**: re-mark updates the existing student-keyed mark and keeps one stored record.
- **Marked -> Cleared**: clearing attendance removes the existing student-keyed mark.
- **Open Unmarked -> Absent**: derived display/status outcome after session close with no stored mark; no new persisted absent mark is introduced by this feature.
