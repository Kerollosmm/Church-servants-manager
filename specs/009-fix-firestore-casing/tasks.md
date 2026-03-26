# Tasks: Fix Firestore Collection Casing

**Input**: Design documents from `/specs/009-fix-firestore-casing/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/firestore-collection-paths.md`, `quickstart.md`

**Tests**: Validation is explicitly requested for this feature, so analysis and existing repository test execution are included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. `US1`, `US2`, `US3`)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm scope and collect the in-scope Firestore path literals before editing.

- [X] T001 Search for quoted Firestore path literals `Users`, `Students`, and `Classes` across `C:\Users\KimoStore\church_managment_system\lib`, `C:\Users\KimoStore\church_managment_system\functions`, `C:\Users\KimoStore\church_managment_system\test`, and `C:\Users\KimoStore\church_managment_system\firestore.indexes.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the canonical lowercase path contract that all consumers must follow.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 Update Firestore collection string values to lowercase in `C:\Users\KimoStore\church_managment_system\lib\core\constants\firestore_collections.dart`

**Checkpoint**: Shared collection constants now define the lowercase canonical contract.

---

## Phase 3: User Story 1 - Restore authorized data access (Priority: P1) 🎯 MVP

**Goal**: Ensure all in-scope production Firestore path consumers use the lowercase canonical names so protected data access aligns with rules.

**Independent Test**: Repo-wide search of production code and backend config shows no remaining in-scope `Users`, `Students`, or `Classes` Firestore path literals, and all canonical lookups resolve to lowercase names.

### Implementation for User Story 1

- [X] T003 [US1] Normalize any hardcoded Firestore path literals in repository and service files under `C:\Users\KimoStore\church_managment_system\lib\features\**\data\**` that still use `Users`, `Students`, or `Classes`
- [X] T004 [P] [US1] Normalize the backend Firestore collection constant in `C:\Users\KimoStore\church_managment_system\functions\src\index.ts`
- [X] T005 [P] [US1] Normalize Firestore collection group names in `C:\Users\KimoStore\church_managment_system\firestore.indexes.json`
- [X] T006 [US1] Re-run a repo-wide search for quoted `Users`, `Students`, and `Classes` Firestore path literals to verify no in-scope production matches remain under `C:\Users\KimoStore\church_managment_system\lib`, `C:\Users\KimoStore\church_managment_system\functions`, and `C:\Users\KimoStore\church_managment_system\firestore.indexes.json`

**Checkpoint**: User Story 1 is complete when all production path consumers use lowercase collection names.

---

## Phase 4: User Story 2 - Preserve existing feature behavior (Priority: P2)

**Goal**: Prove the casing fix does not break compilation or existing repository behavior.

**Independent Test**: Static analysis passes and existing Firestore-heavy repository tests continue passing after the path normalization.

### Tests for User Story 2 ⚠️

- [X] T007 [P] [US2] Normalize hardcoded Firestore path literals in `C:\Users\KimoStore\church_managment_system\test\features\team\data\repos\team_repository_test.dart`
- [X] T008 [P] [US2] Normalize hardcoded Firestore path literals in `C:\Users\KimoStore\church_managment_system\test\features\attendance\data\repos\attendance_repository_test.dart`
- [X] T009 [US2] Run `flutter analyze` from `C:\Users\KimoStore\church_managment_system` to confirm the lowercase path changes compile cleanly
- [X] T010 [US2] Run `flutter test test/features/team/data/repos/team_repository_test.dart test/features/attendance/data/repos/attendance_repository_test.dart` from `C:\Users\KimoStore\church_managment_system` to confirm no repository regressions

**Checkpoint**: User Story 2 is complete when analysis and existing repository tests pass with the updated path values.

---

## Phase 5: User Story 3 - Keep scope controlled (Priority: P3)

**Goal**: Confirm the delivered change stays limited to Firestore path string normalization with no identifier churn.

**Independent Test**: Final review shows only string value changes for Firestore collection paths and direct literals, while existing class and member names remain unchanged.

### Implementation for User Story 3

- [X] T011 [US3] Review the final diff in `C:\Users\KimoStore\church_managment_system\lib\core\constants\firestore_collections.dart`, `C:\Users\KimoStore\church_managment_system\functions\src\index.ts`, `C:\Users\KimoStore\church_managment_system\firestore.indexes.json`, and updated repository/test files to confirm only Firestore path string values changed
- [X] T012 [US3] Run the quickstart validation checklist from `C:\Users\KimoStore\church_managment_system\specs\009-fix-firestore-casing\quickstart.md` and record any deviations before completion

**Checkpoint**: All user stories are independently functional and the fix remains surgically scoped.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final confirmation across all affected areas.

- [X] T013 [P] Perform a final repo-wide search from `C:\Users\KimoStore\church_managment_system` to confirm no in-scope quoted `Users`, `Students`, or `Classes` Firestore path literals remain

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; starts immediately.
- **Foundational (Phase 2)**: Depends on Phase 1; establishes the canonical shared contract.
- **User Story 1 (Phase 3)**: Depends on Phase 2.
- **User Story 2 (Phase 4)**: Depends on User Story 1 because validation should run after all production and test path literals are normalized.
- **User Story 3 (Phase 5)**: Depends on User Story 2.
- **Polish (Phase 6)**: Depends on all user stories.

### User Story Dependencies

- **US1 (P1)**: Starts after foundational work; no dependency on other stories.
- **US2 (P2)**: Depends on US1 because it validates the implemented path normalization.
- **US3 (P3)**: Depends on US2 because scope review is meaningful only after implementation and validation complete.

### Within Each User Story

- Search/inventory before edits.
- Shared constants before consumer updates.
- Production path normalization before analysis and test execution.
- Test fixture normalization before running repository tests.
- Final diff review after all automated validation passes.

### Parallel Opportunities

- T004 and T005 can run in parallel after T003 starts because they touch separate files.
- T007 and T008 can run in parallel because they update different test files.
- T013 can be executed independently as the final validation sweep.

---

## Parallel Example: User Story 1

```bash
# Parallelizable normalization tasks after repository/service literal sweep begins:
Task: "Normalize the backend Firestore collection constant in C:\Users\KimoStore\church_managment_system\functions\src\index.ts"
Task: "Normalize Firestore collection group names in C:\Users\KimoStore\church_managment_system\firestore.indexes.json"
```

---

## Parallel Example: User Story 2

```bash
# Parallelizable test-fixture normalization tasks:
Task: "Normalize hardcoded Firestore path literals in C:\Users\KimoStore\church_managment_system\test\features\team\data\repos\team_repository_test.dart"
Task: "Normalize hardcoded Firestore path literals in C:\Users\KimoStore\church_managment_system\test\features\attendance\data\repos\attendance_repository_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Stop and verify that all production path consumers use lowercase collection names

### Incremental Delivery

1. Establish lowercase canonical constants
2. Normalize production consumers and backend/index config
3. Normalize repository test fixtures and run validation
4. Perform final scope-control review and repo-wide search

### Parallel Team Strategy

With multiple developers:

1. One developer updates shared constants and repository/service literals
2. One developer updates `functions/src/index.ts` and `firestore.indexes.json`
3. One developer updates repository test fixtures
4. A final pass runs analysis, tests, and scope review sequentially

---

## Notes

- All tasks follow the required checklist format.
- Tasks marked `[P]` touch separate files and can be executed in parallel.
- User story labels map directly to the stories in `spec.md`.
- The suggested MVP scope is **User Story 1 only**.
