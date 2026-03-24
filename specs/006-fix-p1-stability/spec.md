# Feature Specification: Fix P1 Stability Issues

**Feature Branch**: `006-fix-p1-stability`  
**Created**: 2026-03-23  
**Status**: Draft  
**Input**: User description: "I have a code review document at C:\Users\KimoStore\Downloads\church_code_review.docx.md that contains prioritized issues (P1/P2/P3) for the church_management_system Flutter app. Read the file and create a feature spec for fixing all P1 issues: - P1-A: app_router.dart — mixed context.read and getIt - P1-B: role_router.dart — unsafe AuthDegraded cast - P1-C: attendance_taking_cubit.dart — race condition in _runMutation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Dependency Resolution [P1-A] (Priority: P1)

Developers and users should experience a stable app where dependencies are resolved reliably. The current mix of retrieval strategies in the routing logic can mask wiring errors and lead to confusing runtime crashes if the environment is not perfectly aligned with expectations.

**Why this priority**: Stability in core routing and dependency injection is foundational. Failure here causes app-wide crashes or broken features during navigation.

**Independent Test**: Can be tested by navigating to all student-related screens (List, Detail, Edit) and verifying that all services and logic controllers initialize correctly without "provider not found" or registration errors.

**Acceptance Scenarios**:

1. **Given** the app is navigating to a feature screen, **When** the screen requires data use cases, **Then** the system must resolve these dependencies using a single, unified strategy.
2. **Given** a routing transition is in progress, **When** dependencies are injected into a new feature block, **Then** the process must be deterministic and independent of the widget tree context.

---

### User Story 2 - Safe Role-Based Routing [P1-B] (Priority: P1)

Admin users with "degraded" account status (requiring data refreshes or re-authentication) must be handled safely. The current implementation uses an unsafe type conversion that will cause an immediate crash if the user's state changes unexpectedly during navigation.

**Why this priority**: Prevents critical crashes for administrative users and ensures that security-sensitive account transitions are handled gracefully.

**Independent Test**: Can be tested by triggering a "degraded" account state for an admin and verifying they are safely routed to a refresh screen instead of the app crashing.

**Acceptance Scenarios**:

1. **Given** an admin user's session status changes to "degraded," **When** the system resolves their dashboard route, **Then** it must use safe matching logic to display the refresh screen without risking a type-related crash.
2. **Given** any user role, **When** routing is resolved, **Then** the system must validate the session state type before performing role-specific operations.

---

### User Story 3 - Atomic Attendance Processing [P1-C] (Priority: P1)

Servants marking attendance need a reliable system that handles rapid updates correctly. A race condition currently exists where a database update might finish just as new data arrives from the server, potentially "swallowing" error messages or showing incorrect status icons.

**Why this priority**: Attendance taking is a core, high-frequency operation. Data integrity and clear UI feedback are essential for user trust.

**Independent Test**: Can be tested by simulating a network delay during an attendance mark followed by a rapid data emission, verifying that any errors are correctly preserved and displayed to the user.

**Acceptance Scenarios**:

1. **Given** an attendance mark is in progress, **When** the operation completes, **Then** the system must accurately report the result based on the state at the start of that specific action.
2. **Given** multiple data updates arrive from the server, **When** a local action is also running, **Then** the local action's result must not be overwritten or lost by the incoming server data.

---

### Edge Cases

- What happens if `getIt` is accessed before it is fully initialized during a route transition?
- How does the `RoleRouter` handle a state that has a non-null user but is neither `AuthAuthenticated` nor `AuthDegraded`?
- What happens if the attendance roster stream emits a new snapshot exactly when a local mutation completes?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST ensure all application dependencies are resolved using a single, consistent mechanism to prevent initialization errors and navigation crashes.
- **FR-002**: System MUST handle account status transitions (such as administrative permission changes) gracefully without causing application interruptions.
- **FR-003**: System MUST ensure attendance records are processed reliably, preventing data loss or UI inconsistencies when multiple updates occur simultaneously.
- **FR-004**: System MUST provide accurate and immediate visual feedback to users during data processing operations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero runtime crashes due to type casting in `RoleRouter`.
- **SC-002**: 100% consistency in dependency resolution across all routes managed by `AppRouter`.
- **SC-003**: Attendance data integrity maintained even under "stress" (rapid user interaction).
- **SC-004**: Successful completion of all P1 bug fixes verified by manual or automated regression tests.
