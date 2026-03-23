# Phase 2 Tasks — Auth & Splash Screens

## Prerequisites
- [x] Phase 1 complete — all atoms/molecules/organisms available
- [x] Verify `flutter analyze` passes from Phase 1

---

## Task 2.1 — Create/Update Splash Screen
**File:** `lib/features/auth/presentation/screens/splash_screen.dart`

- [x] Create `SplashScreen extends StatefulWidget` (or update existing)
- [x] Add `AnimationController` with 400ms duration, `vsync: this`
- [x] Add `CurvedAnimation(curve: Curves.easeOut)`
- [x] Build `Animation<double>` for scale (0.8 → 1.0) and fade (0.0 → 1.0)
- [x] In `build`: wrap logo in `FadeTransition` + `ScaleTransition`
- [x] Place `logo_elkarooz.png` centered with `SizedBox(height: 120)`
- [x] App name below in `Theme.of(context).textTheme.displayLarge` style
- [x] Decorative blobs: `AppGradientDecoration` at top-left and bottom-right corners
- [x] `initState`: call `_controller.forward()` then navigate after 2s if already authenticated
- [x] Use `Hero(tag: 'app_logo')` around logo widget for shared element transition
- [x] Scaffold background: `AppColors.background`
- [x] Verify: no `setState` outside of animation (use controller listeners only)
- [x] `flutter analyze` → 0 errors

## Task 2.2 — Hero Tag in AppLogo Widget
**File:** `lib/core/widgets/app_logo.dart`

- [x] Add optional `bool enableHero = false` and `String heroTag = 'app_logo'` params
- [x] Wrap image in `Hero` widget when `enableHero == true`
- [x] Verify `const` constructor preserved

## Task 2.3 — Refactor Login Screen
**File:** `lib/features/auth/presentation/screens/login_screen.dart`

### Layout Structure
- [x] Replace entire `build()` with `AppScreenShell` wrapper
- [x] Inside: `Column` with `AppHeader(showLogo: true, title: 'الكنيسة')`
- [x] Below header: centered `AppSectionCard` containing the form
- [x] Use `Directionality(textDirection: TextDirection.rtl)` at root of this screen

### Form
- [ ] Extract `_LoginForm extends StatelessWidget` private class
  - [x] `Form` widget with `GlobalKey<FormState>`
  - [x] `AppInputField` for email (`TextInputType.emailAddress`, leading email icon)
  - [x] `SizedBox(height: AppSpacing.spacingM)` between fields
  - [x] `AppInputField` for password (`obscureText: true`, leading lock icon)
  - [x] `AppTextButton` for "نسيت كلمة المرور؟" (Forgot password) — aligned end
  - [x] `SizedBox(height: AppSpacing.spacingL)`
  - [x] `AppPrimaryButton(label: 'تسجيل الدخول', isLoading: state.isSubmitting)`
  - [x] Full-width button: wrap in `SizedBox(width: double.infinity)`

### BLoC Integration
- [x] Keep `BlocConsumer<AuthBloc, AuthState>` as outer wrapper
- [x] On `AuthSuccess` state → GoRouter navigates away (no change to existing logic)
- [x] On `AuthFailure` state → show `_LoginError` widget below the button
- [x] `_LoginError` is a private `StatelessWidget` that shows red text with icon

### Hero Tag
- [x] Add `AppHeader` with `AppLogo(enableHero: true)` so hero transitions from splash

### Validation
- [x] Email validator: non-empty + basic email format check
- [x] Password validator: non-empty, min 6 chars

## Task 2.4 — Routing Check
**File:** `lib/core/routing/app_router.dart` (or equivalent)

- [x] Confirm there is a `/splash` or `/` initial route pointing to `SplashScreen`
- [x] Confirm the auth redirect guard exists and works with the new splash screen
- [ ] Run app in debug mode and verify: Splash → auto-navigate to Login or Dashboard

## Task 2.5 — Widget Tests
**File:** `test/features/auth/login_screen_test.dart`

- [x] Create test file
- [x] Test 1: Login screen renders email and password fields
- [x] Test 2: Tapping login button with empty fields shows validators
- [x] Test 3: `AppPrimaryButton` shows loading indicator when BLoC emits loading state
- [x] Use `MockAuthBloc` (mockito/mocktail)
- [x] Run: `flutter test test/features/auth/`

## Task 2.6 — Visual QA
- [ ] Build and run in debug: `flutter run`
- [ ] Compare login screen visually against Stitch screenshot:
  - ✅ Logo visible at top
  - ✅ Ochre button (#a58255) with white text
  - ✅ Input fields have subtle fill + ochre border
  - ✅ RTL layout (Arabic text right-aligned)
  - ✅ Background is #f7f7f6 (off-white)
  - ✅ No sharp corners anywhere
  - ✅ No pure black colors
- [ ] Test hero animation: launch splash → observe logo animates → transitions to login screen

## Task 2.7 — Final Check
- [x] `flutter analyze` → 0 issues
- [x] `flutter test` → all tests pass
