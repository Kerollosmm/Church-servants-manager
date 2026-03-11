# Future Improvements

Observations derived from static analysis of the codebase. Priority is ordered: **High** → **Medium** → **Low**.

---

## High Priority

### 1. Duplicate Feature Directories

`lib/features/` contains two near-identical attendance record directories:
- `attendace_recourd/` (typo)
- `attendance_record/`

**Impact:** Dead code confusion, potential import divergence.  
**Fix:** Delete the stale typo directory; verify no imports reference it.

### 2. Missing `@injectable` Code-Gen Adoption

The `injectable` package is declared as a dependency but unused — the DI graph is wired manually in `injection.dart`. This is fine architecturally, but the presence of the dependency without usage adds confusion and an unnecessary build dependency.

**Fix:** Either adopt `@injectable` annotations throughout (and remove the manual wiring) or remove the `injectable` and `injectable_generator` packages from `pubspec.yaml`.

### 3. Test Coverage Gaps

The `test/` directory exists but only covers a fraction of domain logic and repositories. The complex `AttendanceRepository` (1002 lines) and `AuthBloc` have critical paths that are not adequately tested.

**Fix:** Prioritise unit tests for:
- `AttendanceRepository.createSession` (overlap and duplicate detection)
- `AuthBloc` state transitions (especially `AuthDegraded` path)
- `StudentLinkedUserSyncService` (the sync invariant is easy to break silently)

---

## Medium Priority

### 4. `AuthService` Role Creep

`AuthService` currently acts as both an authentication facade and a profile data source (via `lastKnownAppUser` and `getCurrentAppUser`). It partially implements `AuthRepository` while also exposing additional methods not in the interface.

**Fix:** Split into:
- `AuthSessionManager` — Firebase Auth lifecycle only (`signIn`, `signOut`, `authStateChanges`)
- `AuthProfileRepository` — reads and caches the `Users/{uid}` Firestore document

### 5. `AdminTeamService` Placement

`AdminTeamService` and `AdminTeamMembershipService` live under `features/admin/data/` but are used as first-class domain services injected at the app root. They have side effects across both the `team` and `auth` (user document) domains.

**Fix:** Consider promoting them to a shared `services/` layer under `core/` or creating a `features/admin/domain/` layer with orchestration use-cases that call the team and auth repositories.

### 6. Denormalized Data Consistency Risk

`TeamModel.assignedServantName` and `AttendanceSession.studentNameSnapshots` are denormalised. If a servant or student changes their name, these snapshots become stale.

**Fix:** Accept staleness (snapshots are intentional in the attendance case) but document the decision explicitly in the model and consider a Cloud Function trigger to update `Classes/{teamId}.assignedServantName` when `Users/{uid}.name` changes.

### 7. Hive Integration Incomplete

`hive` and `hive_flutter` are declared as dependencies but there are no `@HiveType` annotations or `Hive.openBox` calls in the main codebase. Either Hive is being used for a feature not yet committed, or it's a leftover dependency.

**Fix:** Remove `hive`/`hive_flutter`/`hive_generator` if not needed. If planned for local persistence (e.g., user preferences), implement and document it.

---

## Low Priority / Scalability

### 8. `StudentQueryService` Chunk Size Hard-Coded to 10

Firestore's `whereIn` limit is 30 documents per query. The current chunk size of 10 is conservative and correct, but it's a magic number embedded in the repository logic.

**Fix:** Extract as a named constant (e.g., `_firestoreWhereInLimit = 10`) with a comment explaining the Firestore constraint.

### 9. Clock Stream Polling Interval (15 s)

`AttendanceRepository._watchClock()` polls every 15 seconds. On low-end devices or with many concurrent sessions watched simulataneously, this creates unnecessary timer overhead.

**Fix:** Increase the interval to 30–60 seconds or make it configurable. The only effect is a slightly delayed "session expired" transition in the UI.

### 10. No Pagination on Student and Servant Lists

`ServantDataRepository` and `StudentDataRepository` load the entire collection on first fetch. For large churches, this will cause latency and memory issues.

**Fix:** Implement Firestore cursor-based pagination (`startAfterDocument`) and load data on scroll (lazy loading).

### 11. AppRouter is a Monolithic Switch Statement

The router is a single `switch` with 17 cases. As routes grow, this becomes harder to maintain.

**Fix:** Migrate to `go_router` or `auto_route`, which support strongly-typed routes, nested navigation, and code generation. This also eliminates the manual `RouteArgs` boilerplate.

### 12. `data_seeder.dart` in Production Build

`core/utils/data_seeder.dart` is a dev-only utility that is compiled into the production binary (it's only excluded at runtime via `kDebugMode` guards in the DevTools screen). This adds unnecessary APK size and is a security concern if seed data contains sensitive examples.

**Fix:** Move to `test/` or guard with a conditional import pattern so it is tree-shaken from release builds.

---

## Technical Debt Summary

| Item | Effort | Risk if Ignored |
|---|---|---|
| Stale `attendace_recourd/` directory | Low | Confusion, potential dead imports |
| Unused `injectable` dependency | Low | Minimal |
| Auth service split | Medium | Increasing complexity as auth requirements grow |
| Missing tests on critical paths | High | Regressions in auth/attendance logic |
| List pagination | Medium | Scalability failures with church growth |
| Hive cleanup | Low | Unused dev dependency |
