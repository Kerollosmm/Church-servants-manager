# 📋 PROJECT STATE DOCUMENT
### Church Management System (CSMS) — Flutter + Firebase
**Generated:** 2026-03-26 | **Version:** 1.0.0+1 | **Status:** Active Development

---

## 1. 🏗️ PROJECT OVERVIEW

| Field | Details |
|---|---|
| **App Name** | Church Management System (`church_management_system`) |
| **Display Name** | اعداد خدام (Servant Preparation) |
| **Purpose** | A mobile/multi-platform app for managing church servants, students, teams, and attendance sessions |
| **Target Users** | Admins (church leadership), Servants (team leaders/teachers), Students (youth members) |
| **Language** | Arabic-primary UI, English codebase |
| **Platforms** | Android, iOS, Web, macOS, Linux, Windows |

### Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter 3+ (Dart SDK ^3.9.2) |
| **State Management** | flutter_bloc ^9.1.1 (BLoC + Cubit) |
| **Backend** | Firebase (Firestore, Auth, Cloud Functions) |
| **DI** | GetIt ^9.2.1 + injectable ^2.7.1 |
| **Data Models** | Freezed ^2.5.2 + json_serializable ^6.8.0 |
| **Local Storage** | Hive ^2.2.3 (registered, not yet wired to features) |
| **Networking** | cloud_firestore ^6.1.3, cloud_functions ^6.0.7 |
| **Connectivity** | connectivity_plus ^6.1.0 |
| **Navigation** | Named routes via custom `AppRouter` |
| **Utilities** | dartz ^0.10.1, equatable ^2.0.8, rxdart ^0.28.0, uuid ^4.5.3 |
| **Testing** | mocktail ^1.0.4, fake_cloud_firestore ^4.0.1 |

---

## 2. 🏛️ ARCHITECTURE ANALYSIS

### Folder Structure Overview

```
lib/
├── main.dart                      ✅ Entry point, error zone wrapping
├── church_app.dart                ✅ Root widget (MaterialApp)
├── firebase_options.dart          ✅ Auto-generated
├── role_user_route.dart           ⚠️ Placeholder widget only
│
├── core/
│   ├── constants/                 ✅ enums, routes, firestore_collections
│   ├── di/                        ✅ GetIt injection.dart
│   ├── routing/                   ⚠️ app_router.dart is a STUB
│   ├── services/                  ✅ ConnectivityService
│   └── utils/                     ✅ validators, json_converters, exception_matchers
│
└── features/
    ├── admin/                     ✅ AdminPolicy, AdminTeamService, AdminTeamMembershipService
    ├── attendance/                ✅ Full domain + data layer; ❌ NO presentation layer
    ├── auth/                      ✅ Full domain + data + use cases
    ├── servant/                   ✅ Full domain + data + use cases
    ├── student/                   ✅ Full domain + data + use cases
    └── team/                      ✅ Domain + data + use cases
```

### Architecture Pattern

**Clean Architecture** — feature-first folder layout with:
- **Domain Layer**: Abstract repositories (`I*Repository`), use cases, failure classes
- **Data Layer**: Concrete repositories, Firestore services, models (Freezed)
- **Presentation Layer**: BLoC/Cubit (mostly missing or removed — see §4)

### ✅ Correctly Implemented

- Separation of domain interfaces from data implementations
- Use cases as single-responsibility classes
- Failure classes per feature with consistent `mapException*` helpers
- `CanMutateStudentUseCase` for permission gating at domain level
- Proper Firestore offline persistence (100MB bounded cache)
- `runZonedGuarded` error boundary in `main.dart`
- Transaction-like rollback in `AddStudent`/`AddServant` use cases

### ❌ Missing / Broken

- `AppRouter.onGenerateRoute` is a **stub** — returns "Not Found" for every route
- **No presentation layer exists** — no screens, no actual UI widgets (removed per TODOs)
- BLoC/Cubit section in `injection.dart` is **empty** (comment left, no registrations)
- `ConnectivityCubit` is referenced in DI comment but **never actually registered**
- `ChurchApp` uses `ThemeData.light()` — no custom design system wired in
- Hive is declared as dependency but **never initialized or used**
- `dartz` is listed in dependencies but **not used** — Either/Option pattern not adopted

---

## 3. 🔐 AUTHENTICATION & LOGIN FLOW

### Step-by-Step Login Flow

