# Phase 1 — Auth & Roles: Research Notes

## R1 — Collection Casing (`Users` vs `users`)
**Decision**: Use `'Users'` (capital U) everywhere.  
**Rationale**: Cloud Functions and security rules already use `Users`; app code was temporarily diverged. Production data lives under `Users`.  
**Action**: Change `FirestoreCollections.users` constant value to `'Users'` and propagate.  
**Risk**: Low — existing documents are already under `Users/`; no migration needed.

## R2 — Splash Screen Auth Dispatch Pattern
**Decision**: `SplashScreen` uses `BlocListener<AuthBloc, AuthState>` with `listenWhen` that fires only once on non-`AuthInitial` states.  
**Rationale**: Matches existing `RoleRouter.listeners()` contract; no duplicate navigation.  
**Pattern**:
```dart
BlocListener<AuthBloc, AuthState>(
  listenWhen: (_, current) => current is! AuthInitial && current is! AuthLoading,
  listener: (context, state) => _navigate(context, state),
  child: _SplashBody(),
)
```

## R3 — AdminGate Role Check
**Decision**: `AdminGate` reads `AuthBloc` from context; if state is not `AuthAuthenticated` with `role == admin`, it calls `Navigator.pushNamedAndRemoveUntil(context, login, ...)`.  
**Rationale**: Prevents back-navigation to admin screens after logout without needing a separate guard cubit.

## R4 — Form Validation
**Decision**: Use Flutter built-in `Form` + `TextFormField` with `validator` callbacks; submit button calls `Form.validate()` before dispatching bloc event.  
**Rationale**: Matches `flutter-building-forms` skill guidance. Keeps validation in the widget (input contract), not in the bloc (business logic). Error display from bloc state (`AuthError.message`) shown in `AuthErrorBanner`.

## R5 — `role_user_route.dart` Removal
**Decision**: Delete file. All role dispatch is in `RoleRouter.resolve()`.  
**Risk**: Check for any import before deletion via `grep_search`.
