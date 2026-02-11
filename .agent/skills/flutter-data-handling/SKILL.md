---
name: flutter-data-handling
description: Guidelines for JSON serialization, Logging, and Code Generation
license: Private
---

# Flutter Data Handling

## JSON Serialization
Use `json_serializable` and `json_annotation`.

* **Conventions:**
    * Use `fieldRename: FieldRename.snake` to map Dart `camelCase` to JSON `snake_case`.

```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String name;
  User(this.name);
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Code Generation
* **Build Runner:** Ensure `build_runner` is in `dev_dependencies`.
* **Execution:** Run `dart run build_runner build --delete-conflicting-outputs` after changes.

## Logging
Use `dart:developer` for structured logging, or `package:logging`.

```dart
import 'dart:developer' as developer;

try {
  // ...
} catch (e, s) {
  developer.log(
    'Error fetching data',
    name: 'my.app.data',
    error: e,
    stackTrace: s,
  );
}
```
