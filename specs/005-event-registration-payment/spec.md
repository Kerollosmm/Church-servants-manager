# Feature Specification: Event Registration

**Feature Branch**: `005-event-registration-payment`  
**Created**: 2026-03-23  
**Status**: Draft  
**Input**: User description: "I want to add a new feature that allows church members to register for events and pay for them online." (Updated: Registration is free, no payment system required).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Member & Guest Registration (Priority: P1)

As a user (member or guest), I want to find an upcoming event and register for it so that I can secure my spot quickly and conveniently.

**Why this priority**: This is the core functionality. The system must handle both authenticated members (students/servants) and public guests depending on the event's settings.

**Independent Test**: Can be tested by navigating to an event page, entering required details (automatically populated for members, manual for guests), and verifying that a registration record is created and capacity is updated.

**Acceptance Scenarios**:

1. **Given** an event marked "Open to All", **When** a guest provides their Name and Phone number, **Then** the registration is recorded and the event's available capacity is reduced.
2. **Given** an event marked "Members Only", **When** an unauthenticated guest attempts to register, **Then** they are prompted to log in or informed that the event is restricted to members.
3. **Given** an event that has reached its capacity, **When** any user attempts to register, **Then** they are notified that the event is full.

---

### User Story 2 - Registration Confirmation (Priority: P2)

As a registered participant, I want to receive an immediate confirmation of my registration so that I have a record of my intent to attend.

**Why this priority**: Confirmation is essential for user peace of mind and provides necessary details (date, time, location) for the user's records.

**Independent Test**: Can be tested by completing a registration and verifying that a notification is triggered and that members can see their registration in their dashboard.

**Acceptance Scenarios**:

1. **Given** a successful registration, **When** the form is submitted, **Then** an automated confirmation message is displayed and (if applicable) sent via notification.
2. **Given** a registered member, **When** they log into their dashboard, **Then** they can see a list of events they have successfully registered for.

---

### User Story 3 - Registration Cancellation (Priority: P3)

As a participant or administrator, I want to be able to cancel a registration so that the spot is freed up for someone else.

**Why this priority**: Adds flexibility for the user and helps the church manage event capacity effectively.

**Independent Test**: Can be tested by selecting an existing registration and initiating a cancellation, verifying that the status updates and capacity is released.

**Acceptance Scenarios**:

1. **Given** an existing registration, **When** a user or an admin selects 'Cancel Registration', **Then** the registration is removed or marked 'Cancelled', and the spot is returned to the event's available capacity.

---

### Edge Cases

- **Duplicate Registration**: What happens when a guest tries to register multiple times with the same phone number for the same event? The system should prevent or warn about duplicate entries.
- **Concurrent Registrations**: How does the system handle two users registering for the last available spot at the exact same time? The system must handle the "race condition" gracefully to prevent over-registration.
- **Member-Guest Hybrid**: What happens if a member registers as a guest (using Name/Phone) instead of logging in? The system should ideally recognize the phone number if it exists in the database, or simply treat it as a guest entry to keep the flow fast.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a list of available events with clear registration deadlines and capacity limits.
- **FR-002**: System MUST allow users to provide registration details (e.g., dietary requirements, emergency contact) specific to each event.
- **FR-003**: System MUST support event-specific registration types: "Members Only" (Authenticated Students/Servants) or "Open to All" (Members + Guests).
- **FR-004**: System MUST allow guests to register for "Open to All" events using only their Name and Phone number.
- **FR-005**: System MUST allow both users (for their own registrations) and Administrators to cancel registrations to free up capacity.
- **FR-006**: System MUST ensure NO payment information is collected or processed, as all events are free.

### Key Entities *(include if feature involves data)*

- **Event**: Represents a church activity. Attributes: Title, Description, Date/Time, Location, Capacity, Registration Deadline, Access Type (Members Only / Open to All).
- **Registration**: Records a participant's entry. Attributes: Event ID, User ID (if member), Guest Name (if guest), Guest Phone (if guest), Timestamp, Status (Active, Cancelled), Custom Fields.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the registration process in under 1 minute.
- **SC-002**: 100% of registrations result in an immediate confirmation message.
- **SC-003**: System accurately maintains event capacity, preventing over-registration 100% of the time.
- **SC-004**: 95% of guest registrations include valid contact information (Name + Phone).

## Assumptions

- We assume participants have access to a mobile device or computer to register.
- We assume admins will keep event capacities and deadlines up to date.
- We assume no financial transactions will ever be required for these events within this application.
