# Phase 7 — Tasks: Core Routing

- [X] T7-01 Read `lib/role_user_route.dart` fully — determine if it is a Widget, function, or guard
- [X] T7-02 List every role branch (admin, servant, user, etc.) and the screen it maps to
- [X] T7-03 Create `lib/core/routing/role_router.dart` with a `resolveRoleRoute(role)` function
- [X] T7-04 Update `role_user_route.dart` to call `RoleRouter.resolve(role)` (target: < 60 lines)
- [X] T7-05 `flutter analyze` + `flutter test`

- [ ] T7-06 Manual: sign in as Admin → verify landing on correct admin screen
- [ ] T7-07 Manual: sign in as Servant → verify landing on servant dashboard
- [ ] T7-08 Manual: sign out → verify return to login screen
- [ ] T7-09 Manual: relaunch app while already signed in → verify role-based routing applies correctly at startup
- [ ] T7-10 Mark Phase 7 complete — all 25 God Files remediated
