# Implementation Plan: Project-Wide Elite Code Review & Refactor

## Phase 1: Deep Discovery & Audit Reporting
Focus on identifying issues across the codebase and documenting them for targeted fixes.

- [x] Task: Project-Wide Contextual Audit (d4b422e)
    - [x] Run `dart analyze` and record all current warnings/errors.
    - [x] Audit `lib/core/` for theme consistency and architectural leaks.
    - [x] Audit `lib/features/auth/` for security and session robustness.
    - [x] Audit `lib/features/student/` for sync logic and model integrity.
- [ ] Task: Performance & Sync Profiling
    - [ ] Profile startup time and list scrolling in the Student Directory.
    - [ ] Analyze Hive/Firestore synchronization edge cases (e.g., conflicting updates).
- [ ] Task: Generate `AUDIT_REPORT.md`
    - [ ] Document all findings categorized by Security, Performance, Logic, and Architecture.
    - [ ] Prioritize issues (Critical, Major, Minor).
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Discovery' (Protocol in workflow.md)

## Phase 2: Infrastructure & Auth Hardening
Resolve core issues and stabilize the authentication layer.

- [ ] Task: Refactor Core Infrastructure (TDD)
    - [ ] Standardize Theme/Typography access across the app.
    - [ ] Clean up redundant or inconsistent core widgets.
- [ ] Task: Harden Auth Feature (TDD)
    - [ ] Fix identified session management bugs.
    - [ ] Improve error handling and user feedback in login/signup flows.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Core & Auth' (Protocol in workflow.md)

## Phase 3: Student Module & Sync Reliability
Focus on the most complex feature and ensure data integrity.

- [ ] Task: Refactor Student Data Layer (TDD)
    - [ ] Realign models with Freezed/JSON best practices.
    - [ ] Fix logic errors in Student Repository and Data Sources.
- [ ] Task: Optimize Sync Mechanism (TDD)
    - [ ] Implement robust conflict resolution for Hive/Firestore.
    - [ ] Add background sync improvements.
- [ ] Task: Refactor Student UI (TDD)
    - [ ] Optimize widget rebuilds in the directory and attendance lists.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Student & Sync' (Protocol in workflow.md)

## Phase 4: Global Optimizations & Final Checks
Final polishing and verification of the entire system.

- [ ] Task: Global Performance Tuning
    - [ ] Apply final "Senior Level" optimizations based on audit findings.
    - [ ] Ensure all code generation is up to date and conflict-free.
- [ ] Task: Final Quality Gate Verification
    - [ ] Verify >80% code coverage across refactored modules.
    - [ ] Ensure `dart analyze` is perfectly clean.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Final Audit' (Protocol in workflow.md)
