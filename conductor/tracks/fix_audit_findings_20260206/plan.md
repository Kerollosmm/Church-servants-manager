# Implementation Plan: Resolve Audit Report Findings (Cloud-First)

## Phase 1: Security & Auth Hardening
Establish the local storage infrastructure and fix critical authentication gaps.

- [x] Task: Centralize Auth Error Mapping (TDD) (8b2fd07)
    - [x] Write tests for mapping specific `FirebaseAuthException` codes to domain `AuthFailure`.
    - [x] Update `FirebaseAuthProvider` to propagate rich error information.
- [x] Task: Auth Caching & Session Hardening (TDD) (58725db)
    - [x] Implement local caching for `AuthUser` in `FirebaseAuthProvider`.
    - [x] Fix N+1 issue in `authStateChanges` by checking cache before fetching from Firestore.
- [x] Task: Domain-Level Input Validation (TDD) (12dba48)
    - [x] Create reusable `Validator` classes in `lib/core/utils/`.
    - [x] Implement business-rule validation for Registration and Student forms.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Security' (Protocol in workflow.md)

## Phase 2: Performance & Pagination
Optimize the UI for data efficiency and responsiveness.

- [ ] Task: Infinite Scroll in Repository (TDD)
    - [ ] Update `getAllStudents` to support cursor-based pagination.
- [ ] Task: Refactor StudentDataBloc for Pagination (TDD)
    - [ ] Implement `StudentsLoadMoreRequested` and paginated state management.
- [ ] Task: Infinite Scrolling & Search Refactor (TDD)
    - [ ] Add `ScrollController` to `StudentManagementScreen` for loading more data.
    - [ ] Enable pagination for search results.
- [ ] Task: Implement Network Image Caching
    - [ ] Replace standard images with `CachedNetworkImage` for profile pictures.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Performance' (Protocol in workflow.md)

## Phase 3: Architecture & Final Polish
Final architectural cleanup and verification against the Audit Report.

- [ ] Task: Refactor AppRouter (TDD)
    - [ ] Implement a more declarative or modular routing system.
- [ ] Task: Final Quality Gate & Audit Verification
    - [ ] Verify every non-DB item in `AUDIT_REPORT.md` is resolved.
    - [ ] Ensure >80% coverage on new logic.
    - [ ] Run `dart analyze` to ensure zero warnings.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Final Audit' (Protocol in workflow.md)


