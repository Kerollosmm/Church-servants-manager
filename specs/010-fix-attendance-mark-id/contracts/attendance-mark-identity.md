# Internal Contract: Attendance Mark Identity

## Scope

This contract covers the attendance repository behavior used by the attendance-taking flow.

## Contract Rules

1. A mark for a student within a session is identified by `studentId`.
2. Writing a mark for the same `teamId`, `sessionId`, and `studentId` must target the same stored record.
3. Repeating a mark operation for the same student and session must update the existing record instead of creating another one.
4. The persisted manual mark statuses remain limited to the current stored statuses; derived absent behavior stays computed from session state rather than a new stored absent mark.
5. Any local attendance-record identity must match `studentId`.
6. Queue correlation identifiers remain independently generated and must not replace the attendance mark's business identity.

## Verification Evidence

- Repository path resolution uses the student-specific mark document reference.
- Repeated mark operations leave one mark document in the session marks collection.
- Attendance-taking Cubit continues using the existing repository interface and state flow.
