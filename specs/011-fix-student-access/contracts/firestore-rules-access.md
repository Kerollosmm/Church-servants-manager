# Contract: Firestore Attendance Access

**Branch**: `011-fix-student-access` | **Date**: 2026-03-24

This contract defines the expected allow/deny outcomes for attendance mark reads affected by
this feature.

## Scope

- Resource path: `classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`
- Ownership source: `students/{studentId}.linkedUser`
- Out of scope: write authorization changes, attendance storage redesign, servant permission redesign

## Authorization Contract

| Actor | Preconditions | Requested Resource | Expected Result |
|-------|---------------|--------------------|-----------------|
| Student | Authenticated user ID matches `students/{studentId}.linkedUser` | Mark for the same `studentId` | Allow read |
| Student | Authenticated user ID does not match `students/{studentId}.linkedUser` | Mark for another student's `studentId` | Deny read |
| Student | Student profile has no `linkedUser` value | Mark for that `studentId` | Deny read |
| Servant | Existing team-based access check passes | Mark within authorized team scope | Preserve current read behavior |
| Unauthenticated user | No authenticated user | Any student mark | Deny read |

## Verification Matrix

| Scenario ID | Scenario | Expected Outcome |
|-------------|----------|------------------|
| RA-001 | Student reads own mark through linked profile | Allowed |
| RA-002 | Student reads another student's mark | Denied |
| RA-003 | Student reads mark where profile has no linked user | Denied |
| RA-004 | Servant reads mark within existing access scope | Unchanged from baseline |

## Deployment Gate

Rules deployment is ready only after emulator verification demonstrates the expected result
for RA-001 through RA-004.
