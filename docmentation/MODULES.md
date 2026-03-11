# Modules

---

## Auth

**Purpose:** Manages user identity, session state, and role resolution.

**Key Files:**

| File | Description |
|---|---|
| `data/models/auth_user.dart` | `@freezed` model: `uid`, `email`, `name`, `role`, `isEmailVerified`, `isArchived`, `assignedTeamIds`, archive audit fields |
| `data/services/firebase_auth_provider.dart` | Wraps `FirebaseAuth` and `AuthUserProfileStore`; returns `AuthUser` with Firestore-enriched data |
| `data/services/auth_service.dart` | Domain-facing facade. Implements `AuthRepository`. Caches `lastKnownAppUser` for degraded-mode recovery |
| `data/services/auth_user_profile_store.dart` | Reads and writes the user's document in the `Users` Firestore collection |
| `data/services/admin_user_provisioning_service.dart` | Admin-only: creates servant accounts, resets passwords, archives/restores users |
| `presentation/bloc/auth_bloc.dart` | Global BLoC. 9 states: `Initial → Loading → Authenticated / Degraded / Unauthenticated / Archived / NeedsVerification / VerificationSent / PasswordResetSent / Error` |

**Auth State Machine:**

```
AuthEventCheckStatus ──► Reload Firebase user ──► fetch Firestore profile
                                                      │
                          ┌───────────────────────────┤
                          ▼                           ▼
                  no user: Unauthenticated    user found:
                                               archived → AuthArchived
                                               unverified → NeedsVerification
                                               ok → AuthAuthenticated
```

**Degraded Mode:** If Firestore fetch fails but a cached `AuthUser` matches the current Firebase UID, the bloc emits `AuthDegraded` instead of an error, allowing the user to continue with stale permissions.

**Dependencies:** `firebase_auth`, `cloud_firestore`, `flutter_bloc`

**Interactions:** `AuthBloc` is read globally by `RoleUserRoute`, `AppRouter` (AdminGate), and any feature screen that needs the current user identity.

---

## Student

**Purpose:** Full lifecycle management for student records.

**Key Files:**

| File | Description |
|---|---|
| `data/models/student_model.dart` | `@freezed` model: name, mobile, parent contacts, grade, education stage, team/group assignment, archive fields, `classId` for query optimisation |
| `data/repos/student_data_repository.dart` | Implements `IStudentRepository`. Firestore CRUD + streams |
| `data/services/student_query_service.dart` | Encapsulates filtered Firestore queries (by class, by group). Prevents N+1 patterns |
| `data/services/student_linked_user_sync_service.dart` | Keeps the student's Firestore `Students` doc in sync with the corresponding `Users` doc when a student creates an account |
| `domain/usecases/get_students_stream_usecase.dart` | Wraps `IStudentRepository.watchStudents()` with optional filters |
| `domain/usecases/can_mutate_student_usecase.dart` | Pure permission check: can the current actor modify a given student? |
| `presentation/bloc/student_data/student_data_bloc.dart` | Screen-scoped BLoC for the student list. Provisioned per-screen inside `AppRouter` |
| `presentation/bloc/student_profile/student_profile_cubit.dart` | Screen-scoped cubit for a student's own profile view |

**Dependencies:** `cloud_firestore`, `flutter_bloc`

**Interactions:** 
- `StudentDataRepository` is consumed by `StudentDataBloc`, `AttendanceRepository` (roster resolution), and `ServantDataRepository`.
- `StudentLinkedUserSyncService` is composed into `StudentDataRepository` and triggered on student profile updates.

---

## Servant

**Purpose:** Servant profile management and a global servant list used for team assignment.

**Key Files:**

| File | Description |
|---|---|
| `data/models/servant_models.dart` | `@freezed` model for servant profile (mirrors `Users` collection with role == 'servant') |
| `data/repo/servant_data_repository.dart` | Implements `IServantRepository`. Reads from `Users` collection filtered by role |
| `presentation/bloc/servant_data/servant_data_cubit.dart` | Global cubit (registered in `ChurchApp`). Loads and caches all servant profiles for team assignment dropdowns |
| `presentation/bloc/servant_dashboard_cubit.dart` | Per-screen cubit for the servant's own dashboard state |

**Dependencies:** `cloud_firestore`, `flutter_bloc`

