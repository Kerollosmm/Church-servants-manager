# Phase 1 — Authentication & Roles (Logic Only)

## Goal
Fix the foundational logic issues that prevent auth from working end-to-end: collection casing mismatch, `AdminGate` stub, stale `role_user_route.dart`, and brittle `AuthBloc` handler edge cases.

## Existing Assets (keep, do not rewrite)
- `AuthBloc` + all event handlers — working
- `RoleRouter.resolve()` and `RoleRouter.listeners()` — working
- All auth use cases (`SignInUseCase`, `SignOutUseCase`, `ObserveAuthStateUseCase`, etc.)
- `AppRouter.onGenerateRoute` — routing skeleton intact

## What Is Being Fixed (Logic Only)

### 1. `Users` vs `users` Casing Mismatch
- `FirestoreCollections.users` constant value corrected to `'Users'`
- Propagated to: `firestore.rules`, `functions/src/index.ts`, any raw string call sites in `lib/`

### 2. `AdminGate` Logic Stub
- Current: renders `child` unconditionally
- Fix: reads `AuthBloc` state; blocks non-admin access; schedules push to `/login` via `SchedulerBinding.addPostFrameCallback`

### 3. Stale `role_user_route.dart`
- Duplicate routing logic — remove file after fixing all import references
- All role dispatch stays in `RoleRouter`

### 4. `church_app.dart` Entry Wiring
- Set `home: const SplashScreen()` so `AuthEventCheckStatus` is dispatched at startup
- Remove dead `OfflineIndicator` reference
- Confirm `RoleRouter.listeners()` is inside `MultiBlocListener`

### 5. `AuthBloc` Handler Hardening
- Guard `_handleCheckStatus` against rapid-fire double-dispatch (add `droppable()` transformer or early return if already `AuthLoading`)
- Verify `close()` cancels subscription correctly

### 6. Stale Router Test Expectations
- `app_router_test.dart` has 2 expectations with old `invalidMessage` strings — update to current values

## Files Changed (Logic Only)
| File | Change |
|------|--------|
| `lib/core/constants/firestore_collections.dart` | `users` → `'Users'` |
| `firestore.rules` | path casing fix |
| `functions/src/index.ts` | collection name fix |
| `lib/features/admin/presentation/widget/admin_gate.dart` | role guard logic |
| `lib/church_app.dart` | home wiring + dead code removal |
| `lib/role_user_route.dart` | DELETE |
| `lib/features/auth/presentation/bloc/auth_bloc_handlers.dart` | droppable guard |
| `test/core/routing/app_router_test.dart` | stale expectation fix |

## Completion Gate
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test test/features/auth/` — all pass
- [ ] `flutter test test/core/routing/` — all pass
