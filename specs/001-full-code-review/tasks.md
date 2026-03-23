# Tasks: Full Code Review

**Input**: Design documents from `/specs/001-full-code-review/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Review task is read-only; verification tasks focus on report generation validity.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `lib/`, `tests/` at repository root
- **Review output**: `docs/review/`, `docs/review/annotated/`
- Paths below reflect the feature-first vertical slice structure

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Initialize review directory structure in `docs/review/`
- [x] T002 [P] Create review context templates and headers in `docs/review/templates/`
- [x] T003 [P] Configure pre-review linter scan in `analysis_options.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Map and index all vertical feature slices in `lib/features/`
- [x] T005 [P] Create feature-specific report placeholders in `docs/review/features/`
- [x] T006 [P] Scan all human-written Dart files in `lib/` excluding generated code (`*.g.dart`, `*.freezed.dart`)

**Checkpoint**: Foundation ready - feature-specific review implementation can now begin

---

## Phase 3: User Story 1 - Produce Feature-Specific Review Reports (Priority: P1) 🎯 MVP

**Goal**: Generate high-level review findings for each vertical slice of the application

**Independent Test**: Verify that `docs/review/features/` contains report files for each slice with P0/P1/P2 issues identified

### Implementation for User Story 1

- [x] T007 [P] [US1] Perform deep-reasoning analysis of `lib/features/auth/` and generate `docs/review/features/auth_report.md`
- [x] T008 [P] [US1] Perform deep-reasoning analysis of `lib/features/attendance/` and generate `docs/review/features/attendance_report.md`
- [x] T009 [P] [US1] Perform deep-reasoning analysis of `lib/features/students/` and generate `docs/review/features/students_report.md`
- [x] T010 [P] [US1] Perform deep-reasoning analysis of `lib/features/servants/` and generate `docs/review/features/servants_report.md`
- [x] T011 [P] [US1] Perform deep-reasoning analysis of `lib/features/teams/` and generate `docs/review/features/teams_report.md`
- [x] T012 [P] [US1] Perform deep-reasoning analysis of `lib/core/` infrastructure and generate `docs/review/features/core_report.md`

**Checkpoint**: At this point, User Story 1 should provide a complete high-level overview of technical debt

---

## Phase 4: User Story 2 - Annotated Source Deepthink (Priority: P1)

**Goal**: Generate line-by-line annotated source code with inline reasoning and issue identification

**Independent Test**: Verify that `docs/review/annotated/` contains mirrored source files with `// [DEEPTHINK]` annotations

### Implementation for User Story 2

- [x] T013 [P] [US2] Generate annotated source for `lib/features/auth/` in `docs/review/annotated/features/auth/`
- [x] T014 [P] [US2] Generate annotated source for `lib/features/attendance/` in `docs/review/annotated/features/attendance/`
- [x] T015 [P] [US2] Generate annotated source for `lib/features/students/` in `docs/review/annotated/features/students/`
- [x] T016 [P] [US2] Generate annotated source for `lib/features/servants/` in `docs/review/annotated/features/servants/`
- [x] T017 [P] [US2] Generate annotated source for `lib/features/teams/` in `docs/review/annotated/features/teams/`
- [x] T018 [P] [US2] Generate annotated source for `lib/core/` in `docs/review/annotated/core/`

**Checkpoint**: User Story 2 provides the granular "why" behind every identified issue

---

## Phase 5: User Story 3 - Unified Remediation Roadmap (Priority: P1)

**Goal**: Consolidate all findings into a prioritized, sprint-based master fix plan

**Independent Test**: Verify that `docs/review/MASTER_FIX_PLAN.md` exists and contains 3 sprints mapped to issue severity

### Implementation for User Story 3

- [x] T019 [US3] Extract P0 issues from all reports into Sprint 1 of `docs/review/MASTER_FIX_PLAN.md`
- [x] T020 [US3] Extract P1 issues from all reports into Sprint 2 of `docs/review/MASTER_FIX_PLAN.md`
- [x] T021 [US3] Extract P2 issues from all reports into Sprint 3 of `docs/review/MASTER_FIX_PLAN.md`
- [x] T022 [US3] Finalize unified roadmap with estimated remediation approaches in `docs/review/MASTER_FIX_PLAN.md`

**Checkpoint**: All findings are now actionable and scheduled

---

## Phase 6: User Story 4 - Migration to GoRouter (Priority: P1)

**Goal**: Transition navigation from manual Navigator 1.0 to declarative GoRouter

- [x] T025 Define route constants and typed paths in `lib/core/routing/app_routes.dart`
- [x] T026 Implement `GoRouter` configuration with role-based redirects in `lib/core/routing/app_router.dart`
- [x] T027 Migrate `MaterialApp` to `MaterialApp.router` in `lib/church_app.dart`
- [x] T028 Update all navigation calls from `Navigator` to `context.go()` or `context.push()`

---

## Phase 7: User Story 5 - Localization Implementation (Priority: P1)

**Goal**: Centralize all UI strings in ARB files for multi-language support

- [ ] T029 Configure `l10n.yaml` and initialize `lib/l10n/` directory structure
- [ ] T030 Extract hardcoded Arabic strings to `lib/l10n/app_ar.arb`
- [ ] T031 Implement base English translations in `lib/l10n/app_en.arb`
- [ ] T032 Update all UI components to use `AppLocalizations.of(context)`

---

## Phase 8: User Story 6 - Final Cleanup & Dead Code (Priority: P2)

**Goal**: Remove technical debt and unused artifacts

- [ ] T033 Run `dart fix --apply` to resolve automatic lint issues
- [ ] T034 Remove unused imports, variables, and identified dead code blocks
- [ ] T035 Perform final verification build and verify all tests pass

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation

- [x] T023 [P] Update root `README.md` with links to all generated review artifacts
- [x] T024 Perform final structural validation of all review files in `docs/review/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Phase 1 completion
- **User Stories (Phases 3-5)**: All depend on Phase 2 completion
- **Polish (Final Phase)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (Reports)**: Independent after Phase 2
- **US2 (Annotated)**: Independent after Phase 2 (can run in parallel with US1)
- **US3 (Master Plan)**: Depends on US1 completion to have issues to consolidate
- **US4 (GoRouter)**: Depends on Phase 2; involves structural changes to routing
- **US5 (Localization)**: Independent after Phase 2; cross-cutting UI updates
- **US6 (Cleanup)**: Should run last to ensure all new code is also linted and cleaned

### Parallel Opportunities

- T007-T012 can run in parallel (different feature slices)
- T013-T018 can run in parallel (different annotated slices)
- T025-T028 can run in parallel with US5 tasks
- Phases 3 and 4 can run concurrently

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 & 2
2. Complete Phase 3 (Feature Reports)
3. STOP: Validate that we have a high-level list of all bugs and architectural violations

### Incremental Delivery

1. Foundation ready
2. Add high-level reports (US1)
3. Add deepthink annotations (US2)
4. Consolidate into Master Plan (US3)
5. Each increment adds depth and actionability to the review

---

## Notes

- [P] tasks can run in parallel across different feature directories
- All annotations must use `// [DEEPTHINK]` or `// [ISSUE:PX]` syntax
- NO changes to production code in `lib/` are permitted
