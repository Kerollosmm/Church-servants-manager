# Research: Pre-Deploy Security & Stability Fixes

**Branch**: `004-security-stability-fixes` | **Date**: 2026-03-22
**Input**: Pre-deployment audit findings + Flutter/Firebase best practices

---

## Research Area 1: Firestore Security Rules Design

**Decision**: Author role-based Firestore Security Rules using `request.auth.token`
custom claims **or**, since this project stores roles in a Firestore `Users` document
(not Firebase custom claims), use a `get()` call to `Users/{uid}` inside the rules to
read the role at write-time.

**Rationale**: Firebase Custom Claims would be the fastest check (no extra Firestore
read), but the app currently stores roles in Firestore (`Users/{uid}.role`).
Migrating to custom claims requires backend Admin SDK work outside this scope.
Using `get()` in rules is the pragmatic zero-migration-cost solution.
The `get()` call is cached by Firestore within a single rule evaluation.

**Alternatives considered**:
- **Custom Claims (JWT)**: Best performance, zero Firestore reads in rule evaluation.
  Rejected: requires Cloud Function or Admin SDK to set claims on role change — out of scope.
- **Flat field on Auth profile**: Not supported by Firebase without custom claims.
- **Security rules + Firestore get()**: Chosen — enables role-based rules without schema change.

**Findings**:
- `request.auth.uid` is always available in rules when the user is authenticated.
- `get(/databases/$(database)/documents/Users/$(request.auth.uid)).data.role` reads the
  role from Firestore within the rule evaluation. This is a single document read cached
  per request batch.
- Firestore rules support the helper pattern `function isAdmin() { return get(...).data.role == 'admin'; }`.
- Rules file: `firestore.rules` at repository root, deployed via `firebase deploy --only firestore:rules`.

**Critical paths to protect**:
| Collection Path | Write Operations | Allowed Roles |
|---|---|---|
| `Classes/{teamId}/attendance_sessions` | create, update, delete | admin |
| `Classes/{teamId}/attendance_sessions/{sid}/marks` | create, update, delete | admin, servant (own team) |
| `Students/{docId}` | create, update, delete | admin |
| `Users/{uid}` | update | admin (or own profile fields only) |
| `Classes/{teamId}` | create, update, delete | admin |

---

## Research Area 2: Actor Identity (archivedByUserId)

**Decision**: Extend `deleteStudent` and `restoreStudent` in `StudentDataRepository`
to accept a `String performedByUid` parameter. Pass the uid to Firestore.

**Rationale**: The `IStudentRepository` interface and all callers (`DeleteStudentUseCase`,
`RestoreStudentUseCase`) already receive an `AuthUser` in the context of the BLoC/cubit.
The change is addable without breaking the frozen model (`freezed` not used here — it's
a plain class). The calling chain:
`StudentDataBloc` → `DeleteStudentUseCase.call(student, performedBy: authUser)` →
`StudentDataRepository.deleteStudent(id, performedByUid: authUser.uid)`.

**Alternatives considered**:
- Pass full `AuthUser`: More type-safe but increases coupling between data layer and auth domain.
- Pass just `uid` string: Minimal coupling, sufficient for audit fields. **Chosen.**
- Store `performedBy` in use case (not repo): Violates Repository Layer principle — data
  write logic belongs in the repository. Rejected.

---

## Research Area 3: Idempotent Logout

**Decision**: Remove the `else throw UserNotLoggedInAuthException()` branch from
`FirebaseAuthProvider.logOut()`. When `_auth.currentUser == null`, return immediately.

**Rationale**: Firebase's `signOut()` is itself idempotent — calling it when signed out
does nothing. The guard was defensive but created a double-logout failure mode.

**Alternatives considered**:
- Catch the error in `AuthBloc._onSignOut`: Hides root cause. Rejected.
- Debounce `AuthEventSignOut`: Unnecessary complexity. Rejected.

---

## Research Area 4: watchActiveSessionForTeam Query Optimization

**Decision**: Add an independent `watchOpenSessionsForTeam` private method in
`AttendanceRepository` that queries with `.where('isClosed', isEqualTo: false)`.
Use this stream instead of `watchSessionsForTeam` inside `watchActiveSessionForTeam`.

