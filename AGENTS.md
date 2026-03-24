# Church Servants Manager — Development Guidelines

> Read by **Rovo Dev** (and any AGENTS.md-compatible agent) as the primary workspace memory file.
> Last updated: 2026-03-23

## Active Technologies

- **Flutter 3.x + Dart ≥ 3.9.2** — cross-platform mobile app (Android / iOS primary)
- **Firebase** — Auth, Firestore, Cloud Functions (TypeScript), Crashlytics
- **flutter_bloc** — BLoC for auth, Cubits for all feature state
- **get_it** — manual dependency injection (no code generation)
- **freezed + json_serializable** — immutable models with auto-serialization
- **go_router** — declarative, role-based navigation
- **flutter_localizations + ARB** — Arabic (ar_EG) primary locale
- **mocktail** — mocking in unit/widget tests

## Project Structure

```text
lib/
├── main.dart                  # Firebase init, DI bootstrap, error handling
├── church_app.dart            # Root widget, MultiRepositoryProvider/MultiBlocProvider
├── role_user_route.dart       # Role-based navigation shell (admin/servant/student)
├── firebase_options.dart      # Generated Firebase config
├── core/
│   ├── constants/             # Enums (UserRole, AttendanceStatus…), routes
│   ├── di/injection.dart      # get_it service registry (all registrations here)
│   ├── routing/               # go_router config & role router
│   ├── theme/                 # AppTheme, AppColors, Typography, Spacing
│   ├── utils/                 # Validators, JSON converters, DataSeeder
│   └── widgets/               # Shared atoms, cards, dialogs, feedback, form, organisms
└── features/                  # Vertical feature slices
    ├── auth/                  # Firebase Auth (login, register, verify, forgot pw)
    ├── student/               # Student CRUD, profile, attendance summary
    ├── servant/               # Servant CRUD, dashboard, team assignment
    ├── team/                  # Team management, member assignment
    ├── attendance/            # Session creation, taking, history, stats
    └── admin/                 # Admin dashboard, provisioning

Each feature follows:
  data/
    models/      # freezed data classes (.freezed.dart, .g.dart)
    repos/       # Repository implementations (Firestore)
    services/    # Firebase service wrappers
  domain/
    repos/       # i_*_repository.dart interfaces
    usecases/    # Business logic use cases
    failures/    # Domain-specific failure types
  presentation/
    bloc/        # BLoC / Cubits
    screens/     # Screen widgets
    widgets/     # Feature-specific widgets

functions/
  src/
    index.ts     # Cloud Functions entry point
    admin.ts     # Admin provisioning functions
test/            # Mirrors lib/features/<feature>/<layer>/
```

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Run a specific test file
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code (must pass before any PR)
flutter analyze

# Run the app on a connected device/emulator
flutter run
```

## Code Style & Architecture Rules

### Core Principles (from Constitution v1.2.1)

1. **Production Stability** — Never break existing Firestore schema or production behavior.
2. **Surgical Changes** — Keep all fixes minimal and scoped. Do not refactor unrelated code.
3. **Business Logic in Cubits Only** — Widgets MUST only render and forward user events.
4. **Repository Layer** — Firestore MUST only be accessed through repository implementations.
5. **Feature-First Structure** — Every feature owns its `data/`, `domain/`, and `presentation/`.

### Technical Constraints

- **No God Widgets** (> 150 lines) or **God Cubits** (> 200 lines) — break into smaller parts.
- **All models** use `freezed` for immutability + `json_serializable` for Firestore serialization.
- **All DI** is manual via `get_it` in `core/di/injection.dart`.
- **All user-facing strings** use `AppLocalizations.of(context)` (Arabic ar_EG primary).
- **State classes** use `freezed` or `equatable` — always immutable and value-comparable.
- **Fix traceability**: annotate changed lines with `// FIX [ID]: reason`.
- `const` everywhere possible; no `Expanded` outside `Flex`; tight `BlocBuilder` scopes.

### Adding a New Feature

1. Add `freezed` models in `features/<name>/data/models/`
2. Define `I<Name>Repository` interface in `domain/repos/`
3. Implement repository in `data/repos/`
4. Create Cubit/Bloc in `presentation/bloc/`
5. Build screens in `presentation/screens/`
6. Register DI in `core/di/injection.dart`
7. Add routes in `core/routing/app_router.dart`
8. Run `dart run build_runner build --delete-conflicting-outputs`

### Adding a New Screen

1. Create screen widget in `features/<name>/presentation/screens/`
2. Add route constant in `core/constants/routes.dart`
3. Add `GoRoute` in `AppRouter.createRouter()`
4. Scope state with `BlocProvider`/`RepositoryProvider` as needed

## Speckit Workflow (Spec-Driven Development)

This project uses **speckit** — a spec-driven development workflow. Use these commands in order:

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `/speckit.constitution` | Create/update project constitution |
| 2 | `/speckit.specify` | Write a feature specification |
| 3 | `/speckit.clarify` | Clarify ambiguities in the spec |
| 4 | `/speckit.plan` | Generate implementation plan + data model |
| 5 | `/speckit.tasks` | Break plan into executable tasks |
| 6 | `/speckit.analyze` | Cross-check spec/plan/tasks for gaps |
| 7 | `/speckit.implement` | Execute tasks phase-by-phase |
| 8 | `/speckit.checklist` | Validate quality gates before merge |

All specs live in `specs/<NNN>-<feature-name>/`. The active constitution is at `.specify/memory/constitution.md`.

Scripts are PowerShell (`.specify/scripts/powershell/`). The key scripts called by speckit commands are:
- `setup-plan.ps1 -Json` — sets up a new plan from the template
- `check-prerequisites.ps1 -Json [-RequireTasks] [-IncludeTasks] [-PathsOnly]` — validates workflow state
- `update-agent-context.ps1 [-AgentType <type>]` — syncs agent context files after planning

## Key Files

| File | Purpose |
|------|---------|
| `lib/core/di/injection.dart` | All DI registrations |
| `lib/core/routing/app_router.dart` | Route definitions and auth redirects |
| `lib/role_user_route.dart` | Role-based navigation shell |
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Auth state machine |
| `lib/features/auth/data/models/auth_user.dart` | Auth user model |
| `.specify/memory/constitution.md` | Project governance constitution |
| `firestore.rules` | Firestore security rules |

## Firestore Collections

- `users` — User profiles with role (`admin`/`servant`/`student`), teamId, archive status
- `teams` — Team documents with servant assignments
- `attendance_sessions` — Attendance session records with embedded marks

## Navigation & Auth States

- `AppRouter` uses `go_router` with auth state redirection via `GoRouter.redirect`
- Role shell: `StatefulShellRoute.indexedStack` dispatches by `UserRole`
- Auth states: `AuthInitial` → `AuthLoading` → `AuthUnauthenticated` | `AuthNeedsVerification` | `AuthAuthenticated` | `AuthDegraded` | `AuthArchived` | `AuthError`

## Testing

- Unit tests: `mocktail` for mocking, mirror path `test/features/<feature>/<layer>/`
- Widget tests: `flutter_test` with `pumpWidget`
- No integration tests yet (future work)
- After code-gen changes, always re-run `dart run build_runner build --delete-conflicting-outputs` before testing

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
