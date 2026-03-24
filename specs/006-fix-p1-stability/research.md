# Research: P1 Stability Fixes

## Decision: State Snapshot Pattern for Attendance Mutations [P1-C]

### Rationale
The `AttendanceTakingCubit` currently suffers from a race condition where incoming Firestore snapshots can interfere with the reporting of local mutation results. By capturing the state before the mutation starts and applying only the necessary changes (isMutating, mutationError) to the *latest* available state at the end of the operation, we ensure that:
1. UI feedback (loading/error) is never "lost" due to stream emissions.
2. The UI always displays the most up-to-date roster data from the server.

### Implementation Pattern
```dart
Future<void> _runMutation(...) async {
  // 1. Guard against concurrent mutations
  if (_isMutating) return;
  
  // 2. Local state update
  _isMutating = true;
  _mutationError = null;
  
  // 3. Emit loading state on current data
  if (state is AttendanceTakingLoaded) {
    emit((state as AttendanceTakingLoaded).copyWith(isMutating: true));
  }

  try {
    await action();
    _mutationError = null;
  } catch (e) {
    _mutationError = mapError(e);
  } finally {
    _isMutating = false;
    
    // 4. Final emit using LATEST state to ensure we don't revert roster data
    final finalState = state;
    if (finalState is AttendanceTakingLoaded) {
      emit(finalState.copyWith(
        isMutating: false,
        mutationError: _mutationError,
        clearMutationError: _mutationError == null,
      ));
    }
  }
}
```

## Decision: Unified DI Strategy in AppRouter [P1-A]

### Rationale
`AppRouter` is a configuration class, not a widget. Relying on `BuildContext` via `context.read` inside the router is brittle and inconsistent with the rest of the project's DI strategy. We will transition to 100% `getIt` resolution for all dependencies required during BLoC instantiation within the router.

### Alternatives Considered
- **BlocProvider.value**: Rejected because it requires the BLoC to be created upstream, which complicates the route definitions.
- **Provider-based injection**: Rejected to maintain `getIt` as the single source of truth for services and use cases.

## Decision: Type-Safe Pattern Matching in RoleRouter [P1-B]

### Rationale
The unsafe cast `(state as AuthDegraded)` will be replaced with Dart 3's `if (state case ...)` or exhaustive `switch` expressions. This ensures that even if the `AuthState` sealed class is expanded in the future, the routing logic remains deterministic and crash-free.

### Implementation Pattern
```dart
UserRole.admin => switch (state) {
  AuthAuthenticated() => const AdminDashboardScreen(),
  AuthDegraded(:final message) => AdminRefreshRequiredScreen(message: message),
  _ => const SizedBox.shrink(), // Or fallback error screen
}
```
