# Tasks: Fix Attendance Mark Document ID

**Input**: Design documents from `/specs/010-fix-attendance-mark-id/`
**Prerequisites**: `specs/010-fix-attendance-mark-id/plan.md`, `specs/010-fix-attendance-mark-id/spec.md`, `specs/010-fix-attendance-mark-id/research.md`, `specs/010-fix-attendance-mark-id/data-model.md`, `specs/010-fix-attendance-mark-id/contracts/`

**Tests**: Test coverage is required for this feature because the user explicitly requested a unit test for repeated marking and the spec requires regression verification of the attendance flow.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Every task includes an exact file path or scoped project path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Load the feature documents and confirm the implementation surface before editing code.

- [X] T001 Review `specs/010-fix-attendance-mark-id/spec.md`, `specs/010-fix-attendance-mark-id/plan.md`, and `specs/010-fix-attendance-mark-id/research.md` to confirm the idempotent mark-ID rules
- [X] T002 Inspect `lib/features/attendance/data/repos/attendance_repository.dart` and `test/features/attendance/data/repos/attendance_repository_test.dart` to locate the `saveAttendanceMark` equivalent and current mark-ID test coverage

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Confirm the shared implementation constraints that apply to all user stories.

**⚠️ CRITICAL**: No user story work should start until this verification is complete.

- [X] T003 Verify `lib/features/attendance/data/repos/attendance_repository.dart` still uses `SetOptions(merge: true)` for mark upserts and retain or restore that behavior if it has drifted
- [X] T004 [P] Search `lib/` and `test/` for `AttendanceRecordHive`, `SyncQueueItemHive`, and related attendance offline persistence types, then identify the exact file path to update for local `recordId = studentId` handling (no matching types exist in the current source tree)

**Checkpoint**: Repository upsert behavior and local persistence touchpoints are confirmed.

---

## Phase 3: User Story 1 - Record One Mark Per Student Per Session (Priority: P1) 🎯 MVP

**Goal**: Ensure recording attendance for a student always targets a single canonical mark document keyed by `studentId`.

**Independent Test**: Mark the same student twice in the same session and confirm the marks collection contains exactly one document whose ID is the student ID.

### Tests for User Story 1

- [X] T005 [P] [US1] Add or update the repeated-mark regression test in `test/features/attendance/data/repos/attendance_repository_test.dart` so marking the same student twice leaves exactly one Firestore mark document with ID `student-1`

### Implementation for User Story 1

- [X] T006 [US1] Update the mark write path in `lib/features/attendance/data/repos/attendance_repository.dart` so the `saveAttendanceMark` equivalent resolves the document with `doc(mark.studentId)` or the repository's equivalent student-keyed document reference
- [X] T007 [US1] Add fix traceability comments in `lib/features/attendance/data/repos/attendance_repository.dart` on the attendance mark identity lines changed for Task T006
- [X] T008 [US1] Run `flutter test test/features/attendance/data/repos/attendance_repository_test.dart` to verify the repeated-mark idempotency test passes

**Checkpoint**: User Story 1 should now guarantee one mark document per student per session.

---

## Phase 4: User Story 2 - Correct a Student's Mark Without Duplicates (Priority: P2)

**Goal**: Ensure re-marking the same student updates the existing record without changing attendance status rules or timestamp merge behavior.

**Independent Test**: Change a student's mark within the same session and confirm the same document is updated, the status changes, and no duplicate record is created.

### Tests for User Story 2

- [X] T009 [P] [US2] Extend `test/features/attendance/data/repos/attendance_repository_test.dart` with a regression case that re-marks the same student with a different status and confirms the same document is updated instead of duplicated

### Implementation for User Story 2

- [X] T010 [US2] Preserve merge-based idempotent writes in `lib/features/attendance/data/repos/attendance_repository.dart` while updating the student-keyed mark document so status changes remain update-in-place behavior
- [X] T011 [US2] Verify the mark mapping logic in `lib/features/attendance/data/models/attendance_mark.dart` still derives `studentId` from the mark document identity after the repository update
- [X] T012 [US2] Run `flutter test test/features/attendance/data/repos/attendance_repository_test.dart` to verify correction and idempotent upsert behavior for present/late re-marking

**Checkpoint**: User Stories 1 and 2 should both work independently with one authoritative mark per student and session.

---

## Phase 5: User Story 3 - Preserve Offline and Sync Workflow Behavior (Priority: P3)

