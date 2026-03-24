# Data Model: Stability Fixes

This feature focuses on fixing stability issues in existing data structures. No new entities are introduced.

## Modified State Models

### AttendanceTakingLoaded (Updated Logic)
Represents the UI state during attendance taking. The stability fix ensures that `isMutating` and `mutationError` are handled atomically with respect to stream snapshots.

| Field | Type | Description |
|-------|------|-------------|
| `session` | `AttendanceSession` | The current session metadata (time, team, etc.). |
| `roster` | `List<AttendanceRosterItem>` | The list of students and their current status. |
| `isMutating` | `bool` | True if a local database update is in progress. |
| `mutationError` | `String?` | The error message from the *last* attempted mutation. |

**Validation Rules**:
- `isMutating` must be disabled immediately after an operation completes (success or failure).
- `mutationError` must be cleared at the start of a new mutation.
- Roster data must always reflect the *latest* snapshot from the repository, even during a mutation.