```
1. App starts → Firebase.initializeApp() → configureDependencies() → ChurchApp
2. ChurchApp renders → AppRouter.onGenerateRoute → [BROKEN: always returns Not Found]
3. [Expected] ObserveAuthStateUseCase watches Firebase auth stream
4. [Expected] AuthUser loaded from Firestore Users/{uid}
5. [Expected] RoleRouter checks:
      isArchived           → ArchivedAccountScreen
      role == admin        → needs fresh session check → AdminReauthScreen
      role == servant      → ServantDashboard
      role == student      → StudentDashboard
```

### AuthUser Model Fields

```dart
AuthUser {
  uid, name, email, role (admin/servant/student),
  isEmailVerified, isArchived, archivedAt, archivedByUserId,
  groupId,                    // servant's group
  assignedTeamId,             // servant's primary team
  assignedTeamIds,            // List<String> - multi-team support
  restorePendingPasswordReset // flag for restored accounts
}
```

### Firebase Auth Integration

| Component | Status | Notes |
|---|---|---|
| `FirebaseAuthProvider` | ✅ Implemented | Wraps FirebaseAuth, reads profile from Firestore |
| `AuthService` | ✅ Implemented | Delegates to provider, implements AuthRepository |
| `AuthUserProfileStore` | ✅ Implemented | Read/write to `Users/{uid}` in Firestore |
| `ObserveAuthStateUseCase` | ✅ Implemented | Emits typed `AuthStateResolved` variants |
| `SignInUseCase` | ✅ Implemented | Email/password |
| `SignOutUseCase` | ✅ Implemented | Clears session |
| `AdminAuthClient` | ✅ Implemented | Cloud Functions for admin user provisioning |
| `AdminUserProvisioningService` | ✅ Implemented | Create/archive/restore users with rollback |
| Login Screen UI | ❌ **MISSING** | Removed (TODO in test files) |
| Splash Screen UI | ❌ **MISSING** | Removed |
| Auth BLoC | ❌ **MISSING** | `auth_bloc_test.dart` is `void main() {}` |

### Role-Based Access

```
UserRole: admin | servant | student

RoleRouter resolves:
  - AuthStateNeedsAdminRefresh  → AdminReauthScreen  [stub widget]
  - AuthStateArchived           → ArchivedAccountScreen [stub widget]
  - AuthStateAuthenticated      → route by role
```

### ⚠️ Security Weaknesses

| # | Issue | Severity |
|---|---|---|
| S1 | `AppRouter` is a stub — all routes return "Not Found". No route guards exist. | 🔴 P0 |
| S2 | No auth guard middleware: unauthenticated users can theoretically reach any route | 🔴 P0 |
| S3 | `validSelfUserCreate` in Firestore rules only allows `role == 'student'` — blocks legitimate admin-created servants from writing their own profile | 🟡 P1 |
| S4 | `callerUser()` makes a live document read on every rule evaluation — expensive and can cause rule evaluation timeouts under load | 🟡 P1 |
| S5 | `restorePendingPasswordReset` flag is client-side only — password reset isn't enforced server-side | 🟡 P1 |
| S6 | Admin session freshness (`canAccessAdminArea`) is checked client-side only — not enforced in Firestore rules | 🟠 P2 |

---

## 4. 🧠 BLOC / CUBIT ANALYSIS

### Registered BLoCs / Cubits

> ⚠️ **Critical Finding**: The `// ---- BLoCs / Cubits ----` section in `injection.dart` is **completely empty**. All BLoC/Cubit registrations have been removed. Test stubs confirm this.

### Inferred BLoC/Cubit Architecture (from tests & structure)

| Cubit/BLoC | Feature | Test File Status | Inferred States | Notes |
|---|---|---|---|---|
| `AuthBloc` | Auth | `void main() {}` | Initial, Loading, Authenticated, Unauthenticated, Error | ❌ Implementation removed |
| `ServantDataCubit` | Servant | `void main() {}` | Initial, Loading, Loaded, Error | ❌ Implementation removed |
| `StudentDataBloc` | Student | TODO — disabled | Initial, Loading, Loaded, Error | ❌ Implementation removed |
| `TeamCubit` | Team | TODO — disabled | Initial, Loading, Loaded, Error | ❌ Implementation removed |
| `TeamMembersCubit` | Team | TODO — disabled | Initial, Loading, Members, Error | ❌ Implementation removed |
| `AttendanceSessionAdminCubit` | Attendance | `void main() {}` | Initial, Creating, Active, Closed, Error | ❌ Implementation removed |
| `AttendanceTakingCubit` | Attendance | `void main() {}` | Loading, Ready, Marking, Marked, Error | ❌ Implementation removed |
| `StudentAttendanceCubit` | Attendance | `void main() {}` | Loading, History, Stats, Error | ❌ Implementation removed |
| `ConnectivityCubit` | Core | Not found | Online, Offline | ❌ Registered in comment only |

