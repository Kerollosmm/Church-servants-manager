# Auth Fixes TODO List

- [ ] Update AuthUser model with `requiresTokenRefresh` flag
- [ ] Update Firestore rules to allow self-update of refresh flag
- [ ] Refactor FirebaseAuthRepository (GAP 1 & 2)
- [ ] Add AuthRoleRefreshing and AuthRoleUpdated states to AuthBloc
- [ ] Update RoleUserRoute to handle refresh states and banners
- [ ] Verify fix via manual Firestore flag trigger and unit tests
