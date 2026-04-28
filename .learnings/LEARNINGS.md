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
The PR deleted `IServantRepository`, `IStudentRepository`, and stubbed `ITeamRepository`. This caused `ServantDataCubit`, `StudentDataBloc`, and `GetStudentsStreamUseCase` to depend directly on concrete `*DataRepository` classes that import `cloud_firestore`. This violates Clean Architecture's Dependency Inversion Principle and makes unit testing impossible without real Firebase or complex mocking.

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

## [LRN-20260416-001] best_practice

**Logged**: 2026-04-16T17:35:00Z
**Priority**: medium
**Status**: resolved
**Area**: backend

### Summary
Aggressive refactoring often leaves "orphaned" private methods that are no longer referenced.

### Details
Shifting logic from services/BLoCs into state classes or other layers can leave private helper methods unused. In Phase 4, `_tryGetStudentsByQueryFromCache` and `_getStudentsByQueryFromServer` were left in `student_query_service.dart` despite no longer being needed by the updated logic.

### Suggested Action
When deleting or moving logic out of a class, perform a "dead code sweep" by checking for unused private members. `flutter analyze` is the best tool for identifying these `unused_element` warnings.

### Metadata
- Source: user_feedback
- Related Files: lib/features/student/data/services/student_query_service.dart
- Tags: refactoring, dead-code, maintenance, flutter
