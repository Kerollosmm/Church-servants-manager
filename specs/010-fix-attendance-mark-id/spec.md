# Feature Specification: Fix Attendance Mark Document ID

**Feature Branch**: `010-fix-attendance-mark-id`  
**Created**: 2026-03-24  
**Status**: Draft  
**Input**: User description: "Fix attendance mark document ID in Church Attendance Flutter app.

Context:
- File: lib/features/attendance/data/repos/attendance_repository.dart
- Method: saveAttendanceMark() or equivalent
- Problem: Currently uses Uuid().v4() as Firestore document ID for marks
- Required: Firestore mark doc ID MUST equal studentId
  Path: classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}
- Why: Idempotent writes - same student can't have duplicate marks per session

Acceptance Criteria:
- Mark document written to Firestore uses studentId as doc ID
- Re-marking same student in same session = update, not duplicate
- AttendanceRecordHive.recordId also = studentId for marks
- UUID only used for SyncQueueItemHive.recordId (queue correlation)
- All attendance recording BLoC states still work correctly
- Existing mark present/absent/late logic unchanged"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record One Mark Per Student Per Session (Priority: P1)

As a servant taking attendance, I can mark a student's attendance for a session and be confident the system keeps a single authoritative mark for that student in that session.

**Why this priority**: Preventing duplicate attendance marks is the core business need because duplicate entries can distort attendance history, reporting, and later corrections.

**Independent Test**: Can be fully tested by recording attendance for one student in one session and confirming only one mark exists for that student in that session.

**Acceptance Scenarios**:

1. **Given** a student has not yet been marked in a session, **When** attendance is recorded, **Then** the system stores exactly one mark for that student in that session.
2. **Given** a student already has a mark in a session, **When** attendance is recorded again for the same student in the same session, **Then** the existing mark is updated instead of creating another mark.

---

### User Story 2 - Correct a Student's Mark Without Duplicates (Priority: P2)

As a servant correcting attendance, I can change a student's mark from one status to another in the same session without creating duplicate entries.

**Why this priority**: Attendance corrections are common during live recording, and staff must be able to fix mistakes without compromising data integrity.

**Independent Test**: Can be fully tested by marking a student with one attendance status, re-marking the same student with a different status, and confirming the final stored result reflects only the most recent mark.

**Acceptance Scenarios**:

1. **Given** a student is marked present in a session, **When** the servant changes the mark to absent for the same session, **Then** the student still has one mark in that session and its status becomes absent.
2. **Given** a student is marked absent in a session, **When** the servant changes the mark to late for the same session, **Then** the student still has one mark in that session and its status becomes late.

---

### User Story 3 - Preserve Offline and Sync Workflow Behavior (Priority: P3)

As a servant recording attendance in normal or offline-assisted flows, I can continue using the existing attendance workflow without new steps or unexpected state changes while duplicate mark creation is prevented.

**Why this priority**: The workflow must remain stable for current users, especially where local records and queued sync actions are involved.

**Independent Test**: Can be fully tested by recording and re-recording attendance through the existing workflow, including local persistence and queued synchronization, and confirming the user-facing states behave as before.

**Acceptance Scenarios**:

1. **Given** attendance is recorded through the existing workflow, **When** the operation completes, **Then** the user sees the same success and progress behavior currently expected by the attendance flow.
2. **Given** a queued synchronization item is created for an attendance update, **When** the item is processed, **Then** it remains uniquely trackable without changing the business identity of the attendance mark itself.

---

### Edge Cases

- What happens when a student is marked multiple times in rapid succession within the same session? The system keeps only one mark for that student in that session and the latest saved status becomes authoritative.
- How does the system handle a correction from present to absent or late, or between absent and late? The system updates the existing mark without changing the allowed attendance statuses or their meaning.
- What happens when an existing local attendance record and a pending sync action both reference the same student and session? They continue to point to the same business record so the final synchronized result is a single updated mark.
- What happens when a mark already exists from an earlier attempt and the user retries after a transient failure? The retry updates the same mark rather than creating a duplicate.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST treat each student's attendance mark within a given session as a single unique record.
- **FR-002**: The system MUST use the student's identifier as the business identity for an attendance mark within a session.
- **FR-003**: When attendance is recorded again for the same student in the same session, the system MUST update the existing mark instead of creating a new mark.
- **FR-004**: The system MUST store local attendance records for session marks using the same student-based record identity used for the session mark.
- **FR-005**: The system MUST keep queue-tracking identifiers independent from the business identity of an attendance mark so synchronization items can still be uniquely correlated.
- **FR-006**: The system MUST preserve the existing attendance status options and status-selection behavior for present, absent, and late marks.
- **FR-007**: The system MUST preserve the current attendance recording workflow outcomes so users can continue recording and correcting marks without additional steps.
- **FR-008**: The system MUST ensure that re-marking a student in the same session results in one final authoritative mark for that student and session.

### Key Entities *(include if feature involves data)*

- **Attendance Session**: A single meeting or class occurrence in which attendance is recorded for a defined group of students.
- **Attendance Mark**: A student's attendance status for one session, uniquely identified by the student within that session and updated when re-marked.
- **Local Attendance Record**: The device-stored representation of an attendance mark used to support continuity and synchronization.
- **Sync Queue Item**: A queued action used to track and process pending attendance synchronization attempts independently from the attendance mark's business identity.

## Assumptions

- Historical duplicate marks, if any already exist, are outside the scope of this feature unless they are touched by a new update.
- User roles, permissions, and the visible attendance workflow remain unchanged.
- The allowed attendance statuses remain present, absent, and late with their current meaning and rules.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In validation testing, 100% of repeated attendance submissions for the same student in the same session result in one stored mark, not multiple marks.
- **SC-002**: In validation testing, 100% of attendance corrections for the same student in the same session preserve only the latest selected status as the final result.
- **SC-003**: Users can re-mark a student in an existing session without any additional manual cleanup steps or duplicate-removal steps.
- **SC-004**: Regression testing confirms the existing attendance recording flow continues to complete successfully for present, absent, and late scenarios.