**Goal**: Keep local attendance identity and queue correlation behavior aligned with the server-side mark identity without changing Cubit/UI workflow behavior.

**Independent Test**: Confirm any local attendance record uses `studentId` as `recordId`, queue IDs remain separate, and attendance-taking state flow still works without new UI behavior.

### Tests for User Story 3

- [X] T013 [P] [US3] Add or update targeted tests in the exact file identified by Task T004 so local attendance record creation asserts `recordId = studentId` and queue correlation IDs remain independently generated (not applicable because no matching Hive persistence types exist in the current source tree)

### Implementation for User Story 3

- [X] T014 [US3] Update the `AttendanceRecordHive` creation path in the exact file identified by Task T004 so `recordId` is assigned from `studentId` instead of a generated UUID (not applicable because no `AttendanceRecordHive` exists in the current source tree)
- [X] T015 [US3] Verify the `SyncQueueItemHive` creation path in the exact file identified by Task T004 still uses a unique generated `recordId` only for queue correlation and does not replace attendance business identity (not applicable because no `SyncQueueItemHive` exists in the current source tree)
- [X] T016 [US3] Review `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart` and `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart` and run any existing targeted attendance-taking tests to confirm no state contract changes are required for this fix

**Checkpoint**: All user stories should now be independently functional with stable offline/sync and Cubit behavior.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup across the feature.

- [X] T017 [P] Re-run `flutter test test/features/attendance/data/repos/attendance_repository_test.dart` after all changes to confirm the full attendance repository regression suite passes
- [X] T018 Run `flutter analyze` from the repository root to validate the final surgical change set

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; starts immediately
- **Foundational (Phase 2)**: Depends on Setup; blocks story execution until repository upsert behavior and local persistence paths are confirmed
- **User Story 1 (Phase 3)**: Depends on Phase 2; delivers the MVP
- **User Story 2 (Phase 4)**: Depends on User Story 1 because it extends the same repository mark-update path
- **User Story 3 (Phase 5)**: Depends on Phase 2 and can proceed after User Story 1 if the local persistence path exists; keep it after US2 for safer regression sequencing
- **Polish (Phase 6)**: Depends on all desired stories being complete

### User Story Dependencies

- **US1**: No dependencies on other stories after Phase 2
- **US2**: Depends on US1's student-keyed document path being correct
- **US3**: Depends on foundational discovery of the local persistence files; should remain independently testable once those files are identified

### Within Each User Story

- Write or update the requested regression tests before finalizing implementation
- Repository identity changes before mapping or Cubit verification
- Local attendance record identity changes before queue-correlation verification
- Finish story-level validation before moving to the next story

### Parallel Opportunities

- T004 can run in parallel with T003 after Setup
- T005 can run in parallel with repository code inspection once Phase 2 is done
- T009 and T011 can run in parallel within US2 because they touch different concerns
- T013 can run in parallel with T016 after the offline persistence file is identified
- T017 can run in parallel with final manual review before T018

---

## Parallel Example: User Story 1

```bash
# Run the US1 test-writing and repository verification work in parallel:
Task: "Add or update repeated-mark regression test in test/features/attendance/data/repos/attendance_repository_test.dart"
Task: "Inspect and update the mark write path in lib/features/attendance/data/repos/attendance_repository.dart"
```

## Parallel Example: User Story 3

```bash
# After locating the offline persistence file, run these in parallel:
Task: "Add or update local attendance record identity tests in the file found by T004"
Task: "Review attendance-taking Cubit/state stability in lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart and lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate repeated marking produces one mark document keyed by `studentId`
5. Stop and demo the core idempotent Firestore fix if needed

### Incremental Delivery

1. Deliver US1 to lock in the canonical server-side mark identity
2. Deliver US2 to prove corrections update in place without duplicates
3. Deliver US3 to align local persistence and confirm no attendance-taking workflow regressions
4. Finish with repository test and analyzer validation

### Suggested MVP Scope

- **MVP**: Phase 1 + Phase 2 + Phase 3 (US1)
- **Why**: US1 alone satisfies the core business requirement that a student can only have one stored mark per session

---

## Notes

- All tasks follow the required checklist format: checkbox, task ID, optional `[P]`, required story label for story tasks, and exact file path or scoped project path
- The current planning scan did not find `AttendanceRecordHive` or `SyncQueueItemHive` in the already inspected attendance files, so T004 is intentionally included as a blocking discovery task before touching offline persistence code
- Use `dart run build_runner build --delete-conflicting-outputs` only if implementation changes a generated model
