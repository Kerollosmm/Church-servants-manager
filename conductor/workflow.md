# Development Workflow - CSMS

## 1. Branching Strategy
- **`main`**: Production branch. Must always be stable and deployable.
- **`feature/<feature-name>`**: Short-lived feature branches created off `main`.
- **`fix/<bug-name>`**: Bugfix branches created off `main`.

## 2. Commit Standards
- Follow Conventional Commits (`feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`, `test: ...`).
- Atomic commits with clear descriptions explaining *why* changes were made.

## 3. Pull Request & Quality Gates
- PRs targeting `main` must pass static analysis (`flutter analyze` / `dart analyze`).
- All unit and widget tests must pass before merging.
- Architectural guidelines (Clean Architecture, BLoC, Hive, Firestore RBAC) enforced during review.

## 4. Conductor Integration
- Work is organized into high-level Tracks in `conductor/tracks/`.
- Each Track defines a `spec.md`, `plan.md`, and `tasks.md`.
