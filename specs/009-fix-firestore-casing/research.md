# Research: Fix Firestore Collection Casing

## Decision 1: Use lowercase collection names everywhere Firestore paths are defined

- **Decision**: Standardize all Firestore collection path values to `users`, `students`, and `classes`.
- **Rationale**: The feature spec, security rules contract, and user-provided scope all define lowercase paths as the authoritative names. Aligning all path definitions removes the mismatch that currently breaks rule evaluation and runtime path consistency.
- **Alternatives considered**:
  - Keep uppercase names and change rules instead: rejected because the requested fix explicitly requires lowercase collection names.
  - Add runtime translation between uppercase and lowercase names: rejected because it adds complexity and hides the underlying contract mismatch.

## Decision 2: Search and normalize direct path literals beyond the shared constants

- **Decision**: Include hardcoded Firestore path strings in app code, tests, Cloud Functions, and Firestore index configuration in the implementation scope.
- **Rationale**: Repo-wide search shows direct usages of `Users`, `Students`, and `Classes` outside `lib/core/constants/firestore_collections.dart`. Leaving those unchanged would keep the codebase internally inconsistent and could break validation, tests, or backend tooling after the constants are corrected.
- **Alternatives considered**:
  - Limit the change to `lib/core/constants/firestore_collections.dart` only: rejected because the updated user input explicitly requires a full-codebase search for hardcoded Firestore path strings.
  - Normalize only production code and ignore tests/config: rejected because tests and Firestore indexes are part of the executable contract and would continue encoding the wrong paths.

## Decision 3: Keep identifiers unchanged and modify only string values representing Firestore collection paths

- **Decision**: Preserve Dart class names, constant names, and method signatures; change only string values that represent actual Firestore collection names.
- **Rationale**: This matches the original acceptance criteria, satisfies the constitution's surgical-change principle, and minimizes regression risk.
- **Alternatives considered**:
  - Rename `FirestoreCollections` members for stylistic consistency: rejected because it creates unnecessary caller churn.
  - Refactor repositories to centralize more path handling: rejected because it expands scope beyond the requested defect fix.

## Decision 4: Treat Firestore indexes and Cloud Functions as part of the same path contract

- **Decision**: Normalize `firestore.indexes.json` collection groups and any backend constants used by Cloud Functions.
- **Rationale**: These artifacts reference the same collection namespace as the Flutter app. A partial update would leave backend/admin flows and index definitions inconsistent with the intended schema.
- **Alternatives considered**:
  - Leave index and function files untouched because they are not Flutter files: rejected because they still participate in Firestore path resolution.

## Decision 5: Validate using compile-focused and existing regression checks

- **Decision**: Verify the change with repo-wide string search, `flutter analyze`, and the existing test suites most directly covering attendance and team repositories/BLoCs.
- **Rationale**: The feature risk is contract drift, not algorithmic complexity. The most meaningful validation is that path mismatches are eliminated and existing covered behavior still works.
- **Alternatives considered**:
  - Skip automated validation because the change is "just strings": rejected because the bug directly affects protected data access.
  - Run every possible test suite regardless of scope: rejected as unnecessary for planning; targeted regression coverage is sufficient for this surgical fix.
