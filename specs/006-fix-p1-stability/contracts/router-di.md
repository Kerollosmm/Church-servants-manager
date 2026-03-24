# Interface Contract: Router Dependency Mapping

## Overview
The `AppRouter` is responsible for instantiating BLoCs/Cubits for feature screens. To ensure stability, it must resolve all dependencies through `getIt`.

## Dependency Resolution Rules

### 1. No BuildContext for Data
- **Rule**: NEVER use `context.read<T>()` to retrieve repositories or use cases within `AppRouter`.
- **Reason**: `AppRouter` is not a widget and its lifecycle is not bound to the widget tree in a way that guarantees provider availability during background transitions.

### 2. Service Locator Pattern
- **Rule**: All use cases and services must be retrieved via `getIt<T>()`.
- **Registration**: All dependencies must be registered in `lib/core/di/injection.dart` before the router is called.

### 3. Feature BLoC Instantiation
- **Rule**: BLoCs created within `AppRouter` (e.g., via `_withStudentDataBloc`) must receive their full dependency set through their constructor via `getIt`.
