# Research: Fix P2 Stability and Correctness Issues

**Decision: Value-based equality for TeamMembersState**
- **Rationale**: The constitution mandates value-based equality for all state classes to optimize UI performance by preventing unnecessary rebuilds. Equatable is preferred for simple state classes without complex data structures, while Freezed is recommended for complex models.
- **Alternatives considered**: Manual `==` and `hashCode` implementation (rejected as brittle and error-prone).

**Decision: GetIt Registration Order Optimization**
- **Rationale**: Dependency injection requires that providers/services are registered before their consumers to ensure runtime stability. `StudentLinkedUserSyncService` must precede `StudentDataRepository` in `injection.dart`.
- **Alternatives considered**: Lazy evaluation (rejected as it can mask wiring errors).

**Decision: Validator Consolidation Pattern**
- **Rationale**: `Validators` should use a shared internal helper (`_validate`) to minimize code duplication between English and Arabic versions while maintaining clean public APIs.
- **Alternatives considered**: Deprecating English variants (rejected as they might be needed for future localization or internal tools).

**Decision: Strict Injection for StudentDataBloc**
- **Rationale**: Enforcing required parameters in the constructor and removing fallback constructors ensures that all dependencies are explicitly managed by the DI container, aligning with the "Explicit Control" principle in the constitution.
- **Alternatives considered**: Optional parameters with fallback constructors (rejected as they leak concrete classes and bypass DI).

**Decision: Factory Registration for TeamCubit**
- **Rationale**: BLoCs and Cubits that are not globally singleton should be registered as factories in GetIt to ensure they are properly scoped and recreated when needed, typically provided via `BlocProvider`.
- **Alternatives considered**: Manual instantiation in `initState` (rejected as it couples UI to BLoC instantiation details).
