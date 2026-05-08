# Architectural Correction Plan

## Objective
Align the Church Management System (CSMS) with strict Firebase Spark Plan constraints and Offline-First design by deprecating Custom Claims for RBAC, minimizing Firestore transaction read amplifications, centralizing the sync engine, and enforcing offline-first read strategies.

## Key Files & Context
- `lib/features/auth/data/repos/firebase_auth_repository.dart`
- `lib/features/auth/data/models/auth_user.dart`
- `lib/features/attendance/data/repos/attendance_session_repository.dart`
- `lib/features/attendance/data/local/mark_sync_entry.dart`
- `lib/core/services/sync_service.dart`

## Implementation Steps

### 1. Deprecate Custom Claims & Implement Firestore-First RBAC
*   Modify `FirebaseAuthRepository.userStream` and `getCurrentAppUser`:
    *   Instead of relying exclusively on token claims (`result.claims`), perform a one-time `.get(GetOptions(source: Source.serverAndCache))` call to `/servants/{uid}` using `AuthUserProfileStore.fetchUser`.
    *   The fetched profile data (including `role` and `assignedTeamIds`) will be merged with the `FirebaseUser` and stored locally in Hive via `AuthUserLocalStore`.
*   Update `AuthUser` factory if necessary to not enforce custom claims mapping for roles and teams, relying on the user profile fetched from Firestore.

### 2. Refactor `attendance_session_repository.dart`
*   In `createSession` and `reopenSession`:
    *   Replace `Future.wait(idsToCheck.map((id) => transaction.get(...)))` inside the `runTransaction` loop.
    *   Instead, chunk the `idsToCheck` into lists of max 30 items.
    *   Perform a `whereIn` query *before* the transaction to fetch existing sessions:
        `firestore.collection(sessions).where(FieldPath.documentId, whereIn: chunk).get(const GetOptions(source: Source.server))`
    *   Load these session documents into memory before starting the transaction, to minimize read operations within the transaction lock and avoid read amplification.

### 3. Unify Sync Engine (`SyncService`)
*   Move `MarkSyncEntry` and its related operations (currently localized in `features/attendance/data/local/mark_sync_entry.dart`) to a generalized `core/services/sync_service.dart`.
*   Establish a generic `SyncEntry` format or unified queue.
*   Setup a centralized Hive box `sync_queue_box` specifically for background mutations.
*   Implement connectivity detection inside `SyncService` to auto-trigger the batch upload process when the network comes online.

### 4. Enforce `Source.cache` Fallbacks
*   Scan the codebase for all `.get()` queries.
*   Update unguarded `collection.get()` calls to explicitly include `GetOptions(source: Source.cache)` or handle fallback locally, preventing Spark quota leaks on app startups when offline.

## Verification & Testing
*   Verify that users can log in, fetch their role from Firestore correctly, and caching handles offline app restarts seamlessly.
*   Create a session with simulated overlapping times; assert the chunked `whereIn` query prevents read amplification effectively without exceeding quotas.
*   Test offline mutation queuing via the unified `SyncService`. Ensure mutations replay linearly upon regaining network connection.
