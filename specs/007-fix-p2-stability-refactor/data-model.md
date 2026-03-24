# Data Model: P2 Stability and Correctness Refactor

## Entities

### TeamMembersState
Represents the collective state of all team members.
- **Fields**: 
  - `List<Member> members`: Collection of team member entities.
  - `bool isLoading`: Indicates if data is being fetched.
  - `String? error`: Optional error message.
- **Validation Rules**: Must support value-based equality using `Equatable` or `hashCode`/`==`.
- **State Transitions**: Initial -> Loading -> Loaded | Error.

### StudentDataBloc
Orchestrates student-related business logic.
- **Dependencies (Required)**:
  - `GetStudentsUseCase`
  - `UpdateStudentUseCase`
  - `SyncStudentUserUseCase`
- **Validation Rules**: All dependencies must be non-null and provided at instantiation.

### Validators
Static utility for input validation.
- **Internal Helper**: `_validate(String? value, String emptyMsg, String invalidMsg, bool Function(String) patternCheck)`
- **Behavior**: Shares core logic between English and Arabic validation methods.
