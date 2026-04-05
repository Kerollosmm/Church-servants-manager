<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0
Bump rationale: MAJOR — Initial ratification of the project constitution.

Added principles:
  P01: Clean Architecture Boundaries
  P02: Single-Responsibility Components
  P03: No UI-Owned Business Logic
  P04: Explicit Authorization Boundaries
  P05: Server-Authoritative Privileged Mutations
  P06: No Duplicate Write Paths
  P07: Test-First for Risky Logic
  P08: Incremental Delivery with Rollback Safety
  P09: Spec–Code–Test Traceability
  P10: Accessibility and Non-Technical Usability
  P11: Performance-Aware Flutter Composition
  P12: Predictable Bloc/Cubit Patterns
  P13: Repository and Service Boundary Discipline
  P14: Firebase Safety and Data Consistency
  P15: Logging, Error Handling, and Observability
  P16: Naming and Schema Consistency
  P17: Documentation for Future Agents

Added hard-rule sections:
  HR-01: Feature Flags and Staged Rollout
  HR-02: Transactions, Batched Writes, and Backend Functions
  HR-03: Cache vs Server Truth
  HR-04: When to Stop and Ask for Clarification
  HR-05: Task Breakdown Requirements
  HR-06: Definition of Done

Added sections:
  - Preamble
  - Principles (17)
  - Hard Rules (6)
  - Governance

Removed sections: (none — first version)

Templates requiring updates:
  ⚠ .specify/templates/plan-template.md — does not exist yet
  ⚠ .specify/templates/spec-template.md — does not exist yet
  ⚠ .specify/templates/tasks-template.md — does not exist yet

Follow-up TODOs:
  - Create Spec-Kit template files that reference these principles
  - Wire firestore.rules deployment into firebase.json (P14)
-->

# CSMS Project Constitution

**Project:** Church Servant & Student Management System (CSMS)
**Stack:** Flutter 3.x + Firebase (Firestore, Auth, Cloud Functions)
**Constitution Version:** 1.0.0
**Ratification Date:** 2026-04-04
**Last Amended Date:** 2026-04-04
**Governing Authority:** Project Owner (Kerollos)

---

## Preamble

This constitution defines the non-negotiable engineering principles
and hard rules for all development on the CSMS codebase. Every
contributor — human or AI agent — MUST read, understand, and comply
with this document before writing or modifying any code.

This document is optimized for AI-assisted development. Every
principle is stated in declarative, testable language so that an
implementing agent (Gemini, Codex, or equivalent) can verify
compliance mechanically or by self-audit.

**Enforcement:** Any pull request, commit, or generated code that
violates a principle MUST be revised before merge. Agents MUST
self-check against this constitution before producing output.

---

## Principles

### P01: Clean Architecture Boundaries

Every feature MUST follow the three-layer vertical slice:

```
presentation/  →  domain/  →  data/
```

**Non-negotiable rules:**

- `presentation/` MUST NOT import anything from `data/` directly.
  It depends only on `domain/` interfaces and on `core/`.
- `domain/` MUST NOT import Firebase SDK classes, Firestore types,
  or any concrete data-layer implementation.
- `data/` is the only layer that knows about Firebase, HTTP, or
  any external service SDK.
- Cross-feature imports MUST go through domain interfaces or shared
  `core/` code registered in the DI container. Direct imports of
  another feature's `data/` or `presentation/` internals are
  FORBIDDEN.
- `core/` contains only infrastructure shared by ≥2 features:
  DI, routing, theme, constants, shared widgets, and utilities.

**Rationale:** Layer violations create untestable, tightly coupled
code that cannot be refactored safely.

---

### P02: Single-Responsibility Components

Every class, function, BLoC, Cubit, repository, and service MUST
have exactly one reason to change.

**Non-negotiable rules:**

- A class that does ≥2 of: UI rendering, business logic, data access,
  orchestration, or permission checking MUST be split.
- BLoCs/Cubits own screen-level state orchestration ONLY. They MUST
  NOT contain Firestore queries, serialization logic, or permission
  evaluation beyond delegating to a use case.
- Repositories own data access for a single collection or bounded
  aggregate. Multi-collection orchestration MUST live in a dedicated
  service or use case.
- Use cases encapsulate a single business operation. If a use case
  requires more than ~40 lines (excluding error handling), it is
  likely doing too much.

