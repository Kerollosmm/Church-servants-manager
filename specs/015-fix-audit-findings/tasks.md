# Tasks: Production Audit Remediation

**Input**: Design documents from `/specs/015-fix-audit-findings/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No dedicated test-authoring tasks are included because the feature specification did not require a TDD workflow. Verification tasks are included in the final phase.

**Organization**: Tasks are grouped by user story to enable independent implementation and validation of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Flutter app code lives under `lib/Features/` and `lib/core/`
- Firebase Functions code lives under `functions/src/`
- Firestore rules live in `firestore.rules`
- Feature documentation lives under `specs/015-fix-audit-findings/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared infrastructure needed by the remediation work.

- [ ] T001 Add attendance read-model collection path constants in `lib/core/constants/firestore_collections.dart`
- [ ] T002 [P] Create the attendance history read-model mapping in `lib/Features/attendance/data/models/attendance_history_entry.dart`
- [ ] T003 [P] Extend shared auth resolution state for password-change-required routing in `lib/Features/auth/domain/usecases/observe_auth_state_usecase.dart` and `lib/core/routing/role_router.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before user story work begins.

**⚠️ CRITICAL**: No user story work should begin until this phase is complete.

- [ ] T004 Update shared attendance repository helpers for atomic audit persistence and read-model synchronization in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] T005 [P] Add shared Firestore rule helpers for attendance audit events, session-close authorization, and duration validation in `firestore.rules`
- [ ] T006 [P] Update callable authorization and lifecycle timestamp helpers in `functions/src/index.ts` and `functions/src/lifecycle_helpers.ts`

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Reliable Attendance Actions (Priority: P1) 🎯 MVP

**Goal**: Make attendance actions authoritative, audited, and clear when access changes block a user.

**Independent Test**: Create, update, and clear attendance marks with valid and invalid users and confirm that successful actions are audited, failed actions do not create false-success audit records, and blocked actions show an actionable access-changed message.

### Implementation for User Story 1

- [ ] T007 [US1] Refactor attendance mark create and update flows to commit audit records atomically in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] T008 [US1] Refactor attendance mark clear flow to delete the mark before writing a successful clear audit record in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] T009 [P] [US1] Surface permission-changed handling and retry-safe refresh triggers in `lib/Features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`
- [ ] T010 [US1] Complete signed-in user refresh and access-changed messaging for blocked attendance actions in `lib/Features/auth/presentation/bloc/auth_bloc.dart` and `lib/Features/auth/domain/usecases/observe_auth_state_usecase.dart`
- [ ] T011 [US1] Allow authorized audit review reads for attendance events in `firestore.rules` and `lib/Features/admin/data/admin_audit_review_service.dart`

**Checkpoint**: User Story 1 should now be functional and independently verifiable.

---

## Phase 4: User Story 2 - Scalable Attendance History And Summaries (Priority: P1)

**Goal**: Replace high-cost attendance history and summary reads with bounded, scalable read paths.

**Independent Test**: Load a student with at least a year of attendance history and a servant/admin dashboard with mature team history, then confirm history and summary screens remain responsive, accurate, and stable during routine updates.

### Implementation for User Story 2

- [ ] T012 [US2] Extend student and team summary models for read-model-backed aggregation in `lib/Features/attendance/data/models/attendance_stats.dart`
- [ ] T013 [P] [US2] Add the student attendance history read-model contract consumer in `lib/Features/attendance/data/models/attendance_history_entry.dart` and `lib/Features/attendance/domain/repos/i_attendance_repository.dart`
- [ ] T014 [US2] Populate and maintain student history and summary read models during attendance/session mutations in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] T015 [US2] Replace `watchStudentAttendanceHistory` and `getStudentAttendanceStats` with bounded read-model queries in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] T016 [US2] Replace `getTeamAttendanceStats` with read-model-backed queries in `lib/Features/attendance/data/repos/attendance_repository.dart` and `lib/Features/servant/presentation/bloc/servant_dashboard_cubit.dart`
- [ ] T017 [US2] Update student attendance and profile consumers to use the new history and summary path in `lib/Features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart` and `lib/Features/student/presentation/bloc/student_profile/student_profile_cubit.dart`

**Checkpoint**: User Stories 1 and 2 should both work, and User Story 2 should be independently verifiable.

---

## Phase 5: User Story 3 - Safe Session And Bulk Attendance Management (Priority: P2)

**Goal**: Make session creation, closure, and bulk attendance actions consistent, bounded, and safe at scale.

**Independent Test**: Attempt duplicate session creation, invalid-duration session creation, early session closure, and bulk mark-remaining actions for large teams, then confirm the system blocks invalid actions and completes valid ones without partial results.

### Implementation for User Story 3

- [ ] T018 [US3] Remove the non-atomic open-session pre-check and enforce uniqueness only inside the transaction in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] T019 [US3] Enforce the 480-minute session duration cap in `lib/Features/attendance/data/repos/attendance_repository.dart` and `firestore.rules`
- [ ] T020 [P] [US3] Allow authorized servants and admins to close sessions early in `lib/Features/attendance/data/repos/attendance_repository.dart` and `firestore.rules`
- [ ] T021 [US3] Update session admin state handling to use authoritative close timestamps in `lib/Features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart`
- [ ] T022 [US3] Replace the single large bulk-mark transaction with chunked commits in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [ ] T023 [US3] Filter expired or closed sessions out of active attendance flows in `lib/Features/attendance/data/repos/attendance_repository.dart` and `lib/Features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`

**Checkpoint**: User Stories 1, 2, and 3 should now all be independently functional.

---

## Phase 6: User Story 4 - Secure Account And Admin Safeguards (Priority: P2)

**Goal**: Enforce restored-account password change, linked-student integrity, and privileged admin safety rules.

**Independent Test**: Restore a privileged account, attempt to navigate without changing the temporary password, create a linked student, and attempt an admin self-archive, then confirm the system forces password change, creates immediate searchable linkage, and rejects self-archive.

### Implementation for User Story 4

- [ ] T024 [US4] Preserve `restorePendingPasswordReset` until completion and expose a password-change-required auth state in `lib/Features/auth/data/services/firebase_auth_provider.dart`, `lib/Features/auth/domain/usecases/observe_auth_state_usecase.dart`, and `lib/Features/auth/presentation/bloc/auth_bloc.dart`
- [ ] T025 [US4] Route restored privileged users into a forced password-change flow in `lib/core/routing/role_router.dart` and `lib/Features/auth/presentation/screens/splash_screen.dart`
- [ ] T026 [P] [US4] Block admin self-archive and use merged custom claims plus authoritative lifecycle timestamps in `functions/src/index.ts` and `functions/src/lifecycle_helpers.ts`
- [ ] T027 [US4] Keep canonical and legacy servant assignments synchronized in `lib/Features/admin/data/admin_team_service.dart`, `lib/Features/team/data/repos/team_repository.dart`, and `lib/Features/auth/data/services/auth_user_profile_store.dart`
- [ ] T028 [US4] Enforce linked-student uniqueness and immediate ownership writes in `lib/Features/student/data/repos/student_data_repository.dart` and `lib/Features/student/data/services/student_linked_user_sync_service.dart`
- [ ] T029 [US4] Ensure newly created linked students are searchable and role resolution stays neutral until complete in `lib/Features/student/domain/usecases/add_student_usecase.dart`, `lib/Features/student/data/services/student_query_service.dart`, and `lib/Features/auth/data/models/auth_user.dart`

**Checkpoint**: All user stories should now be independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cross-cutting cleanup.

- [ ] T030 [P] Update operator-facing implementation notes and acceptance checkpoints in `specs/015-fix-audit-findings/quickstart.md`
- [ ] T031 Run Flutter and Firestore-rule verification steps from `specs/015-fix-audit-findings/quickstart.md`
- [ ] T032 Run Cloud Functions lint and build verification from `specs/015-fix-audit-findings/quickstart.md`
- [ ] T033 [P] Regenerate annotated model outputs referenced by `lib/Features/**/**.freezed.dart` and `lib/Features/**/**.g.dart` if any annotated models changed
- [ ] T034 Review all touched production files for required `FIX [015]` traceability comments in the paths modified above

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion - recommended MVP starting point
- **User Story 2 (Phase 4)**: Depends on Foundational completion and should follow User Story 1 because both heavily update `lib/Features/attendance/data/repos/attendance_repository.dart`
- **User Story 3 (Phase 5)**: Depends on Foundational completion and should follow User Story 1 because it extends the same attendance transaction/session helpers
- **User Story 4 (Phase 6)**: Depends on Foundational completion and can proceed in parallel with User Story 2 or User Story 3 where file conflicts do not overlap
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No story dependency after Phase 2
- **User Story 2 (P1)**: Depends on shared attendance repository foundations from Phase 2; recommended after US1
- **User Story 3 (P2)**: Depends on shared attendance repository foundations from Phase 2; recommended after US1
- **User Story 4 (P2)**: Depends only on Phase 2 and is otherwise independent from US1-US3

### Within Each User Story

- Shared repository or auth primitives before UI/state consumers
- Data-model or contract changes before repository and callable updates
- Repository/function/rules changes before final verification
- Complete each story checkpoint before moving to broad polish

### Parallel Opportunities

- `T002` and `T003` can run in parallel in Phase 1
- `T005` and `T006` can run in parallel in Phase 2
- `T009` can run in parallel with `T011` after `T007`/`T008` stabilize US1 repository behavior
- `T012` and `T013` can run in parallel in US2 before repository rewiring
- `T020` can run in parallel with `T021` in US3 after `T018` is complete
- `T026` can run in parallel with `T027` or `T028` in US4
- `T030` and `T033` can run in parallel in the Polish phase

---

## Parallel Example: User Story 4

```bash
# After Foundational phase completes, these can run in parallel:
Task: "Block admin self-archive and use merged custom claims plus authoritative lifecycle timestamps in functions/src/index.ts and functions/src/lifecycle_helpers.ts"
Task: "Keep canonical and legacy servant assignments synchronized in lib/Features/admin/data/admin_team_service.dart, lib/Features/team/data/repos/team_repository.dart, and lib/Features/auth/data/services/auth_user_profile_store.dart"
Task: "Enforce linked-student uniqueness and immediate ownership writes in lib/Features/student/data/repos/student_data_repository.dart and lib/Features/student/data/services/student_linked_user_sync_service.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Stop and validate reliable attendance actions before expanding scope

### Incremental Delivery

1. Finish Setup + Foundational work
2. Deliver User Story 1 as the MVP
3. Add User Story 2 for scalable history and summary reads
4. Add User Story 3 for safer session and bulk actions
5. Add User Story 4 for account/admin safeguards
6. Finish with Polish and verification

### Parallel Team Strategy

1. One engineer completes Phase 1 and Phase 2 shared infrastructure
2. Then split work by story with repository-conflict awareness:
   - Engineer A: User Story 1, then User Story 3
   - Engineer B: User Story 2 read-model consumer work after shared attendance helpers land
   - Engineer C: User Story 4 auth, student, and function safeguards

---

## Notes

- [P] tasks touch different files or can proceed after the listed prerequisite work stabilizes
- [US#] labels map each task to a single user story for traceability
- Every implementation task should add `FIX [015]` comments near changed production logic per the constitution
- Offline sync, offline queues, and other offline-first work are intentionally excluded from these tasks
