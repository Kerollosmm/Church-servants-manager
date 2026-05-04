# Learnings Log

## [LRN-20260407-001] best_practice

**Logged**: 2026-04-07T20:00:00Z
**Priority**: high
**Status**: pending
**Area**: backend

### Summary
When implementing auth/role checks in new repository classes, always match the authoritative implementation's logic exactly — not a simplified version.

### Details
During code review fix for `AttendanceMarkRepository`, the `_canUserManageAttendance` helper was initially implemented with a simplified check (`assignedTeamId == teamId || assignedTeamIds.contains(teamId)`). However, the authoritative `AttendanceRepository.canUserManageAttendance` includes critical checks: archived user rejection, admin role bypass, servant role filtering, and uses `effectiveAssignedTeamIds` (not raw `assignedTeamIds`). The simplified version would have allowed archived users and denied admins not explicitly assigned to teams.

### Suggested Action
When creating auth/permission helpers that mirror existing ones, copy the authoritative implementation's logic verbatim or extract to a shared utility. Never simplify auth checks — every condition exists for a reason.

### Metadata
- Source: code_review
- Related Files: lib/Features/attendance/data/repos/attendance_mark_repository.dart, lib/Features/attendance/data/repos/attendance_repository.dart
- Tags: auth, security, code-review, flutter

---

## [LRN-20260407-003] best_practice

**Logged**: 2026-04-07T20:00:00Z
**Priority**: medium
**Status**: pending
**Area**: backend

### Summary
Dead code methods in repository classes (defined but never called) are often security gaps waiting to be exploited.

### Details
`AttendanceMarkRepository.assertCanWriteMark` was a perfectly implemented validation method that was never called by any write method (`createMark`, `updateMark`, `deleteMark`). This is a defense-in-depth violation — the only protection was Firestore security rules. Always verify that validation methods are actually invoked by their intended callers.

### Suggested Action
When reviewing code, check for methods that are defined but never called — especially auth/validation methods. These are common oversights during feature development.

### Metadata
- Source: code_review
- Related Files: lib/Features/attendance/data/repos/attendance_mark_repository.dart
- Tags: security, dead-code, auth, defense-in-depth

---

## [LRN-20260407-004] best_practice

**Logged**: 2026-04-07T20:00:00Z
**Priority**: medium
**Status**: pending
**Area**: backend

### Summary
Deleting domain-layer interface files couples BLoCs directly to Firebase implementations, destroying testability.

### Details
The PR deleted `IServantRepository`, `IStudentRepository`, and stubbed `ITeamRepository`. This caused `ServantDataBloc`, `StudentDataBloc`, and `GetStudentsStreamUseCase` to depend directly on concrete `*DataRepository` classes that import `cloud_firestore`. This violates Clean Architecture's Dependency Inversion Principle and makes unit testing impossible without real Firebase or complex mocking.

### Suggested Action
Never delete domain interfaces even if they seem redundant. They are the contract that enables testability and implementation swapping. If an interface seems redundant, it's likely still serving the architectural purpose of decoupling layers.

### Metadata
- Source: code_review
- Related Files: lib/Features/servant/domain/repos/i_servant_repository.dart, lib/Features/student/domain/repos/i_student_repository.dart, lib/Features/team/domain/repos/i_team_repository.dart
- Tags: clean-architecture, dependency-inversion, testability, flutter

---

## [LRN-20260407-005] knowledge_gap

**Logged**: 2026-04-07T20:00:00Z
**Priority**: high
**Status**: pending
**Area**: backend

### Summary
Firestore rules comparing `request.time` (server clock) against client-written `DateTime.now()` timestamps will reject valid operations under clock skew.

### Details
Session `startsAt`/`endsAt` are written as client `DateTime.now()`. The `sessionAcceptsMarks` rule compares `request.time` (server time) against these values. A device clock that's even 1-2 minutes off will cause valid attendance marks to be denied by Firestore rules. The fix is to add a grace window (e.g., 5 minutes) in the rules comparison.

### Suggested Action
Never compare server `request.time` against client-written timestamps without a grace window. Always add `duration.value(N, 'm')` tolerance for clock skew.

### Metadata
- Source: code_review
- Related Files: firestore.rules, lib/Features/attendance/data/repos/attendance_session_repository.dart
- Tags: firestore, rules, clock-skew, firebase

---

## [LRN-20260409-001] best_practice

**Logged**: 2026-04-09T00:00:00Z
**Priority**: high
**Status**: pending
**Area**: config

### Summary
Always leverage the Superpower extensions, specifically subagent-driven-development and writing-plans, for robust and reliable task execution.

### Details
Using subagents (e.g., via `subagent-driven-development`) combined with a well-defined plan (`writing-plans`) drastically improves the quality and focus of task output. This approach prevents context degradation, enforces review steps (spec compliance and code quality) for every task, and allows multiple complex operations to be handled efficiently without overwhelming a single session.

### Suggested Action
Whenever tasked with a multi-step coding, refactoring, or feature implementation goal, begin by utilizing the `writing-plans` skill to generate a structured plan. Then, use `subagent-driven-development` to execute the tasks systematically.

