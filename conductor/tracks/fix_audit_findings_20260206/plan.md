# Implementation Plan: Resolve Audit Report Findings

## Phase 1: Foundation & Security Hardening
Establish the local storage infrastructure and fix critical authentication gaps.

- [ ] Task: Initialize Hive Infrastructure
    - [ ] Add Hive initialization and PathProvider setup to `main.dart`.
    - [ ] Create Hive constants for box names.
- [x] Task: Centralize Auth Error Mapping (TDD) (8b2fd07)
    - [x] Write tests for mapping specific `FirebaseAuthException` codes to domain `AuthFailure`.
    - [x] Update `FirebaseAuthProvider` to propagate rich error information.
- [ ] Task: Auth Caching & Session Hardening (TDD)
    - [ ] Implement local caching for `AuthUser` in `FirebaseAuthProvider`.
    - [ ] Fix N+1 issue in `authStateChanges` by checking cache before fetching from Firestore.
- [ ] Task: Domain-Level Input Validation (TDD)
    - [ ] Create reusable `Validator` classes in `lib/core/utils/`.
    - [ ] Implement business-rule validation for Registration and Student forms.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Foundation' (Protocol in workflow.md)

## Phase 2: Data Models & Versioning
Prepare the data models for offline persistence and sequential versioning.

- [ ] Task: Enhance StudentModel for Sync (TDD)
    - [ ] Update `StudentModel` with `version` (int) and `updatedAt` (DateTime).
    - [ ] Add `@HiveType` and `@HiveField` annotations to `StudentModel` and `AuthUser`.
- [ ] Task: Run Code Generation
    - [ ] Execute `dart run build_runner build --delete-conflicting-outputs` to generate Hive adapters.
    - [ ] Register Hive adapters in `main.dart`.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Models' (Protocol in workflow.md)

## Phase 3: Sync Layer Implementation
Build the core synchronization logic to bridge local and remote data sources.

- [ ] Task: Create StudentLocalDataSource (TDD)
    - [ ] Implement Hive-based storage methods for students.
- [ ] Task: Implement StudentSyncRepository (TDD)
    - [ ] Orchestrate data flow between Hive and Firestore.
    - [ ] Implement "Fetch-Then-Cache" logic.
    - [ ] Implement Sequential Versioning conflict resolution (Last-Write-Wins or Version check).
- [ ] Task: Background Sync & Dual-Write Hardening (TDD)
    - [ ] Refactor `StudentDataRepository` to use the new Sync Layer.
    - [ ] Implement retry logic or a sync queue for offline writes.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Sync Layer' (Protocol in workflow.md)

## Phase 4: UI Performance & Pagination
Optimize the user experience for large datasets and slow connections.

- [ ] Task: Implement Pagination in Repository (TDD)
    - [ ] Update `getAllStudents` to support `DocumentSnapshot` cursors.
- [ ] Task: Refactor StudentDataBloc for Pagination (TDD)
    - [ ] Add `StudentsLoadMoreRequested` event.
    - [ ] Implement state management for paginated lists.
- [ ] Task: Infinite Scrolling & Search Refactor (TDD)
    - [ ] Update `StudentManagementScreen` to use `ScrollController` for infinite scroll.
    - [ ] Remove search result hardcap and enable pagination for search.
- [ ] Task: Implement Image Caching
    - [ ] Replace `Image.network` with `CachedNetworkImage` in student cards/details.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: UI Performance' (Protocol in workflow.md)

## Phase 5: Routing & Final Audit
Final architectural cleanup and verification against the Audit Report.

- [ ] Task: Refactor AppRouter (TDD)
    - [ ] Implement a factory pattern or declarative routing (e.g., `go_router`) to simplify argument passing.
- [ ] Task: Final Quality Gate & Audit Verification
    - [ ] Verify every item in `AUDIT_REPORT.md` is addressed.
    - [ ] Ensure >80% coverage on new Sync and Validation logic.
    - [ ] Run `dart analyze` to ensure zero warnings.
- [ ] Task: Conductor - User Manual Verification 'Phase 5: Final Audit' (Protocol in workflow.md)
