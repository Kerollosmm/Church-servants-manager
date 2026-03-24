# Feature Specification: Fix P3 Backlog Issues

**Feature Branch**: `008-fix-p3-issues`  
**Created**: 2026-03-23  
**Status**: Draft  
**Input**: User description: "Fix all P3 issues identified in church_code_review.docx.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Optimized List Loading (Priority: P1)

As an Admin or Servant with a large congregation, I want the student and servant lists to load efficiently so that the app remains responsive and doesn't crash due to memory pressure.

**Why this priority**: High impact on app stability and responsiveness for larger churches. Prevents memory issues identified in the code review.

**Independent Test**: Can be tested by scrolling through a list of 500+ students and verifying that data is fetched in batches and memory usage remains stable.

**Acceptance Scenarios**:

1. **Given** a team with 500 students, **When** I open the student list, **Then** I should see the first batch of students immediately without long loading times.
2. **Given** I am at the end of the loaded student list, **When** I scroll further down, **Then** the next batch of students should load automatically.

---

### User Story 2 - Network Connectivity Awareness (Priority: P2)

As a user working in areas with unstable internet, I want to know when I am working offline so that I understand why data might be stale or why my changes haven't synced yet.

**Why this priority**: Improves user trust and transparency regarding data synchronization.

**Independent Test**: Can be tested by disabling network connectivity and verifying that an indicator appears within 2 seconds.

**Acceptance Scenarios**:

1. **Given** the app is open, **When** the device loses internet connection, **Then** a persistent but non-intrusive offline indicator should appear.
2. **Given** the app is showing an offline indicator, **When** connection is restored, **Then** the indicator should disappear automatically.

---

### User Story 3 - Attendance Session Expiry Warning (Priority: P2)

As a Servant taking attendance, I want to be warned when my session is about to expire so that I can finish marking attendance before the session ends.

**Why this priority**: Prevents loss of work and improves the user experience during the critical attendance-taking workflow.

**Independent Test**: Can be tested by starting an attendance session and waiting until 10 minutes remain, then verifying the banner appears.

**Acceptance Scenarios**:

1. **Given** I am on the attendance taking screen, **When** the session has less than 10 minutes remaining, **Then** a countdown banner should be displayed at the top of the screen.
2. **Given** the countdown banner is visible, **When** the session expires, **Then** the UI should clearly indicate that the session has ended.

---

### User Story 4 - Theme Token Cleanup (Priority: P3)

As a Developer, I want legacy color aliases to be marked as deprecated so that I am guided towards using the correct Material 3 theme tokens.

**Why this priority**: Improves code maintainability and consistency for future development.

**Independent Test**: Can be tested by checking if legacy color aliases in `app_colors.dart` trigger deprecation warnings in the IDE.

**Acceptance Scenarios**:

1. **Given** I am using a legacy color alias like `textPrimary`, **When** I view the code, **Then** I should see a deprecation warning suggesting the use of `onBackground`.

---

### Edge Cases

- **FR-001 (Pagination)**: What happens if the network fails while loading a subsequent batch? The system should allow the user to retry loading the batch.
- **FR-002 (Offline Indicator)**: How does the system handle "flapping" connections? The indicator should have a slight debounce to avoid flickering.
- **FR-003 (Session Expiry)**: What happens if the user's system clock is incorrect? The session expiry should ideally be calculated based on server-synced time.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST implement Firestore pagination for student and servant list screens.
- **FR-002**: System MUST display a persistent network offline indicator widget when the device is not connected to the internet.
- **FR-003**: System MUST show a countdown banner in the attendance taking screen when the remaining session time is less than 10 minutes.
- **FR-004**: System MUST mark legacy color aliases in `app_colors.dart` with `@Deprecated` annotations, providing the recommended replacement in the message.

### Key Entities *(include if feature involves data)*

- **Attendance Session**: Represents the active window for taking attendance, including a start and end time.
- **Student/Servant Records**: The paginated data entities displayed in lists.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Initial view of student/servant lists (first 20 items) loads in under 500ms on a standard connection.
- **SC-002**: Offline status is detected and displayed to the user within 2 seconds of connectivity loss.
- **SC-003**: 100% of users on the attendance taking screen receive a visual warning when their session has less than 10 minutes remaining.
- **SC-004**: 0 usage of non-deprecated legacy color aliases in new code contributions.