### Metadata
- Source: user_feedback
- Related Files: N/A
- Tags: workflow, subagents, superpowers, productivity

---

## [LRN-20260411-001] best_practice

**Logged**: 2026-04-11T00:00:00Z
**Priority**: high
**Status**: pending
**Area**: frontend

### Summary
Prevent UI thread jank by managing `BlocProvider` lifecycle carefully in `StatefulWidget`s and strictly enforcing `const` UI components.

### Details
In Flutter, scrolling or toggling state can cause parent widgets to constantly rebuild. If a `BlocProvider` is instantiated directly inside a `StatelessWidget`'s `build()` method, it will be destroyed and recreated every single time the widget rebuilds. This causes an infinite loop of data re-fetching and blocks the UI thread `LAYOUT` phase, resulting in massive GPU Rasterizer and Animator jank.

### Suggested Action
Always convert components to `StatefulWidget` when they need to instantiate their own `Cubit` or `Bloc`. Initialize the BLoC exactly once inside `initState()` and dispose of it in `dispose()`. Use `BlocProvider.value` in the `build()` method so that Flutter passes down the existing instance without recreating it. Additionally, always use `const` modifiers on stateless shapes, text styles, and icons to aggressively short-circuit rendering operations in large list cards.

### Metadata
- Source: performance_profiling
- Related Files: lib/features/team/presentation/widgets/assign_servant_dialog.dart, lib/features/servant/presentation/screens/servant_dashboard_screen.dart
- Tags: flutter, performance, bloc, state-management, jank, memory-optimization

---

## [LRN-20260429-001] best_practice

**Logged**: 2026-04-29T18:00:00Z
**Priority**: high
**Status**: pending
**Area**: backend

### Summary
Firestore batch operations must account for total operations (500 limit) and ensure atomicity of state changes.

### Details
In `closeSession`, the fallback logic for large groups chunked some updates but not others, and updated the session status in a final batch before ensuring all student aggregates succeeded. This risks leaving a session "partially closed" with incorrect counts if an intermediate batch fails.

### Suggested Action
Always chunk ALL dynamic lists in multi-batch operations. Execute entity updates (aggregates, marks) first, and the final state transition (e.g., `isClosed: true`) only in the absolute final batch to ensure atomicity. Verify total operation counts (`length + 2`) against the 500-operation limit before choosing atomic vs. fallback paths.

### Metadata
- Source: code_review
- Related Files: lib/features/attendance/data/repos/attendance_repository.dart
- Tags: firestore, atomicity, batching, integrity

---

## [LRN-20260429-002] best_practice

**Logged**: 2026-04-29T18:05:00Z
**Priority**: medium
**Status**: pending
**Area**: backend

### Summary
Rollback failures in Use Cases must be rethrown to prevent silent failures and data inconsistency.

### Details
In `ProvisionServantWithAuthUseCase`, rollback errors (e.g., failing to delete a user after a repository error) were caught and logged but not rethrown. This masks the fact that the system is now in an inconsistent state (Auth user created but database record failed).

### Suggested Action
Always `rethrow` in catch blocks handling cleanup or rollbacks within Use Cases. This ensures the failure reaches the UI or orchestration layer, even if the primary error is already being handled.

### Metadata
- Source: code_review
- Related Files: lib/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart
- Tags: use-cases, error-handling, rollback, integrity

---

## [LRN-20260429-003] security_best_practice

**Logged**: 2026-04-29T18:10:00Z
**Priority**: critical
**Status**: pending
**Area**: security

### Summary
Firestore rules must never trust client-provided fields (e.g., email) when looking up sensitive documents if that data is available in the Auth Token.

### Details
A rule trusted `request.resource.data.email` to look up an invitation document. An attacker could provide a victim's email in the JSON body while authenticated as themselves, claiming an invitation they don't own.

### Suggested Action
Always use `request.auth.token.email` or `request.auth.uid` for document lookups in security rules. Never rely on the request body for identity-based lookups unless verified against the auth token.

### Metadata
- Source: code_review
- Related Files: firestore.rules
- Tags: security, firestore-rules, RBAC, spoofing

---

## [LRN-20260429-004] best_practice

**Logged**: 2026-04-29T18:15:00Z
**Priority**: medium
**Status**: pending
**Area**: core

### Summary
Avoid fixed `Future.delayed` for file I/O cleanup; use the operation's completion signal.

### Details
Temporary files were being deleted after a fixed 1-minute delay after sharing. This created a race condition: if the user took >1 minute to complete the share action, the source file was deleted, causing the share to fail.

### Suggested Action
`await` the sharing operation (most Flutter sharing plugins return a `Future` that completes when the UI is dismissed) and delete the file immediately after.

### Metadata
- Source: code_review
- Related Files: lib/core/utils/data_export_service.dart
- Tags: race-condition, cleanup, IO, flutter

---

## [LRN-20260429-005] security_best_practice

**Logged**: 2026-04-29T18:20:00Z
**Priority**: high
**Status**: pending
**Area**: backend

### Summary
Use allowlists instead of blacklists for security mutation checks in Use Cases.

