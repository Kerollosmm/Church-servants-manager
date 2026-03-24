# Quickstart: P1 Stability Fixes

## Overview
This feature addresses three high-priority stability issues identified during code review. The goal is to ensure reliable routing, safe state transitions, and race-condition-free attendance taking.

## Key Files to Modify
1. `lib/core/routing/app_router.dart`: Unify DI strategy using `getIt`.
2. `lib/core/routing/role_router.dart`: Implement type-safe pattern matching for `AuthDegraded`.
3. `lib/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart`: Refactor `_runMutation` to use the state-snapshot pattern.

## Implementation Steps

### 1. Unified Router DI [P1-A]
- Locate `_withStudentDataBloc` in `AppRouter`.
- Replace all `context.read<T>()` calls with `getIt<T>()`.
- Ensure all required use cases are passed to the `StudentDataBloc` constructor.

### 2. Type-Safe Role Routing [P1-B]
- Locate the `resolve` method in `RoleRouter`.
- Replace the ternary operator and `as AuthDegraded` cast with a `switch` expression or `if (state case ...)` pattern match.
- Handle fallback cases gracefully (e.g., return `SizedBox.shrink()`).

### 3. Atomic Attendance Mutations [P1-C]
- Update `_runMutation` in `AttendanceTakingCubit`.
- Implement the pattern identified in `research.md`:
  - Set `_isMutating = true` and emit current state with `isMutating: true`.
  - `await action()`.
  - In `finally`, set `_isMutating = false` and emit using the LATEST `state`.

## Verification
- Run `flutter analyze` to ensure no type errors or lint warnings.
- Manually verify navigation to Student screens.
- Manually verify admin "degraded" state handling.
- Verify attendance marking remains responsive during rapid updates.
