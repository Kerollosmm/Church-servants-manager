# Contract: Access Control and Auditability

## Purpose
Define the expected behavior for role-based access, self-service registration boundaries, managed account lifecycle actions, and audit visibility.

## Contract Rules

1. Self-service registration creates only the allowed self-service account type.
2. Archived or downgraded users cannot continue privileged operations through stale session state.
3. Students can access only their own allowed records through a single canonical identity link.
4. Servants can access only the operational scope granted to them.
5. Administrators can review lifecycle and attendance audit entries for high-impact operations.
6. Archive and restore actions must record who performed them and when.
7. Managed account restore flows must leave administrators with a clear next step for completing the lifecycle action safely.

## Acceptance Signals
- Unauthorized data access attempts are denied consistently.
- Archive/restore/create/close/mark-change actions are attributable.
- Administrators can review operational history without inspecting raw backend records.
