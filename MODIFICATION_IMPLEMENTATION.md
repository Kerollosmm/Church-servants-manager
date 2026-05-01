# MODIFICATION IMPLEMENTATION: Auth Architectural Fixes (P0 + P1)

This plan outlines the phased implementation of architectural and security improvements to the Authentication feature.

## Phase 1: Preparation and Verification
- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Verify the current state of `AuthFreshnessPolicy` and `AuthUserProfileStore` to ensure baseline functionality.

## Phase 2: Provider Refactoring (P1)
- [x] Create `FirebaseIdentityProvider` in `lib/features/auth/data/services/` (extracted from `FirebaseAuthProvider`).
- [x] Create `FirestoreProfileProvider` in `lib/features/auth/data/services/` (extracted from `FirebaseAuthProvider`).
- [x] Implement 1-hour TTL logic in `FirestoreProfileProvider` as a secondary safety mechanism.
- [x] Update `AuthUserProfileStore` to expose detailed metadata (e.g., `lastFetchedAt`) for TTL checks.
- [x] Remove/Deprecate the original `FirebaseAuthProvider`.

## Phase 3: Reactive Repository & Stream Merging (P1)
- [x] Update `AuthRepository` interface in `lib/features/auth/domain/repos/` to include `userStream`.
- [x] Implement `userStream` in `FirebaseAuthRepository` using `switchMap` to merge identity and profile snapshots.
- [x] Update `FirebaseAuthRepository` to coordinate between `FirebaseIdentityProvider`, `FirestoreProfileProvider`, and `AuthUserProfileStore`.
- [x] Implement the "Offline Session Restore" logic in the repository, checking `AuthFreshnessPolicy` and local cache.

## Phase 4: BLoC Integration & Security Gates (P0)
- [x] Update `AuthBloc` to listen to the new repository `userStream`.
- [x] Wire `AuthFreshnessPolicy` into `AuthEventCheckStatus` as a hard security gate.
- [x] Implement `AuthEventRefreshUser` to trigger explicit `forceRefresh` in the repository/provider.
- [x] Ensure `AuthBloc` emits `AuthUnauthenticated` if the freshness policy is violated (offline > 24h).

## Phase 5: Finalization & Documentation
- [x] Update any README.md file for the package with relevant information from the modification.
- [x] Update any GEMINI.md file in the project directory to reflect the new auth architecture.
- [x] Run final verification tools (`dart_fix`, `analyze_files`, `tests`, `dart_format`).
- [x] Ask the user to inspect the package and confirm satisfaction.

## Post-Phase Checklist (to be run after each phase)
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Re-read the `MODIFICATION_IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan.
- [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state in the Journal.
- [x] Use `git diff` to verify changes and propose a commit message to the user.
- [x] Wait for approval before committing and moving to the next phase.
- [x] After committing, use `hot_reload` if an app is running.

## Journal
- **Initial State:** Research completed, design approved. Branch `feature/auth-architectural-fixes` created.
- **Phase 1 Log:** Ran tests. Fixed `AttendanceTakingCubit` bugs, mocktail matching errors, and `AttendanceInsight` const constructors to stabilize baseline. Tests passed.
- **Phase 2 Log:** Split `FirebaseAuthProvider` into `FirebaseIdentityProvider` and `FirestoreProfileProvider` implementing hybrid cache with TTL. Updated `AuthUserProfileStore` to support cache-only fetching.
- **Phase 3 Log:** Refactored `FirebaseAuthRepository` to expose a reactive `userStream` merging identity and profile data using `switchMap`. Implemented offline fallback block based on `AuthFreshnessPolicy`.
- **Phase 4 Log:** Updated `AuthBloc` to listen to `userStream`. Removed old `FirebaseAuthProvider` and cleaned up dependency injection (DI). Fixed all related test compilation errors. Tests passing.
- **Phase 5 Log:** Verified final changes. Updated implementation log and prepared commit. Code formatting and static analysis are complete.

---
*Note: After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks so that you can come back and complete them later.*