**Rationale:** SRP violations hide bugs and make changes risky.

---

### P03: No UI-Owned Business Logic

Business rules MUST NOT live in widgets, screens, or build methods.

**Non-negotiable rules:**

- Widgets MUST be pure functions of state. They receive data and
  emit user events. They MUST NOT compute derived business state,
  evaluate permissions, apply domain transformations, or perform
  conditional logic that determines what the user is allowed to do.
- Permission checks MUST live in use cases or domain policy classes
  (e.g., `AdminPolicy`, `CanMutateStudentUseCase`).
- Data transformations (filtering, sorting by business rules,
  aggregate calculations) MUST live in the domain or data layer,
  not in `build()` methods.
- The test for compliance: if you remove the UI, can you still
  verify the business rule with a unit test? If no, the logic is
  in the wrong place.

---

### P04: Explicit Authorization Boundaries

Authorization MUST be enforced at every layer, independently.

**Non-negotiable rules:**

- **Client-side (Flutter):** Route guards (`AdminGate`, `RoleRouter`)
  MUST prevent navigation to unauthorized screens. BLoC/Cubit
  methods MUST validate actor permissions before calling repositories.
- **Domain layer:** Use cases that mutate data MUST include an
  explicit permission check as their first operation.
- **Server-side (Firestore rules):** Rules MUST independently enforce
  the same access policy. Rules MUST prefer custom claims over
  Firestore document fields when both exist. Rules MUST deny access
  to archived users for all write operations.
- **Backend functions:** Callable functions MUST re-validate the
  caller's current role AND archive state from the Firestore `Users`
  document — never trust token claims alone for privileged operations.
- Defense-in-depth: every permission boundary MUST work correctly
  even if the adjacent layer is compromised or bypassed.

**Rationale:** The app serves a church community where unauthorized
data exposure (student contact info, attendance records) creates
real pastoral harm.

---

### P05: Server-Authoritative Privileged Mutations

Any operation that changes user identity, role, archive state,
custom claims, or system-level configuration MUST be executed by
a Cloud Function — not by client-side Firestore writes.

**Non-negotiable rules:**

- User creation (servant/student provisioning) MUST use a callable
  Cloud Function that creates the Auth user, sets custom claims,
  and writes the Firestore profile atomically.
- Role changes (promote/demote) MUST go through a callable that
  updates both the Firestore document and custom claims, then
  revokes refresh tokens.
- Archive/restore MUST go through a callable that disables/enables
  the Auth user, updates the Firestore document, and revokes tokens.
- The client MUST NOT have Firestore rules that allow writing to
  `role`, `isArchived`, or `customClaims`-equivalent fields directly.
- Read-model collections (`attendance_history`, `attendance_stats`,
  `audit_logs`, `audit_events`) MUST be writable only by backend
  functions. Firestore rules MUST deny all client writes.

---

### P06: No Duplicate Write Paths

For any given business invariant, there MUST be exactly one code
path that performs the write.

**Non-negotiable rules:**

- If a Cloud Function writes a field, the Flutter client MUST NOT
  also write that same field. One owner, one path.
- Denormalized data (e.g., `assignedServantName` on `TeamModel`)
  MUST have exactly one update origin. That origin MUST be
  documented in the model file.
- If two features need to update the same document, they MUST go
  through a shared service or use case — not duplicate the write
  logic independently.
- When adding a new write path, the implementer MUST search the
  codebase for existing writes to the same collection/field and
  either reuse or explicitly replace the existing path.

**Rationale:** Duplicate writes cause data inconsistency, race
conditions, and make audit impossible.

---

### P07: Test-First for Risky Logic

Code that touches permissions, money-equivalent data, state
machines, or multi-document consistency MUST have tests written
before or alongside the implementation.

**Non-negotiable rules:**

- The following categories MUST have unit tests before merge:
  - Auth state transitions (especially degraded and archived paths)
  - Permission use cases (`CanMutate*`, `AdminPolicy`)
  - Repository methods that use transactions or batched writes
  - Session lifecycle (create, close, reopen, overlap detection)
  - Attendance mark validation (roster membership, time window)
  - Data sync services (`StudentLinkedUserSyncService`)
- BLoC/Cubit tests MUST use `blocTest` and verify the exact
  sequence of emitted states.
