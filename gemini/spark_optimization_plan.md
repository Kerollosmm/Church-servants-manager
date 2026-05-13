# Spark Plan Quota Optimization Implementation Plan

## Overview
This plan implements the "Optimistic Local + Authoritative Server" architecture for the Church Servers Management System (CSMS) to strictly adhere to the Firebase Spark (free) plan limits. It removes redundant Firestore reads, optimizes role-based access control (RBAC), and batches offline syncs to minimize quota consumption.

## Phase 1: Authentication & "Optimistic Local" RBAC
**Goal:** Reduce role resolution costs from 1 read per interaction to 1 read per session.

- [ ] **Task 1.1: Refactor `FirebaseAuthRepository` Read Flow**
  - Stop fetching the user profile from Firestore on every `userStream` emission.
  - Read `servants/{uid}` exactly once upon successful login (or app startup if the cache is missing).
  - Hydrate the role and assigned team IDs into the local Hive cache and memory.

- [ ] **Task 1.2: Establish Global Role State Management**
  - Create a global `RoleChangedEvent` StreamController (injected via GetIt).
  - Allow UI Cubits/BLoCs to subscribe to this stream to display "Permissions changed" dialogs and navigate the user to a safe screen.

- [ ] **Task 1.3: Implement `PERMISSION_DENIED` Interceptors**
  - **Reads (Cubit Layer):** Update core Cubits (e.g., `StudentListCubit`, `AttendanceCubit`) to catch `FirebaseException(code: 'permission-denied')`. When caught, emit a `RoleStaleState` to prompt a UI refresh.
  - **Writes (SyncService):** Update `SyncService` to catch `FirebaseException(code: 'permission-denied')`. When caught, force a re-fetch of `Users/{uid}` from the server. If the role changed, broadcast the `RoleChangedEvent` via the global controller.

## Phase 2: Implement Strict TTL Caching
**Goal:** Serve 99% of UI requests from local cache, falling back to network only when data is stale.

- [ ] **Task 2.1: Add TTL Metadata to Local Datasources**
  - Update Hive local datasources to store a `last_fetched` timestamp alongside the cached data.

- [ ] **Task 2.2: Refactor Query Services with TTL Logic**
  - Implement the agreed TTLs: Roles (24h), Students (4h), Sessions (1h).
  - Update `AttendanceQueryService` and `StudentQueryService` read logic:
    - Check Hive -> If valid (within TTL), return immediately.
    - If expired (or forced refresh) AND online -> Fetch from Firestore using `get(source: Source.server)` -> Update Hive.

- [ ] **Task 2.3: Optimize Real-Time Listeners**
  - Scan the codebase and remove unbounded `.snapshots()` listeners on large collections.
  - Retain `.snapshots()` **only** for the active attendance marks screen (scoped to a single session's `marks` subcollection) to support simultaneous editing by multiple servants. Ensure the listener is properly killed `onDispose`.

## Phase 3: "WriteBatch" Offline Sync Engine
**Goal:** Process offline mutations efficiently using batching and robust error handling.

- [ ] **Task 3.1: Enhance `SyncEntry` Model**
  - Add `writtenAt` (DateTime of local write) to track when the offline mutation occurred.
  - Add `retryCount` (int) to implement backoff logic for retriable failures.

- [ ] **Task 3.2: Consolidate Sync Queues**
  - Ensure all features enqueue their mutations directly to the central `SyncService`'s Hive box, removing any redundant feature-specific sync queues.

- [ ] **Task 3.3: Refactor `SyncService.processQueue` for Two-Tier Batching**
  - Group pending `SyncEntry` items by feature/collection.
  - **Tier 1 (Fast Path):** Attempt to execute the grouped operations via a single `WriteBatch` (up to 500 ops).
  - **Tier 2 (Fallback):** If the batch fails with a non-permission error, fall back to individual writes.
  - Categorize individual failures:
    - `FAILED_PERMANENT` (e.g., `not-found`, `invalid-argument`): Drop the entry from the queue and log it.
    - `FAILED_RETRIABLE` (e.g., timeout): Increment the `retryCount` and leave in the queue for later.

- [ ] **Task 3.4: Implement Hybrid Conflict Resolution (LWW)**
  - For high-volume updates (e.g., marking attendance), use "Blind Overwrite" (`SetOptions(merge: true)`) in the batch to save reads.
  - For critical low-volume mutations (e.g., session creation), retain the transactional read-then-write logic to ensure data integrity.