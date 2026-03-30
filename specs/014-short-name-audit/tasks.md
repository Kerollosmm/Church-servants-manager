# Tasks: CSMS Production Hardening Remediation

**Input**: Design documents from `C:\Users\KimoStore\church_managment_system\specs\014-short-name-audit\`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

**Tests**: Include targeted widget, integration, repository, rules, and analyzer tasks because the specification requires independent validation and measurable acceptance outcomes.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. `US1`, `US2`, `US3`)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the remediation workspace, validation surface, and shared planning artifacts.

- [x] T001 Review and align `specs/014-short-name-audit/plan.md`, `specs/014-short-name-audit/spec.md`, and `AGENTS.md` before implementation
- [ ] T002 Create the remediation test matrix in `specs/014-short-name-audit/quickstart.md` covering widget, repository, rules, and analyzer checks per phase
- [ ] T003 [P] Add missing test placeholders for phase coverage in `test/features/attendance/`, `test/features/auth/`, `test/features/admin/`, and `test/core/routing/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish cross-story foundations that block all user stories.

**⚠️ CRITICAL**: No user story work should be considered complete until these foundations are in place.

- [x] T004 Audit and align route constants and argument types in `lib/core/constants/routes.dart`, `lib/core/routing/route_args.dart`, and `lib/core/routing/app_router.dart`
- [x] T005 [P] Register any missing remediation cubits/services in `lib/core/di/injection.dart`
- [x] T006 [P] Add emulator or rules-test scaffolding for authorization verification in `test/core/firestore/` and project config files that support rules validation
- [ ] T007 Define additive audit event shape and shared mapping helpers in `lib/Features/attendance/data/models/`, `lib/Features/admin/data/`, or adjacent feature-first locations referenced by this remediation
- [ ] T008 Review and update `firestore.indexes.json` against current collection casing and planned bounded-query patterns

**Checkpoint**: Shared routing, DI, rules-test scaffolding, audit shape, and index baseline are ready.

---

## Phase 3: User Story 1 - Restore End-to-End Attendance Operations (Priority: P1) 🎯 MVP

**Goal**: Restore working attendance session creation, attendance taking, history, and student attendance flows from the app.

**Independent Test**: Sign in as an authorized admin or servant, create a session, mark multiple students, review history, and open student attendance from working screens without hitting placeholders.

### Tests for User Story 1

- [x] T009 [P] [US1] Add widget flow tests for restored attendance screens in `test/features/attendance/presentation/screens/attendance_workflow_test.dart`
- [x] T010 [P] [US1] Add routing tests for attendance entry points in `test/core/routing/app_router_attendance_flow_test.dart`
- [x] T011 [P] [US1] Add Cubit/widget interaction tests for attendance-taking UI state in `test/features/attendance/presentation/widgets/attendance_taking_view_test.dart`

### Implementation for User Story 1

- [x] T012 [US1] Restore admin attendance entry surface in `lib/Features/admin/presentation/screens/admin_dashboard_screen.dart`
- [x] T013 [US1] Restore servant attendance entry surface in `lib/Features/servant/presentation/screens/servant_dashboard_screen.dart`
- [x] T014 [US1] Implement session-create screen flow in `lib/Features/attendance/presentation/screens/attendance_session_create_screen.dart`
- [x] T015 [P] [US1] Implement attendance-taking screen shell and Cubit binding in `lib/Features/attendance/presentation/screens/attendance_taking_screen.dart`
- [x] T016 [P] [US1] Implement attendance history screen flow in `lib/Features/attendance/presentation/screens/attendance_history_screen.dart`
- [x] T017 [P] [US1] Implement student attendance screen flow in `lib/Features/attendance/presentation/screens/student_attendance_screen.dart`
- [x] T018 [P] [US1] Restore attendance widgets required by the active workflow in `lib/Features/attendance/presentation/widgets/`
- [x] T019 [US1] Wire restored attendance screens to existing Cubits and route arguments in `lib/core/routing/app_router.dart`
- [x] T020 [US1] Ensure restored screens keep business logic out of widgets by moving any decision logic into attendance Cubits in `lib/Features/attendance/presentation/bloc/`

**Checkpoint**: User Story 1 is fully functional and testable as the MVP.

---

## Phase 4: User Story 2 - Enforce Safe Access and Account Boundaries (Priority: P1)

**Goal**: Make self-registration, protected navigation, student self-read, and role/archive enforcement consistent and safe.

**Independent Test**: Attempt self-registration, protected navigation, student self-read, archived-account usage, and privilege downgrade scenarios with admin, servant, student, and archived identities.

### Tests for User Story 2

