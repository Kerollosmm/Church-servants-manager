# Developer Guide

## Development Workflow

### Daily Cycle

1. `flutter pub get` — sync dependencies after pulling.
2. `dart run build_runner build --delete-conflicting-outputs` — regenerate after model changes.
3. `flutter run` — hot-reload for UI changes; hot-restart for state/DI changes.
4. `flutter test` — run the test suite before pushing.

---

## Code Structure Philosophy

### Feature-First Vertical Slices

Each feature in `lib/features/` owns its full stack from data to UI. The boundary between features is clear: one feature calls another only through shared domain interfaces or use-cases registered in the DI container, never by directly importing another feature's internal implementation.

### Clean Layering

- **Presentation → Domain:** BLoCs/Cubits call repository interfaces or use-cases; they never import Firestore SDK classes.
- **Domain → Data:** Repository interfaces abstract away Firestore details. Domain code is testable without a real Firebase instance.
- **Data → Firebase:** Only the `data/` layer and DI configuration know about `FirebaseFirestore`, `FirebaseAuth`, etc.

### Shared Code Policy

Code in `lib/core/` is used by multiple features. If you find yourself writing a utility that two features need, put it in `core/` — not in either feature.

---

## Adding a New Feature

1. Create `lib/features/<feature>/` with `data/`, `domain/`, `presentation/` subdirectories.
2. Define the domain interface in `domain/repos/i_<feature>_repository.dart`.
3. Define domain failure types in `domain/failures/<feature>_failures.dart`.
4. Implement the repository in `data/repos/<feature>_repository.dart`.
5. Create `@freezed` models in `data/models/`. Run `build_runner` after.
6. Register the repository singleton in `core/di/injection.dart`.
7. Create BLoC/Cubit in `presentation/bloc/`.
8. Add screens to `presentation/screens/` and routes to `core/constants/routes.dart`.
9. Wire routes in `core/routing/app_router.dart`.

---

## Adding a New Screen (to an Existing Feature)

1. Create the screen widget in the feature's `presentation/screens/`.
2. If the screen needs data, create a Cubit in `presentation/bloc/` and instantiate it in the router (`AppRouter.onGenerateRoute`) using `BlocProvider`.
3. Add a route string constant to `core/constants/routes.dart`.
4. Add a `case` in `AppRouter.onGenerateRoute`. Use `_buildArgsValidatedRoute<T>` if the screen requires typed arguments.
5. Add a matching `RouteArgs` class in `core/routing/route_args.dart` if needed.

---

## Admin-Gated Routes

Wrap the screen widget with `AdminGate` in `AppRouter`:

```dart
case myAdminRoute:
  return _buildPageRoute(
    builder: (_) => const AdminGate(child: MyAdminScreen()),
    settings: settings,
  );
```

`AdminGate` reads `AuthBloc` and renders a forbidden screen if the current user is not an admin.

---

## Data Models

All models use `@freezed`. The anatomy of a model file:

```dart
@freezed
class MyModel with _$MyModel {
  const MyModel._(); // For custom methods

  const factory MyModel({
    required String id,
    @Default(false) bool isArchived,
    @FirestoreTimestampConverter() DateTime? createdAt,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
  factory MyModel.fromMap(Map<String, dynamic> data, String docId) { ... }
  Map<String, dynamic> toMap() => toJson();
}
```

Key conventions:
- `fromMap(data, docId)` — used for Firestore document hydration. Normalize all strings and handle null gracefully.
- `toMap()` — removes the document ID before writing (Firestore ignores the `id` field but keeping it out avoids surprises).
- Use `@FirestoreTimestampConverter()` for every `DateTime?` field. Firestore returns `Timestamp` objects, not `DateTime`.

After modifying a model, always run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## State Management Conventions

### BLoC vs Cubit

- Use **BLoC** (`Bloc<Event, State>`) when the feature has multiple distinct triggering events that warrant explicit domain modelling (e.g., `AuthBloc`).
- Use **Cubit** for simpler state machines where a method call is sufficient (e.g., `TeamCubit.loadTeams()`).

### State Design

States are `sealed` classes. Each subclass is a distinct case. Never use nullable fields on the parent to distinguish states — add a new subclass instead.

```dart
sealed class MyState { const MyState(); }
class MyInitial extends MyState { const MyInitial(); }
class MyLoading extends MyState { const MyLoading(); }
class MyLoaded extends MyState {
  final List<MyModel> items;
  const MyLoaded(this.items);
}
class MyError extends MyState {
  final String message;
  const MyError(this.message);
}
```

### Error Mapping

Repository implementations catch low-level exceptions and rethrow typed domain failures. BLoCs catch domain failures and convert them to error states with user-readable messages. Raw exception types (Firebase exceptions, network errors) must not leak into the presentation layer.

---

## Testing Approach

The project includes `fake_cloud_firestore` and `mocktail` as dev dependencies.

### Unit Tests

Place in `test/`. Test domain use-cases and repository implementations in isolation:

```dart
// Use FakeFirebaseFirestore for repository tests
final firestore = FakeFirebaseFirestore();
final repo = MyRepository(firestore: firestore);
```

### Bloc/Cubit Tests

Use `bloc_test` pattern from `flutter_bloc`:

```dart
blocTest<MyCubit, MyState>(
  'emits [Loading, Loaded] when successful',
  build: () => MyCubit(repository: mockRepo),
  act: (cubit) => cubit.load(),
  expect: () => [const MyLoading(), isA<MyLoaded>()],
);
```

### Firestore Rule Tests

Security rules in `firestore.rules` can be tested using the Firebase Emulator Suite:

```bash
firebase emulators:start
# Run rule-specific tests using @firebase/rules-unit-testing
```

---

## Debugging

### Auth State

Add a `BlocListener<AuthBloc, AuthState>` to any widget and `debugPrint` the incoming state. Or use the Flutter DevTools BLoC extension.

### Firestore Queries

Enable Firestore debug logging in development:

```dart
FirebaseFirestore.setLoggingEnabled(true); // dev only
```

### Degraded Mode

If the app shows "unable to refresh permissions" snackbars, `AuthDegraded` has been emitted. The root cause is a Firestore read failure for `Users/{uid}`. Check Firestore rules, network, and whether the user document exists.

### Attendance Session Confusion

The `AttendanceRepository` uses a clock stream to re-evaluate session open/closed state every 15 seconds client-side. If the UI shows stale open/closed state immediately after a manually set server timestamp, wait 15 seconds or force a state refresh via the cubit.
