# Auth Logic Fixes Plan

## Background & Motivation
To finalize the Auth layer refactor, we need to address two remaining gaps:
1. **`currentUser` getter**: Currently falls back to `AuthUser.fromFirebase()` which assigns a default role, potentially leaking over-privileged UI states before the auth stream stabilizes. It needs to be claim-first.
2. **Role change detection**: The app currently doesn't detect out-of-band role updates (e.g., from an admin script) without a full app restart or manual refresh. We need to introduce a sentinel flag (`requiresTokenRefresh`) in the Firestore profile to trigger reactive token refreshes without violating Spark plan read quotas.

## Scope & Impact
- **Models:** `AuthUser` will gain a `requiresTokenRefresh` boolean field (defaulting to false).
- **Repository:** `FirebaseAuthRepository` will be updated to:
  - Watch for `requiresTokenRefresh == true` in `userStream`.
  - Force a token refresh when detected, emit the new user state, and clear the flag in Firestore.
  - Update the `currentUser` fallback logic.
- **BLoC:** `AuthBloc` will introduce `AuthRoleRefreshing` and `AuthRoleUpdated` states.
- **UI:** `RoleUserRoute` will handle the refreshing state (blocking navigation) and display a banner when permissions are updated.
- **Security:** `firestore.rules` will allow self-updates for the `requiresTokenRefresh` field.

## Implementation Steps

### Phase 1: Model & Security Rules
1. Update `AuthUser` model with `@Default(false) bool requiresTokenRefresh`.
2. Update `firestore.rules` in `validSelfUserUpdate` to allow updating `requiresTokenRefresh`.

### Phase 2: Repository Refactor (GAP 1 & 2)
1. **Fix GAP 1 (`currentUser`):** Update `getCurrentUser()` to call `getIdTokenResult(false)` and build a claim-first user. Ensure the synchronous `currentUser` getter uses `_lastKnownAppUser`.
2. **Fix GAP 2 (Reactive Refresh):** Add logic to `userStream` to detect `requiresTokenRefresh` and trigger `forceTokenRefresh()`.

### Phase 3: BLoC State Transitions
1. Create `AuthRoleRefreshing` and `AuthRoleUpdated` states.
2. Update `AuthBloc` to handle the refresh lifecycle.

### Phase 4: UI Integration
1. Update `RoleUserRoute` to display loading overlay during refresh.
2. Show "Your permissions have been updated" banner on completion.
