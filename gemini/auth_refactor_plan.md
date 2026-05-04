# Authentication System Refactor Plan

## Objective
Secure the authentication flow, optimize free-tier Firestore costs by shifting role authority to Firebase Auth Custom Claims, and improve offline reliability by leveraging native Firestore caching so the app opens instantly like a social media app.

## Background & Motivation
The current implementation uses `combineLatest2` to merge a continuous `.watchProfile()` Firestore stream with Firebase Auth token changes. This results in continuous document reads, threatening the free-tier quota. Additionally, manual 12-second timeouts and `flutter_secure_storage` logic introduce race conditions during unstable network conditions.

## Scope & Impact
- **Backend:** Cancelled Cloud Function deployment (Spark Plan constraint). Role synchronization will be handled via existing admin scripts (`tools/set_custom_claims.js`).
- **Data Layer:** Refactoring `FirebaseAuthRepository` to use `idTokenChanges` and native Firestore caching.
- **Presentation Layer:** Updating `AuthBloc` to support manual token refreshes.
- **Dependencies:** Removing `flutter_secure_storage` and `AuthFreshnessPolicy` to rely strictly on native Firebase offline capabilities.

## Proposed Solution

### 1. Refactor `FirebaseAuthRepository`
- Remove the `combineLatest2` stream.
- Update `userStream` to map over `idTokenChanges()`.
- Inside the map, fetch custom claims to determine the role (Source of Truth).
- Fetch the user profile using a one-time request: `.get(const GetOptions(source: Source.serverAndCache))`.
- Add a `forceRoleRefresh()` method that calls `user.getIdToken(true)`.

### 2. Refactor Offline/Session Management
- Remove the 12-second timeout logic in `AuthUserProfileStore` and `FirestoreProfileProvider`.
- Remove `AuthFreshnessPolicy` and the `flutter_secure_storage` dependency. The app will rely solely on Firebase Auth's native token persistence and Firestore's `cacheSizeBytes` to allow the app to open instantly based on the last known state.

### 3. Update `AuthBloc`
- Map a pull-to-refresh action (or manual sync button) to an `AuthEventForceRefresh`.
- Handle the token refresh via the repository to silently update claims.

## Verification
- Disconnect network (Airplane mode) and verify the app instantly loads the cached profile.
- Admin changes a role via local script -> User initiates pull-to-refresh -> User receives new role via updated claims without a persistent Firestore stream.