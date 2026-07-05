# Implementation Plan - Offline Attendance & Idempotent Client Sync

## Phase 1: Local Storage & Domain Layer
- Task 1.1: Define Attendance Record Entity & Hive Adapter DTO with UUID `recordId`.
- Task 1.2: Implement Local Data Source using Hive box for attendance records & sync outbox.

## Phase 2: Client Outbox Queue & Repositories
- Task 2.1: Implement Attendance Repository with local-first write and outbox enqueue strategy.
- Task 2.2: Implement Sync Engine Service to monitor `connectivity_plus` and trigger client-side batch writes to Firestore (`/attendance/{recordId}`).

## Phase 3: BLoC & Presentation Integration
- Task 3.1: Build `AttendanceBloc` to handle marking attendance, local caching, sync status events.
- Task 3.2: Integrate sync indicator in UI showing pending outbox count and sync state.

## Phase 4: Unit Testing & Verification
- Task 4.1: Write unit tests for Attendance Repository and Sync Engine (verifying idempotency and retry logic).
