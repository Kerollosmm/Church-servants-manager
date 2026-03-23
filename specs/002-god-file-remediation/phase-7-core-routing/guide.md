# Phase 7: Core Routing Decomposition
**Depends on**: Phase 2 complete (auth routing stable)
**Scope**: 1 God file — the app-level role-based routing file.

---

## Files Targeted

| File | Lines | Action |
|------|-------|--------|
| `lib/role_user_route.dart` | 193 | Extract per-role route guards and screen dispatchers |

---

## ⚠️ WARNING

This file is app-wide. A regression here breaks **all navigation**. Read it fully before touching anything. Test the **entire app** navigation after changes.

---

## Step-by-Step Guide

### STEP 1 — Understand the file

`role_user_route.dart` likely contains a `Widget build()` that reads the current auth/role state and returns the appropriate screen or a `RouteGuard`/`GoRouter` redirect.

Read the file and answer:
- Is it a widget? A function? A redirect callback?
- Does it branch on user role? (admin vs servant vs etc.)
- Does it contain inline `if/switch` for role-to-screen mapping?

### STEP 2 — Extract role resolver logic

If there is a block like:
```dart
if (role == 'admin') {
  return AdminHomeScreen();
} else if (role == 'servant') {
  return ServantDashboardScreen();
}
```

Extract this to:
- `lib/core/routing/role_router.dart` — a utility class/function `resolveRoleRoute(String role) → Widget`

### STEP 3 — Update role_user_route.dart

Replace the inline branching with a call to `RoleRouter.resolve(role)`.
Target: < 60 lines.

### STEP 4 — Verify

```bash
flutter analyze
flutter test
```

Manual — test EVERY role path:
- Sign in as Admin → verify you land on the admin screen.
- Sign in as Servant → verify you land on the servant dashboard.
- Sign out → verify you return to login.
- Deep link or route refresh → verify no crash.

> ⚠️ If you are unsure about any routing behavior, write `HUMAN DECISION REQUIRED` and skip that sub-extraction.
