# Contract: Attendance Operations

## Purpose
Define the user-visible and operational contract for attendance session creation, attendance taking, history review, and mark correction.

## Actors
- Administrator
- Servant
- Student (read-only where allowed)

## Contract Rules

1. An authorized administrator or servant can open the attendance area and reach a working session-create flow.
2. An authorized administrator or servant can open an active session and mark individual students as present or late.
3. A bulk completion action may fill only unmarked students and must not silently replace manual exception handling.
4. Attendance mark changes and removals must be attributable and reviewable.
5. A student may view only the student's own allowed attendance history.
6. Team and student attendance history views must be accessible through working screens and limited to authorized scopes.
7. Conflicting active sessions for the same team must be rejected.

## Acceptance Signals
- The core attendance workflow can be completed from the app without blank screens.
- Concurrent mark handling preserves intended outcomes.
- Session and mark lifecycle actions appear in audit review.