- Repository tests MUST use `FakeFirebaseFirestore` for isolation.
- Edge cases (empty roster, archived team, network failure mid-
  transaction, concurrent session creation) MUST be covered.
- Test naming: `test('[MethodUnderTest] [scenario] [expectedOutcome]')`

**Rationale:** These are the areas where bugs cause the most user
harm and are hardest to detect in manual testing.

---

### P08: Incremental Delivery with Rollback Safety

Every change MUST be deliverable incrementally and reversible.

**Non-negotiable rules:**

- Large features MUST be broken into ≥2 merge-safe increments.
  Each increment MUST leave the app in a working state.
- Database schema changes MUST be additive (new fields with defaults,
  new collections). Destructive schema changes (renaming or deleting
  fields) MUST be preceded by a migration that handles both old and
  new formats.
- Firestore security rule changes MUST be deployed before the client
  code that depends on them, never the other way around.
- Feature flag or conditional checks MUST gate incomplete features
  so that partially-deployed code does not surface to users.
- Every increment MUST include its own tests. Tests MUST NOT be
  deferred to a final "testing phase."
- If a change cannot be rolled back by reverting the commit, the PR
  description MUST document the rollback procedure explicitly.

---

### P09: Spec–Code–Test Traceability

Every feature MUST maintain a traceable chain: specification →
implementation plan → task → code → test.

**Non-negotiable rules:**

- Each task in `tasks.md` MUST reference the spec requirement(s)
  it fulfills (by ID or section heading).
- Each test file MUST include a comment or doc referencing the
  requirement or acceptance criterion it validates.
- Code changes MUST reference the originating task or spec in
  the commit message or PR description.
- If a requirement changes after implementation begins, both the
  spec and the affected tasks MUST be updated before continuing.
- Orphan code (code that does not trace to any requirement) MUST
  be justified or removed.

---

### P10: Accessibility and Non-Technical Usability

The app serves church administrators, servants, and students who
may not be technically proficient. The UI MUST be usable without
training.

**Non-negotiable rules:**

- All interactive elements MUST have semantic labels for screen
  readers (`Semantics` widget or `semanticLabel` property).
- Error messages MUST be user-facing and actionable. Never expose
  raw exception messages, Firestore error codes, or stack traces.
- Form validation MUST provide inline feedback (not just on submit).
- Loading states MUST show a visible indicator. Empty states MUST
  show a helpful message, not a blank screen.
- Critical actions (delete, archive, close session) MUST require
  explicit confirmation dialogs.
- Touch targets MUST be ≥48×48 dp per Material Design guidelines.
- The app MUST support Arabic (RTL) text in student/servant names
  without layout breakage.

---

### P11: Performance-Aware Flutter Composition

Widget trees MUST be composed for performance, not just correctness.

**Non-negotiable rules:**

- `const` constructors MUST be used on every widget and data class
  where possible. The analyzer MUST NOT report avoidable missing
  `const` warnings.
- Lists with >20 items MUST use `ListView.builder` (lazy) — never
  `Column` with a list of children.
- `BlocBuilder` MUST use `buildWhen` to skip unnecessary rebuilds
  when only a subset of state changed.
- `BlocListener` MUST use `listenWhen` to prevent redundant
  side effects.
- Stream subscriptions in repositories MUST be disposed in `close()`
  or `dispose()`. Leaked subscriptions are a P0 bug.
- Firestore queries MUST use field filters to push selection to the
  server. Client-side filtering of large collections is FORBIDDEN
  unless the collection is guaranteed small (<100 documents).
- `rxdart` `combineLatest` streams MUST handle the case where one
  input stream errors — the combined stream MUST NOT silently die.

---

### P12: Predictable Bloc/Cubit Patterns

All state management MUST follow a consistent, predictable pattern.

**Non-negotiable rules:**

- States MUST be `sealed` classes. Each logical state (initial,
  loading, loaded, error) is a separate subclass. Nullable fields
  on a parent class to distinguish states are FORBIDDEN.
- BLoC events MUST be `sealed` classes. Each user action or system
  trigger is a separate subclass.
- Error states MUST carry a user-readable message AND the original
  failure type for programmatic handling.
- A BLoC/Cubit MUST NOT emit states after `close()` is called.
  All async operations MUST check `isClosed` before emitting.
- Global BLoCs (e.g., `AuthBloc`) are singleton-scoped and live for
  the app lifetime. Screen-scoped Cubits are created in `AppRouter`
  and disposed when the route is popped.
