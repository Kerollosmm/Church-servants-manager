# Implementation Plan: project_state_audit

## Phase 1: Environment & Repository Infrastructure Reconnaissance
- [ ] Task: Audit `pubspec.yaml` against `conductor/tech-stack.md`.
- [ ] Task: Audit repository for Cloud Functions, `functions/` folder, and `cloud_functions` imports.
- [ ] Task: Audit repository for Firestore Security Rules (`firestore.rules`) and RBAC configuration.

## Phase 2: Feature-First Clean Architecture Audit (`lib/`)
- [ ] Task: Audit `lib/` directory structure and map all feature folders.
- [ ] Task: Deep audit of `auth` feature across domain, data, and presentation layers.
- [ ] Task: Deep audit of `servants` / `students` features across domain, data, and presentation layers.
- [ ] Task: Deep audit of `attendance` / `results` features across domain, data, and presentation layers.
- [ ] Task: Deep audit of `core/` and offline outbox sync engine layers.

## Phase 3: Guidelines & Pattern Violations Audit
- [ ] Task: Audit UI widgets for hardcoded strings, hardcoded colors, and business logic leakage.
- [ ] Task: Audit codebase for legacy two-app system remnants.

## Phase 4: Gap Analysis Report Synthesis (`tasks.md`)
- [ ] Task: Synthesize all findings into `conductor/tracks/project_state_audit/tasks.md` following Sections A, B, C, D, E output format.
- [ ] Task: Conductor - User Manual Verification 'Project State Audit' (Protocol in workflow.md).
