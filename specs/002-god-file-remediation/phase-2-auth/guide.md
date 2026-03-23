# Phase 2: Auth Feature Decomposition
**Depends on**: Phase 1 complete (auth_bloc.dart ≤120 lines)
**Scope**: Split `login_screen.dart` and `register_screen.dart`.

---

## Files Targeted

| File | Lines | Action |
|------|-------|--------|
| `lib/features/auth/presentation/screens/login_screen.dart` | 205 | Extract form+validators to widget |
| `lib/features/auth/presentation/screens/register_screen.dart` | 160 | Extract form to widget |

---

## Step-by-Step Guide

### STEP 1 — Login Screen

**Target**: Reduce `login_screen.dart` to ~80 lines. It should only: build a `Scaffold`, show a `BlocConsumer<AuthBloc, AuthState>`, and delegate rendering to sub-widgets.

1. Open `login_screen.dart`.
2. Find the email/password form fields (likely a `Form` widget). Extract the entire `Form` into:
   - `lib/features/auth/presentation/widgets/login_form.dart`
   - This widget exposes `onSubmit(String email, String password)` callback.
3. Find any inline validators (if not already in `form_validators.dart`). Extract to:
   - `lib/core/utils/form_validators.dart`
4. Find the logo/header UI (if any). Extract to:
   - `lib/features/auth/presentation/widgets/auth_header.dart`
5. In `login_screen.dart`, replace extracted sections with imports of the new widgets.
6. Verify `login_screen.dart` is now < 100 lines.

---

### STEP 2 — Register Screen

**Target**: Reduce `register_screen.dart` to ~80 lines.

1. Same approach: find the form, extract it to:
   - `lib/features/auth/presentation/widgets/register_form.dart`
2. If `auth_header.dart` was created in STEP 1, reuse it.
3. Verify `register_screen.dart` is now < 90 lines.

---

### STEP 3 — Verify

```bash
flutter analyze
flutter test
```

Manually sign in → verify login works. Manually attempt registration → verify register works.