- [x] T021 [P] [US2] Add auth and role-resolution tests for self-registration and cached-session behavior in `test/features/auth/`
- [x] T022 [P] [US2] Add routing guard tests for archive/demotion behavior in `test/core/routing/role_router_test.dart` and `test/features/admin/presentation/widget/admin_gate_test.dart`
- [x] T023 [P] [US2] Add Firestore rules tests for self-read and role-scoped access in `test/core/firestore/access_rules_test.dart`

### Implementation for User Story 2

- [x] T024 [US2] Restrict self-service registration role assignment in `lib/Features/auth/data/services/firebase_auth_provider.dart`, `lib/Features/auth/data/services/auth_service.dart`, and related auth use cases
- [x] T025 [US2] Make auth-driven route protection reactive in `lib/core/routing/role_router.dart` and `lib/Features/admin/presentation/widget/admin_gate.dart`
- [x] T026 [US2] Tighten stale-session and degraded access handling in `lib/Features/auth/domain/usecases/observe_auth_state_usecase.dart` and `lib/Features/auth/presentation/bloc/`
- [x] T027 [US2] Standardize canonical student-user linkage in `lib/Features/student/data/models/student_model.dart`, `lib/Features/student/data/repos/student_data_repository.dart`, `lib/Features/student/data/services/student_linked_user_sync_service.dart`, and related query helpers
- [x] T028 [US2] Harden Firestore access rules for self-registration, student self-read, archive state, and scope boundaries in `firestore.rules`
- [x] T029 [US2] Align backend authorization checks with current role/archive truth in `functions/src/index.ts`, `functions/src/admin.ts`, and related backend helpers

**Checkpoint**: User Story 2 independently enforces access boundaries and removes direct self-elevation paths.

---

## Phase 5: User Story 3 - Preserve Auditability and Data Integrity Under Real Usage (Priority: P2)

**Goal**: Prevent destructive concurrent attendance outcomes and preserve accountable history for session and mark changes.

**Independent Test**: Simulate concurrent mark changes, bulk-completion actions, mark removal/replacement, and lifecycle operations, then verify correct final state and attributable history.

### Tests for User Story 3

- [x] T030 [P] [US3] Add repository concurrency tests for bulk mark protection and session conflicts in `test/features/attendance/data/repos/attendance_repository_test.dart`
- [x] T031 [P] [US3] Add tests for attendance mark lifecycle history and clear behavior in `test/features/attendance/data/models/` and `test/features/attendance/presentation/bloc/`
- [x] T032 [P] [US3] Add backend or integration coverage for audit event creation in `functions/test/` or the nearest existing backend test location

### Implementation for User Story 3

- [x] T033 [US3] Protect manual attendance exceptions during bulk completion in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [x] T034 [US3] Make conflicting session creation impossible within an active window in `lib/Features/attendance/data/repos/attendance_repository.dart` and any required backend helper in `functions/src/`
- [x] T035 [US3] Replace destructive attendance clear behavior with accountable state/history handling in `lib/Features/attendance/data/repos/attendance_repository.dart` and related attendance models
- [x] T036 [P] [US3] Add immutable or append-only audit event writing for attendance lifecycle actions in `functions/src/` and connected client/repository call sites
- [x] T037 [US3] Ensure high-impact lifecycle actions record actor and timestamp in `lib/Features/attendance/data/`, `lib/Features/servant/data/`, and `lib/Features/team/data/`

**Checkpoint**: User Story 3 independently preserves trustworthy attendance outcomes and auditability.

---

## Phase 6: User Story 4 - Make Reporting and Administration Operationally Useful (Priority: P3)

**Goal**: Make reports and managed account lifecycle flows usable, bounded, and operationally trustworthy.

**Independent Test**: Load bounded team and student summaries, review audit-oriented admin views, and complete managed account restore flows with clear next steps.

### Tests for User Story 4

- [x] T038 [P] [US4] Add bounded report tests for student and team summaries in `test/features/attendance/data/repos/attendance_repository_test.dart`
- [x] T039 [P] [US4] Add admin lifecycle workflow tests in `test/features/admin/` and `test/features/auth/`
- [x] T040 [P] [US4] Add search behavior tests for servant and student records in `test/features/servant/` and `test/features/student/`

### Implementation for User Story 4

- [x] T041 [US4] Bound team and student attendance summary queries in `lib/Features/attendance/data/repos/attendance_repository.dart`
- [x] T042 [US4] Add admin-facing audit and lifecycle review surfaces in `lib/Features/admin/presentation/screens/` and supporting Cubits under `lib/Features/admin/presentation/bloc/`
- [x] T043 [US4] Improve managed account restore/provisioning follow-up guidance in `lib/Features/auth/data/services/admin_user_provisioning_service.dart`, `lib/Features/auth/data/services/admin_auth_client.dart`, and related admin presentation flows
- [x] T044 [US4] Remove remaining `'system'` lifecycle attribution gaps in `lib/Features/servant/data/repo/servant_data_repository.dart` and `lib/Features/team/data/repos/team_repository.dart`
- [x] T045 [US4] Harden membership fallback and identity consistency behavior in `lib/Features/student/data/services/student_query_service.dart`, `lib/Features/admin/data/admin_team_membership_service.dart`, and related data services
- [x] T046 [US4] Improve searchable staff/student behavior for expected name formats in `lib/Features/servant/data/repo/servant_data_repository.dart` and `lib/Features/student/data/services/student_query_service.dart`

