# Phase 1 — Authentication & Roles (55% → 100%)

## Goal
Restore the runnable auth/role entry shell so every user type (admin, servant, student) lands on the correct dashboard after login. Fix the `Users`/`users` casing mismatch, wire all auth screens to `AuthBloc`, and enforce `AdminGate` role guards.

## Existing Assets (keep, do not rewrite)
- `AuthBloc` + events + state (fully working)
- `RoleRouter.resolve()` — role-to-screen dispatch
- `RoleRouter.listeners()` — session change listeners
- `AttendanceRepository`, `AuthService`, use cases — untouched by this phase
- `AppRouter.onGenerateRoute` — routing skeleton

## What Is Missing / Broken
1. **Blank screens** — `SplashScreen`, `LoginScreen`, `RegisterScreen`, `VerifyEmailScreen`, `ForgotPasswordScreen` each contain only a `Text('XYZ - Blanked')` body.
2. **`Users` vs `users` casing** — Firestore collection name is `Users` in Cloud Functions and security rules but `users` in app code (or vice versa). Must be unified to `Users` per production schema.
3. **`AdminGate` is a stub** — does not check `AuthBloc` state / role before rendering.
4. **`role_user_route.dart`** — stale file duplicating role routing; must be removed or merged into `RoleRouter`.
5. **`church_app.dart`** — the `home:` widget must be `SplashScreen` (AuthBloc-aware), not any static widget.
6. **Router test** — `app_router_test.dart` has 2 stale route-message expectations.

## Architecture Decisions
- `SplashScreen` listens to `AuthBloc` and pushes to `RoleRouter.resolve()` or `LoginScreen` based on state.
- `LoginScreen` dispatches `AuthEventSignIn`; shows validation errors from `AuthError` state.
- `RegisterScreen` dispatches `AuthEventSignUp`.
- `VerifyEmailScreen` dispatches `AuthEventSendVerification` / polling refresh.
- `ForgotPasswordScreen` dispatches `AuthEventForgotPassword`.
- `AdminGate` reads `AuthBloc` state; if not `AuthAuthenticated` with `UserRole.admin`, push to login.
- Collection path constant `FirestoreCollections.users` → value `'Users'` (capital U).

## Firestore Collection Casing Fix
| Constant | Old Value | Corrected Value |
|----------|-----------|-----------------|
| `FirestoreCollections.users` | `'users'` | `'Users'` |
Propagate to: app constants, security rules (`firestore.rules`), Cloud Functions (`functions/src/index.ts`).

## Files to Create / Modify

### New Widgets (create)
- `lib/features/auth/presentation/widgets/auth_form_field.dart` — shared text field atom
- `lib/features/auth/presentation/widgets/auth_primary_button.dart` — branded CTA button
- `lib/features/auth/presentation/widgets/auth_error_banner.dart` — inline error display

### Screens to Implement (replace blank bodies)
- `splash_screen.dart` — AnimatedLogo + `BlocListener<AuthBloc>` → route dispatch
- `login_screen.dart` — email/password form, sign-in, forgot-password link
- `register_screen.dart` — name/email/password form, sign-up
- `verify_email_screen.dart` — resend + polling refresh CTA
- `forgot_password_screen.dart` — email input, reset email sent confirmation

### Core Changes
- `lib/core/constants/firestore_collections.dart` — set `users = 'Users'`
- `lib/features/admin/presentation/widget/admin_gate.dart` — enforce role guard
- `lib/church_app.dart` — `home: const SplashScreen()`; remove dead `OfflineIndicator` comment
- `lib/role_user_route.dart` — DELETE (functionality lives in `RoleRouter`)
- `firestore.rules` — align `users` → `Users` path
- `functions/src/index.ts` — align collection reference

### Test Fixes
- `test/core/routing/app_router_test.dart` — update 2 stale route-message expectations

## UI Design Reference
- `UI Screens/splash_screen_restored/`
- `UI Screens/login_screen_with_logo/`

## Completion Gate
- [ ] `flutter analyze` passes
- [ ] All 5 auth screens render with real UI
- [ ] Login → correct role dashboard works end-to-end
- [ ] `AdminGate` blocks non-admin routes
- [ ] `Users`/`users` unified across app + rules + functions
- [ ] `app_router_test.dart` passes