- Cubit methods that perform async work MUST emit `Loading` before
  the async call and MUST catch all exceptions, mapping them to
  error states — never letting exceptions propagate to the framework.

---

### P13: Repository and Service Boundary Discipline

Repositories and services have distinct responsibilities that MUST
NOT overlap.

**Non-negotiable rules:**

- A **repository** owns CRUD for a single Firestore collection (or a
  tightly coupled collection + subcollections, e.g., `Classes` +
  `attendance_sessions` + `marks`).
- A **service** orchestrates operations that span multiple
  repositories or perform side effects beyond simple CRUD
  (e.g., `AdminTeamMembershipService` updating both `Users` and
  `Students` documents).
- A repository MUST NOT call another repository directly. Cross-
  repository coordination MUST go through a service or use case.
- Repositories expose `Stream<T>` for live queries and `Future<T>`
  for one-shot operations. They MUST NOT expose raw `QuerySnapshot`
  or `DocumentSnapshot` types.
- All Firestore error codes MUST be caught in the data layer and
  mapped to typed domain failures before crossing the layer boundary.

---

### P14: Firebase Safety and Data Consistency

Firebase operations MUST be performed safely and consistently.

**Non-negotiable rules:**

- **Transactions** MUST be used when a write depends on reading
  current state (e.g., session overlap check, attendance lock).
- **Batched writes** MUST be used when multiple documents must
  succeed or fail together and no read-dependency exists.
- Batched writes MUST NOT exceed 500 operations (Firestore limit).
  If >500, the batch MUST be split with explicit documentation of
  partial-failure semantics.
- `FieldValue.serverTimestamp()` MUST be used for all `createdAt`
  and `updatedAt` fields. Client-derived `DateTime.now()` MUST NOT
  be written to timestamp fields.
- Document IDs MUST be deterministic where business logic requires
  idempotency (e.g., attendance session IDs). Random UUIDs are
  acceptable only when idempotency is not a concern.
- `firestore.rules` MUST be version-controlled and deployed via
  `firebase.json`. Manual rule edits in the Firebase Console are
  FORBIDDEN.
- Firestore indexes MUST be defined in `firestore.indexes.json`
  and deployed alongside rules. Ad-hoc index creation via error
  links is acceptable only in development.
- Offline persistence is enabled. Code MUST handle the case where
  streams return cached (potentially stale) data before server data.

---

### P15: Logging, Error Handling, and Observability

Errors MUST be handled explicitly and observably.

**Non-negotiable rules:**

- Every `catch` block MUST either:
  (a) map the error to a typed domain failure and propagate it, or
  (b) log the error with sufficient context and handle it locally.
  Empty `catch` blocks are FORBIDDEN.
- Domain failures MUST carry: failure type (enum or sealed class),
  user-readable message, and optionally the original exception for
  debugging.
- Repositories MUST log (at minimum via `debugPrint` in debug mode)
  every Firestore write operation with the collection path and
  document ID. This aids debugging without requiring production
  logging infrastructure.
- Cloud Functions MUST log every privileged action (user create,
  archive, restore, role change) with the actor UID, target UID,
  and timestamp.
- `FlutterError.onError` and `PlatformDispatcher.onError` MUST be
  configured in `main.dart` to catch and log unhandled errors.
  Crashing silently is FORBIDDEN.

---

### P16: Naming and Schema Consistency

Names MUST be consistent, predictable, and self-documenting.

**Non-negotiable rules:**

- **Dart files:** `snake_case.dart`. Feature files live under their
  feature's layer directory.
- **Dart classes:** `PascalCase`. Class name MUST match file name
  (e.g., `StudentDataRepository` in `student_data_repository.dart`).
- **Firestore collections:** `PascalCase` for top-level collections
  (`Users`, `Students`, `Classes`). `snake_case` for subcollections
  (`attendance_sessions`, `marks`, `audit_events`).
- **Firestore document fields:** `camelCase` (matching Dart model
  property names after JSON serialization).
- **BLoC events:** `{Feature}Event{Action}` (e.g., `AuthEventSignIn`).
- **BLoC states:** `{Feature}{StateDescription}` (e.g., `AuthAuthenticated`).
- **Route constants:** `camelCase` strings matching the screen name
  (e.g., `studentDetail`, `attendanceHistory`).