**Checkpoint**: User Story 4 independently delivers bounded reporting and usable admin lifecycle flows.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Cross-story validation, cleanup, and release hardening.

- [x] T047 [P] Run `flutter analyze` and fix final remediation issues across touched files
- [x] T048 Run `flutter test` and phase-targeted validation commands referenced in `specs/014-short-name-audit/quickstart.md`
- [x] T049 [P] Update remediation documentation and acceptance notes in `specs/014-short-name-audit/quickstart.md` and adjacent feature docs if required
- [x] T050 Review all touched files for required `// FIX [014-*]` traceability comments and constitution compliance

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion - recommended MVP start
- **User Story 2 (Phase 4)**: Depends on Foundational completion and should land before broad release of restored attendance flows
- **User Story 3 (Phase 5)**: Depends on Foundational completion and benefits from User Story 1 attendance flow restoration
- **User Story 4 (Phase 6)**: Depends on Foundational completion and should build on trusted lifecycle and access behavior from prior phases
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can begin after Foundational completion; forms the MVP
- **User Story 2 (P1)**: Can begin after Foundational completion; should complete before production release
- **User Story 3 (P2)**: Depends operationally on the restored attendance flow from US1 for end-to-end validation
- **User Story 4 (P3)**: Depends on trusted access and lifecycle semantics from US2 and US3 for reliable reporting/admin review

### Within Each User Story

- Tests should be written before or alongside implementation and must validate the story independently.
- Route and screen wiring should precede cross-story polish.
- Repository/data integrity changes should land before admin/reporting surfaces that depend on them.

### Parallel Opportunities

- `T003`, `T005`, `T006`, and `T008` can run in parallel after initial setup alignment.
- Within US1, `T015`, `T016`, `T017`, and `T018` can run in parallel once route and screen responsibilities are agreed.
- Within US2, test tasks `T021`-`T023` can run in parallel, and linkage/rules/backend tasks can be split across contributors.
- Within US3, tests `T030`-`T032` and implementation tasks `T035`-`T036` can be parallelized where file ownership does not overlap.
- Within US4, tests `T038`-`T040` can run in parallel, and reporting, lifecycle, and search tasks can be split by feature slice.

---

## Parallel Example: User Story 1

```bash
# Launch User Story 1 validation tasks together:
Task: "Add widget flow tests in test/features/attendance/presentation/screens/attendance_workflow_test.dart"
Task: "Add routing tests in test/core/routing/app_router_attendance_flow_test.dart"
Task: "Add UI state tests in test/features/attendance/presentation/widgets/attendance_taking_widgets_test.dart"

# Launch screen restoration tasks that touch different files:
Task: "Implement attendance-taking screen in lib/Features/attendance/presentation/screens/attendance_taking_screen.dart"
Task: "Implement attendance history screen in lib/Features/attendance/presentation/screens/attendance_history_screen.dart"
Task: "Implement student attendance screen in lib/Features/attendance/presentation/screens/student_attendance_screen.dart"
```

---

## Parallel Example: User Story 2

```bash
# Launch authorization validation in parallel:
Task: "Add auth tests in test/features/auth/"
Task: "Add routing guard tests in test/core/routing/role_router_test.dart"
Task: "Add Firestore access rules tests in test/core/firestore/access_rules_test.dart"

# Split implementation by boundary:
Task: "Restrict self-service registration in lib/Features/auth/data/services/firebase_auth_provider.dart"
Task: "Harden Firestore rules in firestore.rules"
Task: "Align backend authorization in functions/src/index.ts"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: confirm the attendance workflow is restored end-to-end

### Incremental Delivery

1. Restore attendance workflows (US1)
2. Harden access boundaries before release (US2)
3. Protect integrity and auditability (US3)
4. Improve reporting and administration usefulness (US4)
5. Run final cross-cutting validation and cleanup

### Suggested MVP Scope

- **MVP**: User Story 1 only, with foundational setup and routing/DI support
- **Release-safe minimum**: User Stories 1 + 2
- **Production-hardening target**: User Stories 1 + 2 + 3 + 4

---

## Notes

- All tasks follow the required checklist format with task ID and file path.
- `[P]` tasks should only be executed in parallel when they do not touch the same files.
- Offline sync redesign remains excluded from this task list by plan and spec.