**Rationale**: `watchSessionsForTeam` is still needed by `AttendanceHistoryScreen`
(which needs all sessions). Creating a separate query method avoids breaking that usage
while fixing the active-session scan.

**Alternatives considered**:
- Add a `limitToOpen: bool` param to `watchSessionsForTeam`: Introduces conditional
  query branching inside one method. Less clean. Rejected.
- Client-side filter via `.where()` on the stream: Downloads all sessions first.
  Defeats the purpose. Rejected.

**Firestore index implication**: The query `where('isClosed', isEqualTo: false)`
on `attendance_sessions` sub-collection requires a composite index if combined with
`orderBy`. Since `watchOpenSessionsForTeam` only needs the currently active session,
no `orderBy` is needed — single-field index on `isClosed` is sufficient and auto-created.

---

## Research Area 5: N+1 Read Elimination in getTeamAttendanceStats

**Decision**: Replace the sequential `await _marksCol(...).get()` inside the `for` loop
with `await Future.wait(sessions.map((s) => _marksCol(teamId, s.id).get()))`.

**Rationale**: All session mark fetches are independent — parallelizing with
`Future.wait` is the standard Dart pattern. For 50 sessions, latency drops from
~50× single-read latency to ~1× max-latency-among-all.

**Risk management**: Firestore allows up to 500 concurrent operations per document batch.
50 sessions is well within limits. No throttling needed.

**Alternatives considered**:
- Denormalized stats counters (written at session close): Best long-term solution but
  requires schema migration + Cloud Function. Out of scope for this sprint.
- Paginate stats: Reduces reads but returns partial stats. Rejected for accuracy.

---

## Research Area 6: Unbounded Reads in getStudentAttendanceStats

**Decision**: Add a `DateTime? since` parameter to `_loadStudentSessions`, defaulting
to `DateTime.now().subtract(const Duration(days: 180))` (6 months). Apply this as a
Firestore `.where('startsAt', isGreaterThanOrEqualTo: since)` filter on the
`_studentSessionsQuery`.

**Rationale**: 6 months of sessions is a reasonable operational window. If admins need
all-time stats, a separate "full history" export feature can be built later.
Capping at 6 months limits parallel reads to a manageable number (typically <50 for
weekly sessions).

**Firestore index implication**: `collectionGroup` query on `attendanceSessions` with
`where('studentIdsSnapshot', arrayContains: ...)` + `where('startsAt', >=)` requires
a composite index. This index MUST be declared in `firestore.indexes.json`.

---

## Research Area 7: DevTools Route Guard

**Decision**: Wrap the `devTools` case in `AppRouter.onGenerateRoute` with
`if (kDebugMode)` using `dart:foundation`. In release, the case is dead code and
is removed by the Dart tree-shaker.

**Rationale**: `kDebugMode` is a compile-time constant in Dart — the if-branch is
eliminated entirely in release/profile builds. This is the Flutter-idiomatic approach.

**Note**: The route constant `devTools` in `core/constants/routes.dart` can remain
defined — unused constants are also tree-shaken. No changes needed to `Routes`.

---

## Summary of All Decisions

| Finding | Decision | Files Affected |
|---------|----------|----------------|
| C1 — No security rules | Add `firestore.rules` with role-based write guards | `firestore.rules` (new) |
| C2 — `'system'` actor | Add `performedByUid` param to delete/restore | `student_data_repository.dart`, `i_student_repository.dart`, `delete_student_usecase.dart`, `restore_student_usecase.dart`, `student_data_bloc.dart` |
| H1 — N+1 team stats reads | Parallelize with `Future.wait` | `attendance_repository.dart` |
| H2 — Unbounded student stats | Cap at 6 months via `since` param | `attendance_repository.dart` |
| H3 — Full session stream | New `_watchOpenSessionsForTeam` method | `attendance_repository.dart` |
| H4 — Logout throws | Remove `else throw` branch | `firebase_auth_provider.dart` |
| M3 — DevTools in release | Guard with `kDebugMode` | `app_router.dart` |
| L1 — Mixed CRLF | Add `.gitattributes` | `.gitattributes` (new) |
