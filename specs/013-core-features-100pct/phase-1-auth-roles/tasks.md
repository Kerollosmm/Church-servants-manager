# Phase 1 — Auth & Roles: Task Checklist

## P1-T1 · Fix Firestore Collection Casing
- [ ] P1-T1.1 Open `lib/core/constants/firestore_collections.dart`; change `users` value to `'Users'`
- [ ] P1-T1.2 Search for raw `'users'` string in app code (grep); fix any remaining occurrences
- [ ] P1-T1.3 Update `firestore.rules` — replace `match /users/{uid}` with `match /Users/{uid}`
- [ ] P1-T1.4 Update `functions/src/index.ts` — replace `.collection('users')` with `.collection('Users')`
- [ ] P1-T1.5 Run `flutter analyze` — 0 issues

## P1-T2 · Implement Auth Widget Atoms
- [ ] P1-T2.1 Create `lib/features/auth/presentation/widgets/auth_form_field.dart`
  - Params: `label`, `hint`, `controller`, `validator`, `obscureText`, `textInputAction`, `onSubmitted`
  - Styled per ochre theme
- [ ] P1-T2.2 Create `lib/features/auth/presentation/widgets/auth_primary_button.dart`
  - Params: `label`, `onPressed`, `isLoading`
  - Shows `CircularProgressIndicator` when `isLoading`
- [ ] P1-T2.3 Create `lib/features/auth/presentation/widgets/auth_error_banner.dart`
  - Params: `message`
  - Animated show/hide based on non-null message

## P1-T3 · Implement SplashScreen
- [ ] P1-T3.1 Replace blank body with `BlocListener<AuthBloc>` + logo animation
- [ ] P1-T3.2 On `AuthAuthenticated/AuthDegraded` → `Navigator.pushNamedAndRemoveUntil` to role home
- [ ] P1-T3.3 On `AuthUnauthenticated` → push `/login`
- [ ] P1-T3.4 On `AuthNeedsVerification` → push `/verify-email`
- [ ] P1-T3.5 On `AuthArchived` → show archived message inline
- [ ] P1-T3.6 Dispatch `AuthEventCheckStatus` in `initState` / `PostFrameCallback`
- [ ] P1-T3.7 Widget test: splash navigates to login when unauthenticated

## P1-T4 · Implement LoginScreen
- [ ] P1-T4.1 Build email + password form with `Form` key
- [ ] P1-T4.2 `BlocListener` on `AuthLoading` → disable button; on `AuthError` → show banner
- [ ] P1-T4.3 On `AuthAuthenticated` → handled by `RoleRouter.listeners()` (no manual nav)
- [ ] P1-T4.4 "Forgot password" `TextButton` → push `/forgot-password`
- [ ] P1-T4.5 "Register" `TextButton` → push `/register`
- [ ] P1-T4.6 Widget test: form validation blocks empty submit

## P1-T5 · Implement RegisterScreen
- [ ] P1-T5.1 Name + email + password + confirm-password fields
- [ ] P1-T5.2 Client-side validation (password match, min length 8)
- [ ] P1-T5.3 Dispatch `AuthEventSignUp` on valid submit
- [ ] P1-T5.4 `BlocListener` → on `AuthNeedsVerification` push `/verify-email`
- [ ] P1-T5.5 Widget test: mismatched passwords show error

## P1-T6 · Implement VerifyEmailScreen
- [ ] P1-T6.1 Static info text + "Resend Email" button
- [ ] P1-T6.2 "Resend" dispatches `AuthEventSendVerification`
- [ ] P1-T6.3 "Check Again" dispatches `AuthEventRefreshUser`
- [ ] P1-T6.4 On `AuthAuthenticated` → `RoleRouter` handles navigation
- [ ] P1-T6.5 "Sign Out" dispatches `AuthEventSignOut`

## P1-T7 · Implement ForgotPasswordScreen
- [ ] P1-T7.1 Email field + "Send Reset Link" button
- [ ] P1-T7.2 Dispatch `AuthEventForgotPassword`
- [ ] P1-T7.3 On `AuthPasswordResetSent` → show success message + back button
- [ ] P1-T7.4 Widget test: empty email blocked

## P1-T8 · Fix AdminGate
- [ ] P1-T8.1 Read `AuthBloc` state in `AdminGate.build()`
- [ ] P1-T8.2 If `AuthAuthenticated` && `role == admin` → render `child`
- [ ] P1-T8.3 Otherwise → `SchedulerBinding.addPostFrameCallback` push to `/login`
- [ ] P1-T8.4 Widget test: non-admin triggers redirect

## P1-T9 · Wire `church_app.dart`
- [ ] P1-T9.1 Set `home: const SplashScreen()`
- [ ] P1-T9.2 Remove dead `OfflineIndicator` comment / import
- [ ] P1-T9.3 Confirm `RoleRouter.listeners()` is inside `MultiBlocListener`

## P1-T10 · Remove `role_user_route.dart`
- [ ] P1-T10.1 Grep for imports of `role_user_route.dart` — fix or remove each
- [ ] P1-T10.2 Delete `lib/role_user_route.dart`

## P1-T11 · Fix Router Tests
- [ ] P1-T11.1 Open `test/core/routing/app_router_test.dart`
- [ ] P1-T11.2 Update 2 stale `invalidMessage` string expectations to current values
- [ ] P1-T11.3 Run `flutter test test/core/routing/app_router_test.dart` — all pass

## P1-T12 · Final Gate
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test test/features/auth/` — all pass
- [ ] Manual smoke: login as admin, servant, student → correct dashboard
