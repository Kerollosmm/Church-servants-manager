# Phase 1 Annotations

## T1-01 `auth_bloc.dart`

- Constructor: wires auth event handlers and subscribes to live auth session updates.
- `_emitResolution`: maps session-resolution results to presentation states.
- `_onCheckStatus`: bootstraps the initial auth state.
- `_onSignIn`: delegates login and emits resolved auth state.
- `_onSignUp`: delegates registration and transitions to verification-needed.
- `_onSignOut`: delegates logout and clears the session state.
- `_onSendVerification`: triggers a verification email flow.
- `_onForgotPassword`: triggers the reset-password flow.
- `_onRefreshUser`: refreshes the cached/current app user.
- `_onSessionChanged` / `_onSessionError`: react to live session updates and fallback states.

## T1-08 `servant_data_cubit.dart`

- Constructor: receives servant CRUD/filter use cases and initializes pagination state.
- `loadServants`: validates admin access, resets paging, and loads the first page.
- `searchServants`: applies in-memory filtering over the loaded servant cache.
- `createServant`: provisions linked auth when needed, persists the servant, then updates state.
- `updateServant`: persists servant edits and reloads the canonical list.
- `deleteServant`: archives servant records and linked auth, then updates visible state.
- `restoreServant`: restores archived servant records and linked auth.
- `refreshServants` / `loadMoreServants`: refresh or paginate while preserving local filters.

## T1-17 `student_data_bloc.dart`

- Constructor: wires student load/search/mutation events to delegated handlers.
- `refresh`: schedules a refresh cycle and completes when the next stream update lands.
- `_onLoadStudents`: sets filters and subscribes to the appropriate Firestore stream.
- `_onSearchStudents`: applies local search or resubscribes when filters change.
- `_onCreateStudent`: validates permissions, optionally provisions auth, then creates the student.
- `_onUpdateStudent`: validates existing data and role-change rules before updating.
- `_onDeleteStudent`: archives the student and linked auth account.
- `_onRestoreStudent`: restores archived student data and linked auth account.
- `_onStreamUpdated` / `_onStreamError`: reconcile stream emissions into UI-facing state.

## T1-26 `team_cubit.dart`

- Constructor: receives team load/create/assignment use cases and keeps selected-team state.
- `loadTeamsByGroup` / `loadAllTeams`: load scoped or global team lists.
- `createTeam`: creates a team then reloads the affected group.
- `updateTeam` / `deleteTeam` / `restoreTeam`: delegate team mutations and emit feedback.
- `selectTeam`: updates the currently selected team without reloading.
- `assignServant` / `unassignServant`: manage responsible-servant assignments.
- `setTeamMembers`: updates the selected student membership list for a team.
