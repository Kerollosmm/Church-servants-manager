# Product Guidelines - CSMS

## 1. Architectural & Engineering Standards
- **Clean Architecture**: Mandatory 3-layer separation across all features:
  - `presentation/`: BLoCs/Cubits, Widgets, Pages, UI state classes.
  - `domain/`: Entities, Value Objects, Use Cases, Repository interfaces.
  - `data/`: Data Models (DTOs), Repository implementations, Local Data Sources (Hive), Remote Data Sources (Firestore).
- **State Management**:
  - `flutter_bloc` / `bloc` for state management.
  - Immutable BLoC states with `freezed` or `equatable`.
  - Zero business logic inside Widgets.
- **Offline-First Data Flow & Client Sync**:
  - Write directly to local Hive cache first.
  - Queue sync transactions with unique, idempotent `recordId` keys in a client outbox queue.
  - Sync queue drains automatically via client-side Flutter background service / network listener using Firestore batch writes.
  - **Zero Cloud Functions**: Spark plan constraint — all batching, validation, and sync outbox logic executed client-side in Flutter.
- **Security & Tokens**:
  - Sensitive credentials, auth tokens, and session data stored strictly in `flutter_secure_storage`.
  - Server-side enforcement relies solely on Firestore Security Rules (Firestore-first RBAC evaluating user role documents via `get()`).

## 2. Code Quality & Maintenance
- **Language**: English for code, variable names, class names, comments, and commit messages.
- **Code Style**:
  - Strict null safety enforcement.
  - Comprehensive linter rules via `analysis_options.yaml`.
  - Explicit error handling with `Either<Failure, T>` (dartz).
- **Testing Standard**:
  - Unit tests for all Use Cases and BLoCs.
  - Mocking external dependencies via `mocktail` / `mockito`.

## 3. Visual & UX Guidelines
- **RTL & Localization**: Full Arabic language support with native Right-to-Left (RTL) layout handling.
- **Design Tokens**: Centralized colors, typography, spacing, and elevation in `core/theme/`.
- **User Interface**: Instant visual feedback on user interactions; seamless offline indicators when disconnected.
