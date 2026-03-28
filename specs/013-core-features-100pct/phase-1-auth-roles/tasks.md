# Phase 1 - Auth & Roles: Task Checklist (Logic Only)

> **Scope**: Data layer, BLoC logic, routing guards, collection constants, Cloud Functions, security rules, and tests.
> No UI/widget code.

## P1-T1 - Fix Firestore Collection Casing
- [x] P1-T1.1 Open `lib/core/constants/firestore_collections.dart`; change `users` constant value to `'Users'`
- [x] P1-T1.2 Grep entire `lib/` for raw string `'users'`; update any remaining call sites
- [x] P1-T1.3 Update `firestore.rules` - replace every `match /users/{uid}` path with `match /Users/{uid}`
- [x] P1-T1.4 Update `functions/src/index.ts` - replace `.collection('users')` with `.collection('Users')`
- [x] P1-T1.5 Run `flutter analyze` - 0 issues

## P1-T2 - Fix AdminGate Role Logic
- [x] P1-T2.1 Open `lib/features/admin/presentation/widget/admin_gate.dart`
- [x] P1-T2.2 Read `AuthBloc` state from context; allow `child` only on `AuthAuthenticated` with `role == UserRole.admin`
- [x] P1-T2.3 On any other state, schedule `Navigator.pushNamedAndRemoveUntil(login)` via `SchedulerBinding.addPostFrameCallback`
- [x] P1-T2.4 Unit test: `AdminGate` logic branch - admin passes, servant redirects, unauthenticated redirects

## P1-T3 - Fix `church_app.dart` Entry Wiring
- [x] P1-T3.1 Set `home: const SplashScreen()` (SplashScreen already dispatches `AuthEventCheckStatus`)
- [x] P1-T3.2 Remove dead `OfflineIndicator` import/comment
- [x] P1-T3.3 Confirm `RoleRouter.listeners()` is registered in `MultiBlocListener` in `church_app.dart`

## P1-T4 - Remove Stale `role_user_route.dart`
- [x] P1-T4.1 Grep for imports of `role_user_route.dart` across `lib/`; remove or redirect each
- [x] P1-T4.2 Delete `lib/role_user_route.dart`
- [x] P1-T4.3 Run `flutter analyze` - 0 issues

## P1-T5 - Fix Router Tests
- [x] P1-T5.1 Open `test/core/routing/app_router_test.dart`
- [x] P1-T5.2 Update 2 stale `invalidMessage` string expectations to match current `AppRouter` values
- [x] P1-T5.3 Run `flutter test test/core/routing/app_router_test.dart` - all pass

## P1-T6 - Auth BLoC Handler Hardening
- [x] P1-T6.1 Open `auth_bloc_handlers.dart`; verify `_handleSignOut` cancels `_authStateSubscription` before `super.close()` (already in `close()` - confirm order is correct)
- [x] P1-T6.2 Verify `_handleCheckStatus` cannot emit twice on rapid `AuthEventCheckStatus` events (add `transformer: droppable()` or guard with `state is AuthLoading` check)
- [x] P1-T6.3 Unit test: rapid double-dispatch of `AuthEventCheckStatus` emits exactly one `AuthLoading` state

## P1-T7 - Validate `RoleRouter.resolve()` Logic
- [x] P1-T7.1 Confirm `RoleRouter.resolve()` handles all `UserRole` values - no missing switch arm
- [x] P1-T7.2 Confirm `AuthDegraded` for admin still serves `AdminRefreshRequiredScreen` (not blank)
- [x] P1-T7.3 Unit test: `RoleRouter.resolve()` returns correct screen type per role + state combination

## P1-T8 - Final Gate
- [x] `flutter analyze` - 0 issues
- [x] `flutter test test/features/auth/` - all pass
- [x] `flutter test test/core/routing/` - all pass