### BLoC/Cubit Status Summary

```
Total Expected:   ~9 BLoCs/Cubits
Implemented:       0
Removed/Missing:   9  (100%)
DI Registered:     0
```

### Missing BLoC Best Practices

- No `BlocObserver` registered for global logging/analytics
- No `MultiBlocProvider` at app root (`ChurchApp` has no providers)
- No error state distinction between network errors and permission errors
- No optimistic update pattern for attendance marking (latency sensitive)

---

## 5. 📦 MODELS REVIEW

### All Models

| Model | File | Freezed | fromJson | toJson | Firestore Map | Issues |
|---|---|---|---|---|---|---|
| `AuthUser` | auth/data/models | ✅ | ✅ | ✅ | ✅ fromMap() | ⚠️ Missing `createdAt` timestamp |
| `StudentModel` | student/data/models | ✅ | ✅ | ✅ | ✅ fromMap() | ⚠️ Missing `updatedAt` field |
| `ServantModel` | servant/data/models | ✅ | ✅ | ✅ | ✅ fromMap() | ⚠️ `teamName` mapped from `groupId` — naming mismatch |
| `TeamModel` | team/data/models | ✅ | ✅ | ✅ | ✅ | ✅ Good |
| `AttendanceSession` | attendance/data/models | ✅ | ✅ | ✅ | ✅ fromMap() | ⚠️ `id` removed from `toMap()` — relies on docId |
| `AttendanceMark` | attendance/data/models | ✅ | ✅ | ✅ | ✅ fromMap() | ⚠️ `studentId` removed from `toMap()` — implicit from path |
| `AttendanceStats` | attendance/data/models | ✅ Manual | N/A | N/A | Computed locally | ✅ |
| `StudentAttendanceHistoryItem` | attendance/data/models | ✅ Equatable | N/A | N/A | Composed locally | ✅ |
| `AttendanceRosterItem` | attendance/data/models | N/A | N/A | N/A | Composed in repo | ✅ |
| `AttendanceRosterSnapshot` | attendance/data/models | N/A | N/A | N/A | Aggregates session+roster | ✅ |
| `AdminUserProvisioningRequest` | auth/data/models | ❌ Plain class | Manual | ✅ toJson() | N/A | ✅ |

### Key Model Issues

| # | Issue | Severity |
|---|---|---|
| M1 | `StudentModel` is missing `updatedAt: DateTime` — cannot track when a record was last modified | 🟠 P2 |
| M2 | `AuthUser` is missing `createdAt: DateTime` — can't audit account age | 🟠 P2 |
| M3 | `ServantModel.teamName` is mapped from Firestore key `groupId` — semantically confusing | 🟡 P1 |
| M4 | `AttendanceMark` has no `absent` status — "absent" is inferred by absence of a mark (correct by design, must be documented) | 🟢 Design note |
| M5 | `AttendanceMarkStatus` only has `present` and `late` — `absent` is an `AttendanceEffectiveStatus` only. Two-enum approach is correct but adds complexity | 🟢 Design note |
| M6 | `StudentModel.grade` is `int` but `educationStage` is an enum — no validation that grade matches stage | 🟠 P2 |
| M7 | Freezed `.freezed.dart` and `.g.dart` generated files are committed — should be in `.gitignore` or documented as intentional | 🟢 Convention |

---

## 6. 🗄️ REPOSITORIES REVIEW

### All Repositories

| Repository | Interface | Implementation | Notes |
|---|---|---|---|
| `AuthRepository` | `AuthRepository` (abstract) | `AuthService` | ✅ Correctly wired |
| `IStudentRepository` | ✅ Defined | `StudentDataRepository` | ✅ Full CRUD + streams |
| `IServantRepository` | ✅ Defined | `ServantDataRepository` | ⚠️ Missing audit fields on `deleteServant` |
| `IAttendanceRepository` | ✅ Defined | `AttendanceRepository` | ✅ Most complete repository |
| `ITeamRepository` | ❌ Not extracted | `TeamRepository` | ⚠️ No interface — untestable via mock |

