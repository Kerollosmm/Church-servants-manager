---
description: "Task list for P1 stability fixes implementation"
---

# Tasks: Fix P1 Stability Issues

**Input**: Design documents from `/specs/006-fix-p1-stability/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- File paths are relative to repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and environment verification

- [ ] T001 [P] Verify project dependencies and Flutter version in `pubspec.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core dependency verification before refactoring

- [ ] T002 [P] Verify `getIt` registration for all required Student use cases in `lib/core/di/injection.dart`
- [ ] T003 [P] Verify `getIt` registration for `AppRouter` in `lib/core/di/injection.dart`

---

## Phase 3: User Story 1 - Consistent Dependency Resolution (Priority: P1) 🎯 MVP

**Goal**: Resolve all application dependencies using a single, consistent mechanism to prevent initialization errors.

**Independent Test**: Navigate to all student-related screens and verify no dependency resolution errors occur.

### Tests for User Story 1

- [ ] T004 [P] [US1] Create regression test for `AppRouter` screen navigation and dependency resolution in `test/core/routing/app_router_test.dart`

### Implementation for User Story 1

- [ ] T005 [US1] Refactor `_withStudentDataBloc` to use `getIt` for all use case dependencies in `lib/core/routing/app_router.dart`
- [ ] T006 [US1] Remove redundant `context` parameter from `_withStudentDataBloc` and its callers in `lib/core/routing/app_router.dart`

**Checkpoint**: User Story 1 verified with independent tests.

---

## Phase 4: User Story 2 - Safe Role-Based Routing (Priority: P1)

**Goal**: Handle account status transitions gracefully using type-safe pattern matching.

**Independent Test**: Mock `AuthDegraded` and `AuthAuthenticated` states and verify correct screen resolution.

### Tests for User Story 2

- [ ] T007 [P] [US2] Create unit test for `RoleRouter.resolve` covering all `AuthState` sealed types in `test/core/routing/role_router_test.dart`

### Implementation for User Story 2

- [ ] T008 [US2] Replace unsafe cast with Dart 3 pattern matching in `RoleRouter.resolve` in `lib/core/routing/role_router.dart`
- [ ] T009 [US2] Add safe fallback for unexpected state types returning `SizedBox.shrink()` in `lib/core/routing/role_router.dart`

**Checkpoint**: User Story 2 verified with independent tests.

---

## Phase 5: User Story 3 - Atomic Attendance Processing (Priority: P1)

**Goal**: Eliminate race conditions in attendance marking using the state-snapshot pattern.

**Independent Test**: Simulate rapid stream updates during a mutation and verify that `mutationError` and `isMutating` state are correctly preserved.

### Tests for User Story 3

- [ ] T010 [P] [US3] Create unit test for `AttendanceTakingCubit` simulating rapid server snapshots during local mutations in `test/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit_test.dart`

### Implementation for User Story 3

- [ ] T011 [US3] Implement state-snapshot pattern in `AttendanceTakingCubit._runMutation` to capture state before `await` in `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`
- [ ] T012 [US3] Ensure final state emission uses the latest available state while applying mutation results in `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`

**Checkpoint**: User Story 3 verified with independent tests.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and code quality enforcement

- [ ] T013 [P] Run `flutter analyze` and resolve any type safety or lint issues
- [ ] T014 [P] Run `dart format .` to ensure consistent project styling
- [ ] T015 Run final manual verification of all P1 fixes per `specs/006-fix-p1-stability/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 & 2** are prerequisites for all subsequent work.
- **Phase 3 (US1)**, **Phase 4 (US2)**, and **Phase 5 (US3)** are mutually independent and can be implemented in parallel.
- **Phase 6** depends on all implementation phases.

### Parallel Opportunities
- T004, T007, and T010 (all test creations) can run in parallel.
- Phases 3, 4, and 5 can be worked on concurrently if multiple developers are available.

---

## Implementation Strategy

### MVP First
1. Complete Setup and Foundational phases.
2. Complete Phase 3 (US1) to ensure core navigation stability.
3. Validate US1 before proceeding.

### Incremental Delivery
1. Deliver US1 (Core DI Stability).
2. Deliver US2 (Routing Safety).
3. Deliver US3 (Data Integrity).
Each increment is independently testable and adds production stability.
