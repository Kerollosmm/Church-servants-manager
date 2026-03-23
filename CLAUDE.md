# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (Freezed, JSON serializable, Hive)
dart run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart

# Run tests with coverage
flutter test --coverage

# Run the app (connected device/emulator required)
flutter run

# Analyze code
flutter analyze
```

## Architecture Overview

This is a Flutter + Firebase church management app with a feature-sliced architecture:

### Tech Stack
- **Flutter 3.x** with Dart ≥ 3.9.2, Material 3
- **Firebase**: Auth, Firestore, Cloud Functions, Crashlytics
- **State Management**: flutter_bloc (BLoC for auth, Cubits for features)
- **DI**: get_it (manual registration, no code-gen)
- **Models**: freezed + json_serializable (immutable, auto-serialized)
- **Navigation**: go_router with role-based routing
- **Localization**: flutter_localizations with ARB files (Arabic primary)

### Directory Structure

```
lib/
├── main.dart              # Firebase init, DI setup, error handling
├── church_app.dart        # Root widget, MultiRepositoryProvider/MultiBlocProvider
├── role_user_route.dart   # Role-based navigation shell (admin/servant/student)
├── core/                  # Shared infrastructure
│   ├── constants/         # Enums (UserRole, AttendanceStatus, etc.), routes
│   ├── di/injection.dart  # get_it service registry
│   ├── routing/           # go_router configuration
│   ├── theme/             # AppTheme
│   ├── utils/             # Validators, converters, system_clock
│   └── widgets/           # Reusable widgets (adaptive, cards, dialogs, feedback, form, loading, navigation, search)
├── features/              # Vertical feature slices
│   ├── auth/              # Authentication
│   ├── student/           # Student management
│   ├── servant/           # Servant management
│   ├── team/              # Team management
│   ├── attendance/        # Attendance tracking
│   └── admin/             # Admin tools
└── l10n/                  # Generated localization files

Each feature follows:
├── data/
│   ├── models/            # freezed data classes
│   ├── repos/             # Repository implementations
│   └── services/          # Firebase/API services
├── domain/
│   ├── repos/             # Repository interfaces
│   ├── usecases/          # Business logic use cases
│   └── failures/          # Domain-specific failures
└── presentation/
    ├── bloc/              # BLoC/Cubit state management
    ├── screens/           # Screen widgets
    └── widgets/          # Feature-specific widgets
```

### Key Architectural Patterns

1. **Role-Based Navigation**: `role_user_route.dart` dispatches to different dashboard shells based on `UserRole` (admin, servant, student). Students see a read-only profile; admins and servants get tabbed navigation.

2. **Repository Pattern**: Each feature has `domain/repos/i_*_repository.dart` interfaces with `data/repos/*_repository.dart` implementations. Dependencies flow from presentation → domain ← data.

3. **BLoC/Cubit State Management**:
   - `AuthBloc` uses events and states for complex auth flows
   - Feature Cubits (e.g., `TeamCubit`, `StudentDataBloc`) handle simpler state
   - UseCases encapsulate business rules (e.g., `CanMutateStudentUseCase`)

4. **Dependency Injection**: Manual get_it registration in `core/di/injection.dart`. Services are singletons; repositories use factory or singleton as appropriate.

5. **Data Models**: All models use `freezed` for immutability with `json_serializable` for Firestore serialization. Use `fromJson`/`toJson` for JSON and custom `fromMap` for Firestore docs.

6. **Localization**: Arabic (ar_EG) is the primary locale. All user-facing strings must use `AppLocalizations.of(context)`.

### Navigation Flow

- `AppRouter` creates a `GoRouter` with auth state redirection
- Role-based shell routing via `StatefulShellRoute.indexedStack`
- Auth states: `AuthInitial`, `AuthLoading`, `AuthUnauthenticated`, `AuthNeedsVerification`, `AuthAuthenticated`, `AuthDegraded`, `AuthArchived`, `AuthError`

### Firestore Collections

Key collections (see individual repositories for details):
- `users` - User profiles with role, team, archive status
- `teams` - Team documents with servant assignments
- `attendance_sessions` - Attendance session records with marks

### Testing Strategy

- Unit tests use `mocktail` for mocking
- Widget tests use `flutter_test`
- Integration tests in `integration_test/`
- Tests mirror feature structure: `test/features/<feature>/<layer>/`

### Code Generation

After modifying models with `@freezed` or `@JsonSerializable`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Key Files to Understand

| File | Purpose |
|------|---------|
| `lib/core/di/injection.dart` | All DI registrations |
| `lib/core/routing/app_router.dart` | Route definitions and auth redirects |
| `lib/role_user_route.dart` | Role-based navigation shell |
| `lib/features/auth/presentation/bloc/auth_bloc.dart` | Auth state machine |
| `lib/features/auth/data/models/auth_user.dart` | Auth user model |

### Common Patterns

**Creating a new feature**:
1. Add models in `features/<name>/data/models/` with freezed
2. Define `I<Name>Repository` in `domain/repos/`
3. Implement repository in `data/repos/`
4. Create Cubit/Bloc in `presentation/bloc/`
5. Build screens in `presentation/screens/`
6. Register DI in `core/di/injection.dart`
7. Add routes in `core/routing/app_router.dart`

**Adding a new screen**:
1. Create screen widget in `presentation/screens/`
2. Add route constant in `core/constants/routes.dart`
3. Add GoRoute in `AppRouter.createRouter()`
4. If feature needs scoped state, use BlocProvider/RepositoryProvider

### Error Handling

- Domain failures extend `Failure` classes in `domain/failures/`
- BLoCs emit error states with user-friendly messages
- Firebase Crashlytics enabled for production error tracking

### Locale

Primary locale is Arabic (Egypt): `Locale('ar', 'EG')`. Use `flutter_gen` for l10n code generation.