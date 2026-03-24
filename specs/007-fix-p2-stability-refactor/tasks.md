# Tasks: Fix P2 Stability and Correctness Issues

**Input**: Design documents from `/specs/007-fix-p2-stability-refactor/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Tests are not explicitly requested in the specification, but verification steps are included in the implementation guide.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and environment verification

- [ ] T001 Verify active branch is `007-fix-p2-stability-refactor`
- [ ] T002 [P] Run `flutter pub get` to ensure dependencies are resolved

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure updates

- [ ] T003 Reorder registrations in `lib/core/di/injection.dart` so `StudentLinkedUserSyncService` precedes `StudentDataRepository`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Optimized UI Performance (Priority: P1) 🎯 MVP

**Goal**: Implement value-based equality for `TeamMembersState` to prevent redundant UI rebuilds.

**Independent Test**: Verify that emitting a new state with identical data to the previous state does not trigger a rebuild in the UI.

### Implementation for User Story 1

- [ ] T004 [US1] Implement `Equatable` or override `==` and `hashCode` for `TeamMembersState` in `lib/features/team/presentation/cubit/team_members_state.dart`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently.

---

## Phase 4: User Story 2 - Robust Dependency Injection (Priority: P2)

**Goal**: Standardize Cubit registration and usage via DI container.

**Independent Test**: Confirm `TeamCubit` is correctly provided by `getIt` and the app initializes without errors.

### Implementation for User Story 2

- [ ] T005 [US2] Register `TeamCubit` as a factory in `lib/core/di/injection.dart`
- [ ] T006 [US2] Update `lib/features/students/presentation/coordinator/student_management_coordinator.dart` to resolve `TeamCubit` via `getIt` instead of manual instantiation

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently.

---

## Phase 5: User Story 3 - Maintainable Codebase (Priority: P3)

**Goal**: Consolidate validation logic and enforce strict dependency injection in BLoCs.

**Independent Test**: Verify shared logic usage in `Validators` and ensured compile-time safety for `StudentDataBloc` dependencies.

### Implementation for User Story 3

- [ ] T007 [US3] Extract shared validation logic to `_validate` internal helper in `lib/core/utils/validators.dart`
- [ ] T008 [US3] Refactor English and Arabic validators to use the `_validate` helper in `lib/core/utils/validators.dart`
- [ ] T009 [US3] Make all use case parameters required and remove fallback constructor logic in `lib/features/students/presentation/bloc/student_data_bloc.dart`

**Checkpoint**: All user stories should now be independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final audit and quality checks

- [ ] T010 [P] Run `dart format .` and `dart fix --apply`
- [ ] T011 Run `flutter test` to ensure no regressions were introduced
- [ ] T012 Verify all P2 stability issues identified in the code review are resolved

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup.
- **User Stories (Phase 3+)**: All depend on Phase 2 completion.
- **Polish (Final Phase)**: Depends on all user stories completion.

### Parallel Opportunities

- T002 [P] and T001 can start together.
- T004 [US1], T005 [US2], and T007 [US3] can potentially start in parallel as they touch different files (though Phase order is recommended).
- T010 [P] can run while reviewing other tasks.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 & 2.
2. Complete Phase 3 (US1).
3. **STOP and VALIDATE**: Verify performance improvement in `TeamMembersState`.

### Incremental Delivery

1. Foundation ready.
2. Deliver US1 (Performance).
3. Deliver US2 (DI Reliability).
4. Deliver US3 (Maintenance).
5. Final Polish.