### Details
`CanMutateStudentUseCase` used a blacklist to prevent servants from editing fields like `role` or `isArchived`. This is "fail-open" logic; if a new sensitive field (like `classId` or metadata) is added and not explicitly added to the blacklist, it becomes editable by unauthorized users.

### Suggested Action
Implement an explicit allowlist by creating a "candidate" object using `existing.copyWith(...)` with only allowed fields from the `updated` object. Then verify `updated == candidate`. This ensures only intended fields can be changed.

### Metadata
- Source: code_review
- Related Files: lib/features/student/domain/usecases/can_mutate_student_usecase.dart
- Tags: security, use-cases, allowlist, validation

---

## [LRN-20260429-006] best_practice

**Logged**: 2026-04-29T18:25:00Z
**Priority**: medium
**Status**: pending
**Area**: backend

### Summary
Avoid silent data truncation by removing or parameterizing hardcoded `.limit()` calls in streams.

### Details
Several student streams had a hardcoded `.limit(100)`. In a project with 500+ students, the UI would silently show incomplete data with no indication to the user or developer why records were missing.

### Suggested Action
Remove hardcoded limits from live-updating streams unless they are part of a pagination contract. If a limit is required for performance, it must be exposed to the UI/caller or handled via cursor-based pagination.

### Metadata
- Source: code_review
- Related Files: lib/features/student/data/services/student_query_service.dart
- Tags: firestore, truncation, streams, pagination

---

## [LRN-20260429-007] best_practice

**Logged**: 2026-04-29T18:30:00Z
**Priority**: high
**Status**: pending
**Area**: backend

### Summary
Ensure atomicity in invitation-to-user conversion by including both operations in a single Firestore transaction.

### Details
`AuthUserProfileStore.saveUser` updated the invitation status inside a transaction but wrote the user document outside of it. If the user document write failed (e.g., due to a rule violation or network drop), the invitation would be marked "claimed" but the user would have no profile.

### Suggested Action
Include all related cross-collection writes inside the `runTransaction` callback. Use `transaction.set()` for the secondary document within the same block.

### Metadata
- Source: code_review
- Related Files: lib/features/auth/data/services/auth_user_profile_store.dart
- Tags: firestore, transactions, atomicity, invitation-flow

---

## [LRN-20260503-001] best_practice

**Logged**: 2026-05-03T12:00:00Z
**Priority**: high
**Status**: pending
**Area**: architecture

### Summary
Proper dependency injection scoping and manual `getIt` registration requirements.

### Details
When replacing a global `Provider` (e.g., inside `main.dart` or `church_app.dart`) with a route-scoped provider (e.g., inside `app_router.dart`), you must ensure that all widgets in that route are wrapped by the new `BlocProvider`. Additionally, when using `getIt` for manual dependency injection (if `build_runner` generation is absent or failing), any new BLoC or Repository (e.g., `AdminDashboardBloc`, `ITeamRepository`) MUST be manually registered in the `configureDependencies` function in `injection.dart`. Failing to do so causes a fatal `GetIt` exception at startup (`Object/factory with type X is not registered`).

### Suggested Action
After removing a global provider, immediately trace the route hierarchy to add a scoped provider. Always double-check `injection.dart` for manual registrations if `build_runner` is not being actively used. Run `dart analyze` and tests to verify dependency graphs before committing.

### Metadata
- Source: error
- Related Files: lib/core/routing/app_router.dart, lib/core/di/injection.dart, lib/main.dart
- Tags: dependency-injection, getIt, provider, scoping, architecture

---

## [LRN-20260503-002] best_practice

**Logged**: 2026-05-03T12:05:00Z
**Priority**: high
**Status**: pending
**Area**: tooling

### Summary
Avoid parallel file replacements on the same file to prevent race conditions.

### Details
When using the Gemini/Claude replace tool, dispatching multiple concurrent replacements on the exact same file path can cause a race condition (file editing collision). This results in only one of the edits succeeding, while the others are dropped or overwritten, leading to persistent compilation errors.

### Suggested Action
Always execute file replacements sequentially when targeting the same file. Alternatively, read the file, apply all changes to the content string, and use the `write_file` tool to overwrite the file in a single operation.

### Metadata
- Source: error
- Related Files: N/A
- Tags: tooling, concurrency, file-io, race-condition

---

## [LRN-20260503-003] best_practice

**Logged**: 2026-05-03T12:10:00Z
**Priority**: critical
**Status**: pending
**Area**: behavior

### Summary
Always invoke `memory-management` and `self-improvement` skills proactively on any task.

### Details
The user explicitly mandated that the `memory-management` and `self-improvement` (or `self-improving-agent`) skills must ALWAYS be invoked on any similar tasks and in any section later. This ensures context is decoded properly using internal language and that learnings, errors, and feature requests are continuously logged and promoted to prevent recurring issues.

### Suggested Action
At the beginning of any task or when starting a new conversation, explicitly activate the `memory-management` and `self-improvement` skills alongside other domain-specific skills (like `using-superpowers`).

### Metadata
- Source: user_feedback
- Related Files: N/A
- Tags: workflow, memory, self-improvement, continuous-learning