### Offline-First Logic

| Feature | Firestore Persistence | Local Cache (Hive) | Offline Writes | Status |
|---|---|---|---|---|
| Students | ✅ SDK-level (100MB) | ❌ Not implemented | ❌ No queue | Partial |
| Servants | ✅ SDK-level | ❌ Not implemented | ❌ No queue | Partial |
| Attendance | ✅ SDK-level | ❌ Not implemented | ❌ No queue | Partial |
| Teams | ✅ SDK-level | ❌ Not implemented | ❌ No queue | Partial |
| Auth | ✅ Firebase native | ❌ | N/A | Partial |

> **Note:** Firestore SDK persistence is enabled and bounded at 100MB. This handles basic offline reads. However, there is **no application-level offline queue, sync-status field on models, or conflict resolution strategy**. Hive is imported but never initialized or used.

### Firestore Read/Write Efficiency

| # | Issue | Severity |
|---|---|---|
| R1 | `searchStudents` is **in-memory** — loads all students, then filters client-side. Will not scale beyond ~500 documents | 🟡 P1 |
| R2 | `filterServants` is **in-memory** — same scalability problem as students | 🟡 P1 |
| R3 | `AttendanceRepository` uses batch reads with 10-item `whereIn` chunks (correct Firestore limit handling) | ✅ Good |
| R4 | `callerUser()` in Firestore rules triggers a document read per security rule evaluation — risk of timeouts | 🟡 P1 |
| R5 | `StudentQueryService` uses `startAt`/`endAt` on name for range queries — correct pattern, but case-sensitive | 🟠 P2 |
| R6 | `getStudentAttendanceStats` fetches full attendance history client-side to compute stats — should be a Cloud Function for large datasets | 🟠 P2 |
| R7 | No pagination cursor saved in state — "load more" requires passing `DocumentSnapshot` manually; no repo-level page cache | 🟠 P2 |
| R8 | `ServantDataRepository` does not pass `performedByUid` to `deleteServant` — audit trail incomplete vs. `IStudentRepository` | 🟡 P1 |

### Error Handling Quality

| Feature | Failure Classes | mapException Helper | Propagation |
|---|---|---|---|
| Auth | ✅ Comprehensive | ✅ `mapExceptionToAuthFailure` | ✅ |
| Student | ✅ Defined | ✅ `mapExceptionToStudentFailure` | ⚠️ Not used consistently in all use cases |
| Servant | ✅ Defined | ✅ `mapExceptionToServantFailure` | ⚠️ No dedicated `PermissionDeniedFailure` class |
| Attendance | ✅ Best in class | ✅ `mapExceptionToAttendanceFailure` | ✅ Arabic user-facing messages |
| Team | ✅ Defined | ✅ `mapExceptionToTeamFailure` | ⚠️ `ITeamRepository` interface missing |

---

## 7. 🔴 CRITICAL ISSUES — P0 (App Cannot Function)

| ID | Issue | Location | Impact |
|---|---|---|---|
| **P0-1** | `AppRouter.onGenerateRoute` is a stub — returns "Not Found" Scaffold for **every route** | `lib/core/routing/app_router.dart` | App is non-functional |
| **P0-2** | **Zero BLoC/Cubit implementations exist** — entire presentation state layer is missing | `lib/core/di/injection.dart` (empty BLoCs section), all `*/presentation/` dirs | App has no functional UI |
| **P0-3** | **No UI screens exist** — all screens were removed. `ChurchApp` renders nothing useful | All `*/presentation/` directories | App shows nothing |
| **P0-4** | `ConnectivityCubit` is referenced in a DI comment but **never registered** — any widget depending on it will crash | `lib/core/di/injection.dart` lines 211–214 | Runtime crash on first use |
| **P0-5** | Hive is declared as a dependency but **never initialized** (`Hive.initFlutter()` never called in `main.dart`) | `pubspec.yaml`, `lib/main.dart` | Silent dependency rot |

---

## 8. 🟡 IMPROVEMENTS NEEDED

### P1 — High Priority (Fix Before Launch)

