# Research: Code Review Remediation Best Practices

## Error Handling Patterns
- **Decision**: Replace empty `catch (e) {}` blocks with structured logging and failure propagation.
- **Rationale**: Swallowing errors makes production debugging impossible. 
- **Pattern**: 
  ```dart
  try {
    // ...
  } catch (e, s) {
    developer.log('Failure description', error: e, stackTrace: s);
    throw SpecificException(e.toString());
  }
  ```

## Dependency Injection for Firebase
- **Decision**: Always inject `FirebaseAuth` and `FirebaseFirestore` via constructor parameters with `GetIt` as the provider.
- **Rationale**: Enables unit testing with mocks/fakes (e.g., `mocktail`, `fake_cloud_firestore`).
- **Pattern**:
  ```dart
  class MyRepository {
    final FirebaseAuth _auth;
    MyRepository({FirebaseAuth? auth}) : _auth = auth ?? GetIt.I<FirebaseAuth>();
  }
  ```

## State Management Refactoring
- **Decision**: Extract `setState` logic into Cubits for complex interactions (forms, navigation logic).
- **Rationale**: Align with the project's "Business Logic Isolation" constitution principle.
- **Alternatives Considered**: Keeping `setState` for trivial UI toggles (rejected for consistency).

## Type Safety Fixes
- **Decision**: Explicitly cast or map `dynamic` results from Firestore to typed models.
- **Rationale**: Resolve the `argument_type_not_assignable` errors in `student_query_service.dart` and `role_user_route.dart`.
- **Pattern**: `(data as List).map((e) => Model.fromJson(e)).toList()`.
