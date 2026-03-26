# Research: Fix Attendance Mark Document ID

## Decision 1: Keep attendance mark identity keyed by `studentId`

- **Decision**: The canonical attendance mark identity for a student within a session is `studentId`, producing the mark path `classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`.
- **Rationale**: This guarantees idempotent writes for repeated marking and matches the feature requirement that one student can only have one stored mark per session.
- **Alternatives considered**:
  - Generate a random mark identifier for each write: rejected because it allows duplicate mark documents for the same student and session.
  - Use a composite generated identifier: rejected because the repository already receives the natural unique key (`studentId`) and does not need an additional identity layer.

## Decision 2: Preserve existing repository mutation behavior and timestamps

- **Decision**: Continue using the existing merge-based mark write flow so re-marking updates the same document, preserves the first `markedAt` value when present, and refreshes `updatedAt`.
- **Rationale**: This keeps existing attendance-taking behavior stable while still making repeated marks idempotent.
- **Alternatives considered**:
  - Replace the write with unconditional overwrite semantics: rejected because it would discard the original mark timestamp behavior.
  - Add a transaction for every mark: rejected because the current single-document flow is already sufficient for idempotent updates.

## Decision 3: Keep Cubit and UI contracts unchanged

- **Decision**: `AttendanceTakingCubit` continues to call the same repository methods without new states, events, or UI workflow changes.
- **Rationale**: The business fix is in record identity, not in user interaction. Preserving the current Cubit contract satisfies the requirement that attendance-recording states continue to work correctly.
- **Alternatives considered**:
  - Add new Cubit states for duplicate prevention: rejected because the repository-level identity change is transparent to the user flow.
  - Move attendance identity checks into the Cubit: rejected by the constitution's repository-layer rule.

## Decision 4: Treat local attendance record identity separately from queue correlation

- **Decision**: Any local attendance-record model used for mark persistence should use `studentId` as its record identity, while queue correlation items keep their own unique queue IDs.
- **Rationale**: This mirrors the server-side business identity and preserves the ability to track queued sync work independently.
- **Alternatives considered**:
  - Reuse the same generated ID for both attendance records and queue items: rejected because it mixes business identity with transport correlation.
  - Leave local records on random IDs while the server uses `studentId`: rejected because it would weaken idempotency across offline and retry flows.

## Decision 5: Planning evidence from the current repository snapshot

- **Decision**: The current `AttendanceRepository` already resolves mark documents through `_markDoc(teamId, sessionId, studentId)`, so implementation should verify and retain this behavior while focusing additional work on local identity alignment and regression safety.
- **Rationale**: The planning scan found the repository already writing marks through a `studentId`-based document reference and the repository test suite already includes an idempotency check for this path.
- **Alternatives considered**:
  - Assume the repository still uses generated IDs and plan a broader Firestore path refactor: rejected because the current source snapshot does not support that assumption.
  - Expand the scope into unrelated attendance cleanup: rejected by the constitution's surgical-change rule.

## Decision 6: No external API contract change is required

- **Decision**: Treat this feature as an internal persistence and repository-behavior correction, documented through an internal repository contract note rather than a public API schema.
- **Rationale**: The feature does not introduce a new external service endpoint or user-facing protocol.
- **Alternatives considered**:
  - Create a public API contract: rejected because the mobile app does not expose a new external endpoint for this fix.
  - Skip contract documentation entirely: rejected because the repository behavior still benefits from a concise internal contract for implementation and review.