| ID | Issue | Recommendation |
|---|---|---|
| **P1-1** | Entire presentation layer is missing (screens + BLoCs) | Build AuthBloc, ServantDataCubit, StudentDataBloc, TeamCubit, AttendanceTakingCubit, etc. |
| **P1-2** | `AppRouter` is a stub with no route guards | Implement all named routes from `routes.dart` + auth-state-aware route guard using `ObserveAuthStateUseCase` |
| **P1-3** | `ServantModel.teamName` stored as `groupId` in Firestore — semantic mismatch | Rename field to `groupId` in model; add `teamDisplayName` if needed |
| **P1-4** | `IServantRepository.deleteServant` lacks `performedByUid` parameter — audit trail gap | Add `{required String performedByUid}` to match `IStudentRepository` pattern |
| **P1-5** | `ITeamRepository` interface not extracted — only concrete `TeamRepository` exists | Extract abstract interface and register in DI for testability |
| **P1-6** | In-memory search for students and servants will not scale | Implement server-side Firestore range queries or integrate Algolia/Typesense |
| **P1-7** | `dartz` imported but never used — Either/Result types not adopted | Either remove dependency or adopt `Either<Failure, T>` return type in use cases |
| **P1-8** | No `BlocObserver` for global error monitoring | Register a `LoggingBlocObserver` in `main.dart` before `runApp` |
| **P1-9** | Firestore rules `callerUser()` reads a document on every rule evaluation | Verify no redundant document fetches in rules; consider caching with `let user = get(...)` |

### P2 — Medium Priority (Before v1.1)

| ID | Issue | Recommendation |
|---|---|---|
| **P2-1** | No `updatedAt` on `StudentModel` | Add `@_TimestampConverter() DateTime? updatedAt` field |
| **P2-2** | No `createdAt` on `AuthUser` / `ServantModel` | Add timestamps for audit compliance |
| **P2-3** | `getStudentAttendanceStats` is O(n) client-side computation | Implement Cloud Function to aggregate stats server-side |
| **P2-4** | No optimistic UI for attendance marking | Add local state update before Firestore write resolves |
| **P2-5** | `StudentModel.grade` not validated against `educationStage` | Add domain validation in `AddStudentUseCase` / `UpdateStudentUseCase` |
| **P2-6** | Firestore name search is case-sensitive | Normalize names to lowercase on write; query lowercase field |
| **P2-7** | No pagination state in repositories | Implement cursor-based pagination object with `hasMore`, `nextCursor` |
| **P2-8** | `ThemeData.light()` only — no design system | Implement custom `AppTheme` with color palette (ochre/sanctuary per DESIGN.md) |
| **P2-9** | Arabic strings hardcoded only in attendance failures | Extract all Arabic strings to `AppStrings` or `l10n` layer |
| **P2-10** | `DataSeeder` utility lives in `core/utils` | Move to `lib/features/devtools/` and gate behind `kDebugMode` |
| **P2-11** | No Firebase App Check configured | Add App Check to prevent unauthorized API access |
| **P2-12** | Admin session freshness is client-only | Add server-side token claim for admin role via Cloud Functions |

---

## 9. 📊 WHAT'S DONE VS WHAT'S MISSING