- **Enum values:** `camelCase` matching the Firestore-stored string
  value.
- **Test files:** `{file_under_test}_test.dart`, placed in a
  `test/` directory mirroring the `lib/` structure.
- Collection name constants MUST be defined in
  `core/constants/firestore_collections.dart`. Hardcoded collection
  name strings in repository code are FORBIDDEN.

---

### P17: Documentation for Future Agents

The codebase MUST be self-documenting to the level that an AI agent
can understand intent, constraints, and boundaries without human
explanation.

**Non-negotiable rules:**

- Every repository and service class MUST have a doc comment
  explaining its responsibility, what collection(s) it owns, and
  what it MUST NOT do.
- Every non-obvious business rule (e.g., "absent is implicit,"
  "claims override Firestore role") MUST have a code comment at
  the enforcement point.
- Every `@freezed` model MUST have a doc comment listing what
  Firestore document it maps to and any denormalization contracts.
- The `injection.dart` DI file MUST have inline comments grouping
  registrations by feature and noting singleton vs factory scope.
- When a design decision has tradeoffs (e.g., "we use denormalized
  servant names for display performance"), the comment MUST state
  the rationale AND the update contract (who is responsible for
  keeping it in sync).
- Stale comments are treated as bugs. When code changes, affected
  comments MUST be updated in the same commit.

---

## Hard Rules

### HR-01: Feature Flags and Staged Rollout

- Incomplete features MUST be gated behind a compile-time constant
  (`const bool kEnableFeatureX = false;`) or a Firestore-backed
  remote config flag.
- The default value for all feature flags MUST be `false` (off).
- Gated code paths MUST be tested in both the enabled and disabled
  states.
- Feature flags MUST be removed within one release cycle after the
  feature is fully launched. Dangling flags are tech debt.
- Staged rollout to production MUST follow this order:
  1. Deploy Firestore rules and indexes
  2. Deploy Cloud Functions
  3. Deploy Flutter app update
  This order ensures the backend is ready before clients start
  exercising new code paths.

---

### HR-02: Transactions, Batched Writes, and Backend Functions

Use the right tool for the right consistency requirement:

| Scenario | Tool | Why |
|---|---|---|
| Write depends on reading current state | `Firestore.runTransaction` | Prevents stale-read races |
| Multiple documents must succeed/fail together (no read needed) | `WriteBatch` | Atomic multi-doc writes |
| Operation requires Auth Admin SDK (create user, set claims, disable account) | Callable Cloud Function | Client SDK cannot access Admin APIs |
| Operation must write to read-model collections (`audit_logs`, `attendance_history`, etc.) | Cloud Function trigger or callable | Client writes are denied by rules |
| Simple single-document write with no dependencies | Direct `set`/`update` | Simplest correct option |

- NEVER use a transaction when a batch suffices (transactions hold
  locks and retry on contention).
- NEVER use client-side writes for operations that require the Auth
  Admin SDK.
- Cloud Functions MUST be idempotent. Retries MUST NOT create
  duplicate side effects.

---

### HR-03: Cache vs Server Truth

- **Server is always the source of truth** for permissions, roles,
  archive state, and any security-relevant data.
- Firestore offline cache MAY be used for read-only display of
  non-sensitive, previously-fetched data (e.g., class names, own
  attendance history).
- Permission-gated screens MUST re-validate the user's current
  role from `AuthBloc` state before rendering. Stale cached roles
  MUST NOT grant access to admin or servant screens.
- On sign-out, archive, or detected permission downgrade, the app
  MUST NOT fall back to cached data. It MUST navigate to the
  appropriate non-authenticated screen.
- `AuthDegraded` state is acceptable ONLY for read-only access with
  a visible degraded-mode indicator. Write operations MUST be
  disabled in degraded mode.
- If the app has been offline for >24 hours, the next successful
  connection MUST trigger a full auth re-check before allowing
  any data mutations.

---

### HR-04: When to Stop and Ask for Clarification

An implementing agent MUST stop and request human clarification
when ANY of the following conditions are true:

1. **Ambiguous requirement:** The spec or task can be interpreted
   in ≥2 materially different ways that affect data schema, user
   experience, or security.
2. **Missing permission model:** The task involves a new write path
   and the spec does not define who is authorized to perform it.
3. **Schema conflict:** The proposed change conflicts with an
   existing Firestore document structure, and the migration path
   is not specified.
4. **Cross-feature side effects:** The change would modify shared
   code (`core/`, `injection.dart`, `firestore.rules`) in a way
   that affects other features.
5. **Security-sensitive operation:** The task involves authentication,
   role changes, custom claims, or Firestore rules, and the spec
   does not provide explicit acceptance criteria for the security
   boundary.
6. **Contradictory requirements:** Two parts of the spec or
   existing code disagree on behavior.
7. **Performance risk:** The implementation would introduce a
   query pattern that could degrade with >1000 documents (e.g.,
   client-side filtering, unbounded collection reads, N+1 queries).

The agent MUST state what it found, what the options are, and what
it recommends — then wait for a decision.

---

### HR-05: Task Breakdown Requirements

Every implementation task MUST meet these criteria:

- **Atomic:** The task produces a single, testable, merge-safe
  change. It MUST NOT require another incomplete task to compile.
- **Bounded:** The task has explicit acceptance criteria that can
  be verified by running tests or inspecting output.
- **Ordered:** Tasks MUST declare dependencies on other tasks.
  A task MUST NOT be started before its dependencies are complete.
- **Scoped:** Each task modifies at most one layer (data, domain,
  or presentation) per feature, unless the change is inherently
  cross-layer (e.g., adding a new end-to-end feature slice).
- **Sized:** A task SHOULD be completable in ≤200 lines of
  production code (excluding generated code and tests). If larger,
  it SHOULD be split.
- **Testable:** Every task that adds or modifies logic MUST include
  the corresponding test(s). A task without tests is not done
  (see HR-06).

Task format:

```
Task N: [short title]
Depends on: [Task M, Task K, ...]
Layer: [data | domain | presentation | infra | rules]
Files: [list of files to create or modify]
Acceptance criteria:
  - [testable criterion 1]
  - [testable criterion 2]
Risks: [known risks or edge cases]
```

---

### HR-06: Definition of Done

A feature is DONE when ALL of the following are true:

- [ ] All tasks in `tasks.md` are marked complete.
- [ ] All acceptance criteria in every task are verified by tests.
- [ ] Unit tests pass: `flutter test` exits with 0 failures.
- [ ] No `TODO` comments remain in the changed code (unless
      explicitly deferred and tracked in a follow-up task).
- [ ] Firestore rules are updated and tested with the emulator
      if the feature touches server access control.
- [ ] Cloud Functions are updated and tested if the feature
      requires backend logic.
- [ ] The DI container (`injection.dart`) correctly wires all new
      dependencies.
- [ ] The router (`app_router.dart`) includes routes for all new
      screens.
- [ ] Lint-clean: `flutter analyze` reports no errors or warnings
      in changed files.
- [ ] Code generation is current: `build_runner build` produces no
      changes to generated files.
- [ ] Documentation: class-level doc comments exist on all new
      public classes.
- [ ] Schema: any new Firestore fields or collections are
      documented in `docs/CODEBASE_FLOW_GUIDE.md` or equivalent.
- [ ] Security: no new write paths bypass the authorization model
      defined in P04 and P05.
- [ ] Performance: no new unbounded queries, no new `Column` with
      dynamic-length children, no leaked stream subscriptions.
- [ ] The feature can be toggled off (if staged) without breaking
      existing functionality.

---

## Governance

### Amendment Procedure

1. Any contributor may propose a constitution amendment by
   documenting the change, its rationale, and its impact.
2. The Project Owner (Kerollos) reviews and approves or rejects.
3. Approved amendments MUST update this document, increment the
   version, and update the `Last Amended Date`.
4. All dependent templates and docs (listed in the Sync Impact
   Report) MUST be updated in the same commit.

### Versioning Policy

This constitution follows semantic versioning:

- **MAJOR:** Removal or redefinition of existing principles.
- **MINOR:** Addition of new principles or sections.
- **PATCH:** Clarifications, typo fixes, non-semantic refinements.

### Compliance Review

- Every feature spec MUST include a "Constitution Check" section
  that lists which principles are most relevant and how the
  design satisfies them.
- Implementing agents MUST self-audit against this constitution
  before submitting work.
- The Project Owner MAY conduct periodic compliance reviews and
  flag violations as P0 bugs.

---

*This constitution is a living document. It evolves with the project
but its principles are non-negotiable unless formally amended.*
