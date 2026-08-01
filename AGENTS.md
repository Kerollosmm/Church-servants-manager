# ChurchServers Management System (CSMS)

## Project Identity
- **Project**: ChurchServers Management System
- **Stack**: Flutter + Firebase (Spark Plan - Free Tier)
- **Architecture**: Clean Architecture (feature-first) + BLoC pattern
- **Data**: Offline-first (Hive SSOT → Firestore sync)
- **Roles**: Admin, Servant, Teacher - RBAC via Custom Claims

## Non-Negotiable Constraints
1. **Offline-first** - Hive is the single source of truth for UI. Firestore is the remote source of truth.
2. **Minimize Firestore reads** - Spark plan limits. Use local caching aggressively.
3. **No Cloud Functions** - Spark plan restriction. All logic in-app.
4. **RBAC** - Use Firebase Custom Claims (fallback to Firestore rules).
5. **Hive SSOT** - UI reads from Hive, writes go to Hive first, then sync to Firestore.
6. **Agent Memory** - Always read the `memory/` directory and `CLAUDE.md` at the start of any task to establish context, active branch/phase, and retrieve stored preferences.

## Architecture Layers (per feature)
```
feature/
  data/
    datasources/    # local (Hive) & remote (Firestore)
    models/         # data models (fromJson/toJson / mappable)
    repos/          # repository implementations
    services/       # query/command services
  domain/
    entities/       # business logic entities
    repos/          # abstract repository interfaces
  presentation/
    bloc/           # BLoC/Cubit state management
    screens/        # full-page widgets
    widgets/        # reusable widgets
```

## Coding Conventions
- Use `flutter_lints` / strict analysis options
- No `// ignore:` comments without justification
- Prefer `const` constructors
- Use `sealed class` for BLoC states
- Use `@freezed` or `@MappableClass` for models
- Always handle loading, error, and empty states in BLoC
- BLoC event handlers MUST account for `InitialState` and empty cache when evaluating event guard conditions to ensure initial data fetches execute
- Use standard ASCII characters (`-`, `'`, `"`) in Dart comments and string literals to prevent Windows CLI/Git encoding artifacts
- Document TDD-justified plan deviations in the commit message body to prevent false-positive scope creep flags during audits
- Omit explicit `param: null` arguments when calling methods/constructors where `null` is already the default value to avoid `avoid_redundant_argument_values` lints
- Repository pattern: local datasource first, remote fallback
- SyncService handles offline queue → Firestore sync


### Auto-Enforced Rules (DO NOT VIOLATE)
- **No `print()`/`debugPrint()`** in production code — use `developer.log()`
- **No silent catch** — every `catch` MUST log `(e, stackTrace)` via `developer.log()`
- **No `unawaited()`** without `.catchError()` handler
- **No `getIt<>()`** in widgets/build methods — pass via constructor
- **No `FirebaseFirestore.instance`** in business logic — inject via constructor
- **No `!` null assertion** in production code — use `??`, `?.`, or pattern matching
- **No `await init()`** in every method — use eager init + `_initialized` guard
- **No hardcoded secrets/API keys** — use `--dart-define` or env vars
- **No PII in logs** — don't log names, emails, phone, IDs
- **No sync handler enqueue loop** — handlers must call remote-write, not re-enqueue
- **Firestore rules MUST have `if` guards** — never allow without condition

## Testing Requirements
- Unit tests for BLoCs, Repos, Services
- Widget tests for screens
- Run `flutter analyze lib/` before COMMITTING
- Run `flutter test` before COMMITTING

## Key Dependencies
- `flutter_bloc` - state management
- `get_it` + `injectable` - DI
- `hive` + `hive_flutter` - local storage
- `firebase_core`, `cloud_firestore`, `firebase_auth` - backend
- `go_router` - navigation
- `freezed` / `mappable` - code gen models
