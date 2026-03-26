# Feature Specification: Protect Student Attendance Access

**Feature Branch**: `011-fix-student-access`  
**Created**: 2026-03-24  
**Status**: Draft  
**Input**: User description: "Fix isOwnStudent() security rule in Church Attendance Firebase app.

Context:
- File: firestore.rules
- Function: isOwnStudent(studentId)
- Problem: rule may check studentId == request.auth.uid directly
- Required: check students/{studentId}.linkedUser == request.auth.uid
  because studentId != Firebase Auth UID - linkedUser is the bridge

Acceptance Criteria:
- isOwnStudent(studentId) function reads students/{studentId}.linkedUser
- Students can read ONLY their own marks (linkedUser matches auth.uid)
- Students cannot read any other student's records
- Servants are unaffected (they use hasTeamAccess not isOwnStudent)
- Firebase emulator rule tests pass for student read own / deny other"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Student views own attendance marks (Priority: P1)

A student opens attendance information that belongs to their own student profile and can view only the marks tied to that profile.

**Why this priority**: This is the core user value of the change and restores correct access for students whose profile identifier differs from their sign-in identifier.

**Independent Test**: Can be fully tested by signing in as a student whose account is linked to a student profile, requesting that student's attendance data, and confirming the read succeeds.

**Acceptance Scenarios**:

1. **Given** a signed-in student account is linked to a student profile, **When** the student requests attendance marks for that profile, **Then** access is allowed.
2. **Given** a signed-in student account is linked to a student profile, **When** the student requests attendance marks for their own profile using the linked relationship, **Then** the system recognizes the request as self-access even when the profile identifier does not match the sign-in identifier.

---

### User Story 2 - Student is blocked from other students' marks (Priority: P1)

A student attempts to access attendance information belonging to another student and is denied.

**Why this priority**: Preventing unauthorized exposure of attendance data is a direct privacy and security requirement.

**Independent Test**: Can be fully tested by signing in as one student, requesting a different student's attendance data, and confirming the read is denied.

**Acceptance Scenarios**:

1. **Given** a signed-in student account is linked to one student profile, **When** that student requests attendance marks for a different student profile, **Then** access is denied.
2. **Given** a signed-in student account is not linked to the requested student profile, **When** the student requests attendance marks, **Then** no attendance data is returned.

---

### User Story 3 - Servant access remains unchanged (Priority: P2)

A servant continues to access attendance data through existing team-based permissions without being affected by the student ownership fix.

**Why this priority**: The change must stay narrowly scoped so it fixes student ownership checks without regressing servant workflows.

**Independent Test**: Can be fully tested by signing in as a servant with valid team-based access and confirming the same attendance reads still succeed after the change.

**Acceptance Scenarios**:

1. **Given** a servant has valid team-based access to attendance data, **When** the servant requests student attendance records within that scope, **Then** access behavior remains unchanged.

---

### Edge Cases

- A student profile has no linked user value; access is denied rather than treated as self-access.
- A student is signed in but requests marks for a student profile linked to a different user; access is denied.
- An unauthenticated request attempts to read student attendance marks; access is denied.
- A servant request continues to be evaluated by servant access rules and is not blocked by student-only ownership logic.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST determine student self-access by comparing the signed-in user with the user linked to the requested student profile.
- **FR-002**: The system MUST allow a student to read attendance marks only when the requested student profile is linked to that signed-in student.
- **FR-003**: The system MUST deny a student request for attendance marks when the requested student profile is linked to a different user or has no linked user.
- **FR-004**: The system MUST support student self-access even when the student profile identifier differs from the signed-in user identifier.
- **FR-005**: The system MUST preserve existing servant attendance access behavior that is based on servant-specific permission checks.
- **FR-006**: The system MUST prevent any student from using another student's profile identifier to read attendance marks.
- **FR-007**: The system MUST provide verification coverage for both allowed self-access and denied cross-student access scenarios.

### Key Entities *(include if feature involves data)*

- **Student Profile**: A student record that represents the person's ministry identity and includes the linked user relationship used to determine ownership.
- **Signed-In User**: The authenticated account making the read request.
- **Attendance Mark**: A student-specific attendance record that may be viewed only by the owning student or by already authorized servant flows.

## Assumptions

- Each student profile is intended to link to at most one signed-in user for ownership checks.
- Student attendance reads already distinguish between student-owned access and servant/team-based access.
- This change only adjusts student ownership validation for reads and does not expand the scope of who may update or delete records.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of verified student self-access scenarios succeed when the signed-in user is linked to the requested student profile.
- **SC-002**: 100% of verified cross-student read attempts are denied when the signed-in user is not linked to the requested student profile.
- **SC-003**: 100% of verified requests for student profiles without a linked user are denied.
- **SC-004**: 100% of verified servant access scenarios covered by the regression check continue to behave the same as before this change.
