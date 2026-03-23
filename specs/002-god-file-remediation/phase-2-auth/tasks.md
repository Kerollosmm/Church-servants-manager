# Phase 2 — Tasks: Auth Screens

- [X] T2-01 Read `login_screen.dart` — list all widgets and logic blocks in the build method
- [X] T2-02 Create `lib/features/auth/presentation/widgets/login_form.dart` (extracts the email/password Form)
- [X] T2-03 Create `lib/core/utils/form_validators.dart` (if inline validators exist and are not already centralized)
- [X] T2-04 Create `lib/features/auth/presentation/widgets/auth_header.dart` (logo/header if > 10 lines)
- [X] T2-05 Update `login_screen.dart` to use extracted widgets (target: < 100 lines)
- [X] T2-06 `flutter analyze` + `flutter test`

- [X] T2-07 Read `register_screen.dart` — list all widgets and form fields
- [X] T2-08 Create `lib/features/auth/presentation/widgets/register_form.dart`
- [X] T2-09 Reuse `auth_header.dart` if applicable
- [X] T2-10 Update `register_screen.dart` to use extracted widgets (target: < 90 lines)
- [X] T2-11 `flutter analyze` + `flutter test`

- [ ] T2-12 Manual verification: sign in with valid credentials → success
- [ ] T2-13 Manual verification: sign in with invalid credentials → error shown correctly
- [ ] T2-14 Manual verification: register new account → success