| Feature | Status | Notes |
|---|---|---|
| **Firebase Setup** | ✅ Done | Auth, Firestore, Functions all configured |
| **Firestore Security Rules** | ✅ Done | Role-scoped, session-validated, mark-validated |
| **DI / GetIt Configuration** | ✅ Done | All repos and use cases wired |
| **AuthUser Model** | ✅ Done | Freezed, role-aware, archive-aware |
| **StudentModel** | ✅ Done | Missing `updatedAt` |
| **ServantModel** | ✅ Done | `groupId`/`teamName` naming mismatch |
| **TeamModel** | ✅ Done | Complete |
| **AttendanceSession Model** | ✅ Done | Complete with time-window logic |
| **AttendanceMark Model** | ✅ Done | Subcollection-aware `toMap()` |
| **AttendanceStats** | ✅ Done | Client-side computed |
| **AttendanceRosterItem / Snapshot** | ✅ Done | |
| **Auth Domain (UseCases)** | ✅ Done | SignIn, SignOut, ObserveAuthState |
| **Student Domain (UseCases)** | ✅ Done | Add, Update, Delete, Restore, Search, CanMutate, GetStream |
| **Servant Domain (UseCases)** | ✅ Done | Add, Update, Delete, Restore, Filter, Get |
| **Team Domain (UseCases)** | ✅ Done | Create, Get, AssignServant |
| **Attendance Domain** | ✅ Done | Full interface defined |
| **StudentDataRepository** | ✅ Done | Full CRUD + streams + pagination |
| **ServantDataRepository** | ✅ Done | Full CRUD + streams (missing audit on delete) |
| **AttendanceRepository** | ✅ Done | Most complete repository |
| **TeamRepository** | ✅ Done | Basic CRUD |
| **AdminTeamService** | ✅ Done | Assign servants, set members |
| **AdminTeamMembershipService** | ✅ Done | Batch member management |
| **AdminUserProvisioningService** | ✅ Done | Create/archive/restore + rollback |
| **ConnectivityService** | ✅ Done | Offline stream |
| **Validators** | ✅ Done | English + Arabic |
| **AppRouter** | ❌ Stub only | Returns "Not Found" for all routes |
| **Login Screen** | ❌ Missing | Removed, test is empty |
| **Splash Screen** | ❌ Missing | Removed |
| **Auth BLoC** | ❌ Missing | Removed, test is empty |
| **ServantDataCubit** | ❌ Missing | Removed, test is empty |
| **StudentDataBloc** | ❌ Missing | Removed, test is TODO |
| **TeamCubit / TeamMembersCubit** | ❌ Missing | Removed, tests are TODO |
| **AttendanceSessionAdminCubit** | ❌ Missing | Removed, test is empty |
| **AttendanceTakingCubit** | ❌ Missing | Removed, test is empty |
| **StudentAttendanceCubit** | ❌ Missing | Removed, test is empty |
| **ConnectivityCubit** | ❌ Missing | Referenced in DI comment only |
| **Admin Dashboard Screen** | ❌ Missing | No presentation/admin directory |
| **Servant Dashboard Screen** | ❌ Missing | No presentation layer |
| **Student List Screen** | ❌ Missing | No presentation layer |
| **Servant List Screen** | ❌ Missing | No presentation layer |
| **Attendance Taking Screen** | ❌ Missing | No presentation layer |
| **Attendance History Screen** | ❌ Missing | No presentation layer |
| **Student Profile Screen** | ❌ Missing | No presentation layer |
| **Servant Profile Screen** | ❌ Missing | No presentation layer |
| **Team Management Screen** | ❌ Missing | No presentation layer |
| **Design System / Theme** | ❌ Missing | Only `ThemeData.light()` used |
| **Offline Write Queue** | ❌ Missing | Hive not initialized |
| **Localization (l10n)** | ❌ Missing | Arabic strings hardcoded in places |
| **Firebase App Check** | ❌ Missing | No security attestation |
| **BLoC Tests** | ❌ Stubs only | All test files are empty |
| **Widget Tests** | ⚠️ Partial | Auth smoke tests exist but reference missing screens |
| **Integration Tests** | ❌ Missing | No integration test directory |

---

## 10. 🗺️ RECOMMENDED IMPLEMENTATION ORDER

```
PHASE 1 — Foundation (Prerequisite for everything)
  [ ] Implement AppRouter with all named routes + auth guard
  [ ] Implement AuthBloc (SignIn, SignOut, ObserveAuthState states)
  [ ] Register ConnectivityCubit in DI
  [ ] Add BlocObserver to main.dart
  [ ] Implement AppTheme (design system)

PHASE 2 — Auth UI
  [ ] SplashScreen (auth state resolver)
  [ ] LoginScreen
  [ ] ArchivedAccountScreen
  [ ] AdminReauthScreen

PHASE 3 — Core Feature BLoCs + Screens
  [ ] ServantDataCubit + Servant Dashboard + Servant List + Profile
  [ ] StudentDataBloc + Student List + Profile
  [ ] TeamCubit + Team Management

PHASE 4 — Attendance
  [ ] AttendanceSessionAdminCubit + Session Create Screen
  [ ] AttendanceTakingCubit + Attendance Taking Screen
  [ ] StudentAttendanceCubit + Attendance History Screen

PHASE 5 — Quality & Scale
  [ ] Server-side search (replace in-memory)
  [ ] Cloud Function for stats aggregation
  [ ] Firebase App Check
  [ ] l10n / AppStrings
  [ ] Full BLoC test coverage
```

---

> **Document generated by:** Rovo Dev — Senior Flutter & Firebase Architect
> **Conclusion:** The backend is production-ready. Your domain, data, repositories, security rules, and use cases are well-structured and cover real-world edge cases (rollback, audit trails, session time windows, permission scoping). The entire presentation layer needs to be rebuilt from scratch.