**Interactions:** `ServantDataCubit` is provided globally so `AdminTeamService` and servant-assignment dialogs can access the full servant list without refetching.

---

## Team

**Purpose:** Team (class) lifecycle management and servant assignment.

**Key Files:**

| File | Description |
|---|---|
| `data/models/team_model.dart` | `@freezed` model: `id`, `name`, `groupId`, `assignedServantId`, `assignedServantName` (denormalised), archive fields |
| `data/repos/team_repository.dart` | CRUD for the `Classes` Firestore collection |
| `data/admin_team_service.dart` (under `features/admin`) | Orchestrates team creation, update, archival, and servant assignment with related side-effects |
| `data/admin_team_membership_service.dart` | Updates `Students.classId` and `Users.assignedTeamIds` when team membership changes |
| `presentation/bloc/team_cubit.dart` | Loads and streams the team list |
| `presentation/bloc/team_members_cubit.dart` | Loads students for a specific team |
| `presentation/bloc/assign_servant_options_cubit.dart` | Loads available servants for the assign-servant dialog |

**Dependencies:** `cloud_firestore`, `flutter_bloc`

**Interactions:** `AdminTeamService` is the only module that writes to the `Users.assignedTeamIds` array, coupling team management with the auth user's profile.

---

## Attendance

**Purpose:** Session-based attendance tracking with real-time roster and mark management.

**Key Files:**

| File | Description |
|---|---|
| `data/models/attendance_session.dart` | `@freezed`: `teamId`, `startsAt`, `endsAt`, `durationMinutes`, `isClosed`, `isReopenedForAdminEdit`, `studentIdsSnapshot`, `studentNameSnapshots` |
| `data/models/attendance_mark.dart` | `@freezed`: per-student mark with `status` (present/late), `markedByUserId`, `markedByName`, `markedAt`, `note` |
| `data/models/attendance_roster_item.dart` | View model combining student info + mark for a single roster row |
| `data/repos/attendance_repository.dart` | 1002-line implementation. Combines Firestore streams with `rxdart`. Validates permissions, overlap, and open/closed state before writes |
| `domain/repos/i_attendance_repository.dart` | Contract: session CRUD, mark operations, roster watch, history queries |
| `presentation/bloc/attendance_taking/` | Cubit powering the real-time attendance sheet |
| `presentation/bloc/attendance_history/` | Cubit for the session history list |
| `presentation/bloc/student_attendance/` | Cubit for displaying a single student's attendance track record |
| `presentation/bloc/session_admin/` | Cubit for admin session management (close/reopen) |

**Session Lifecycle:**

```
Admin/Servant → Create Session (roster snapshot taken at creation time)
             → Session Open (startsAt ≤ now < endsAt)
             → Marks written (present / late; absent is implicit)
             → Session Closes (isClosed=true OR endsAt passed)
             → Admin Reopens (isReopenedForAdminEdit=true)
             → Admin Re-closes
```

**Dependencies:** `cloud_firestore`, `rxdart`, `flutter_bloc`

---

## Admin

**Purpose:** Admin-specific orchestration and access control.

**Key Files:**

| File | Description |
|---|---|
| `data/admin_team_service.dart` | High-level team operations; calls `AdminTeamMembershipService` for cascading user/student updates |
| `data/admin_team_membership_service.dart` | Manages `Users.assignedTeamIds` and `Students.classId` arrays |
| `domain/admin_policy.dart` | Pure domain rules for admin-only actions |
| `presentation/widget/admin_gate.dart` | Guard widget: reads `AuthBloc`, shows forbidden screen for non-admins |
| `presentation/screens/admin_dashboard_screen.dart` | Top-level admin navigation hub |

---

## Core / Shared

**Purpose:** Infrastructure used by all features.

| Module | Responsibility |
|---|---|
| `core/di/injection.dart` | Full dependency graph — 15+ singleton registrations |
| `core/routing/app_router.dart` | 17 named routes; `_withStudentDataBloc` helper injects `StudentDataBloc` on student routes |
| `core/theme/` | Design tokens and component overrides assembled into `AppTheme.light()` |
| `core/widgets/` | 20+ shared widgets: forms, dialogs, cards, search, snackbars |
| `core/utils/json_converters.dart` | `FirestoreTimestampConverter` and `RequiredFirestoreTimestampConverter` used across all `@freezed` models |
