# Phase 2 - Auth Screens

## Goal
Refactor authentication entry flow UI with clean separation between presentation and auth logic.

## UI Inputs
- `UI Screens/splash_screen_restored`
- `UI Screens/login_screen_with_logo`

## Target Screens
- `lib/features/auth/presentation/screens/splash_screen.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`

## Plan
1. Build screen structure to visually match provided UI images.
2. Extract auth-specific UI sections into small widgets under `features/auth/presentation/widgets`.
3. Keep state/actions in `AuthBloc`; no service calls directly from widgets.
4. Apply consistent header/logo style from phase 1 foundation.
5. Ensure keyboard-safe, responsive login layout.

## Verification
- widget tests for splash and login
- manual visual compare with UI image files
- `flutter analyze`
