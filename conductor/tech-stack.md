# Tech Stack - Church Servants Manager (CSMS)

## Core Technologies
*   **Language:** [Dart](https://dart.dev/) - The primary programming language for building the application.
*   **Framework:** [Flutter](https://flutter.dev/) - UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.

## Frontend & UI
*   **Design System:** [Material Design 3](https://m3.material.io/) - Modern design principles used for consistent and accessible UI components.
*   **Typography:** [Google Fonts](https://pub.dev/packages/google_fonts) - Used for high-quality, custom typography across the app.
*   **State Management:** [BLoC (Business Logic Component)](https://pub.dev/packages/flutter_bloc) - Used to separate presentation from business logic using reactive programming.

## Data & Backend
*   **Cloud Platform:** [Firebase](https://firebase.google.com/)
    *   **Authentication:** [Firebase Auth](https://pub.dev/packages/firebase_auth) - Secure user authentication and role management.
    *   **Database:** [Cloud Firestore](https://pub.dev/packages/cloud_firestore) - Real-time NoSQL database for cloud data storage.
*   **Local Storage:** [Hive](https://pub.dev/packages/hive) - A lightweight and blazing fast key-value database for offline support and ephemeral state.
*   **Serialization:** [json_serializable](https://pub.dev/packages/json_serializable) & [freezed](https://pub.dev/packages/freezed) - Used for type-safe data modeling and JSON serialization.

## Development & Architecture
*   **Pattern:** Feature-based Layered Architecture (Clean Architecture principles)
    *   **Presentation Layer:** Widgets and BLoCs.
    *   **Domain Layer:** Models and Business Logic interfaces.
    *   **Data Layer:** Repositories, Data Sources, and API clients.
*   **Testing:**
    *   **Unit/Widget Tests:** `flutter_test` and `bloc_test`.
    *   **Mocks:** `mocktail` for expressive and type-safe mocking in tests.
*   **Code Generation:** `build_runner` - Orchestrates code generation for Hive, Freezed, and JSON serialization.