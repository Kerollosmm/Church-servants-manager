# Contract: Attendance Read Models

## Purpose

Define the consumer-facing contract for attendance history and summary data used by the app after the remediation.

## Read Model Types

- Student attendance history entries
- Student attendance summary
- Team attendance summary

## Shared Contract Rules

- Read models are additive and do not replace the source attendance session or mark records.
- Read models are derived only from committed attendance/session changes.
- Read models must never expose data to a user who could not read the underlying source records.
- Read models must be safe for direct UI consumption without one-listener-per-session fan-out.

## Student Attendance History Contract

### Consumer Promise

- The student history screen can load a student's recent attendance from one bounded source.
- Each entry includes session timing, session state, and the student's resulting attendance status.
- Closed and expired sessions are represented accurately and are not shown as active work.

### Freshness Expectation

- After a committed attendance or session lifecycle change, the related history entry is updated before the UI reports the action complete, or the UI continues showing a safe loading state until the update is available.

## Student Attendance Summary Contract

### Consumer Promise

- A student profile reads one summary object per supported reporting window.
- The summary contains session count, attendance count, lateness count, absence count, and attendance rate.

### Freshness Expectation

- Summary values reflect the latest committed attendance/session changes in the supported reporting window.

## Team Attendance Summary Contract

### Consumer Promise

- Servant/admin dashboards read one summary object per team and reporting window.
- The summary supports dashboard cards without scanning all historical sessions and marks.

### Freshness Expectation

- Team summary values are refreshed whenever a committed attendance mutation or session lifecycle change affects the reporting window.

## Authorization Contract

- Linked students can read only their own history and summary.
- Servants can read only summaries and histories for teams they are currently assigned to manage.
- Admins can read all summaries and histories within the existing admin visibility scope.

## Failure Contract

- If a read model is unavailable or stale, the app must fail safely by showing a retryable loading/error state rather than silently falling back to an expensive N-listener or N+1 read path.
