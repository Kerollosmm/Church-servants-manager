---
description: Flutter specific rules, performance, and best practices
---

# Flutter Best Practices

## Project Structure
* **Standard:** Assumes a standard Flutter project structure with `lib/main.dart` as the primary entry point.

## Style Guide
* **SOLID:** Apply SOLID principles throughout.
* **Declarative:** Write concise, modern, technical Dart code. Prefer functional/declarative patterns.
* **Composition:** Favor composition over inheritance for complex widgets and logic.
* **Immutability:** Prefer immutable data structures. Widgets (especially `StatelessWidget`) should be immutable.
* **Widgets are for UI:** Compose complex UIs from smaller, reusable widgets. Break down large `build()` methods into private Widget classes.
* **Private Widgets:** Use small, private `Widget` classes instead of private helper methods returning `Widget`.

## Performance
* **Rebuilds:** Use `const` constructors for widgets and in `build()` methods whenever possible.
* **Isolates:** Use `compute()` for expensive calculations (e.g., JSON parsing) to avoid blocking the UI.
* **Lists:** Use `ListView.builder` or `SliverList` for lazy-loading long lists.
* **Build Methods:** Avoid expensive operations (network calls, complex computations) directly in `build()`.

## Package Management
* **Tools:** Use `pub` or `flutter pub` to manage dependencies.
* **Selection:** Use `pub_dev_search` or choose suitable, stable packages from pub.dev.
* **Commands:**
    * Add: `flutter pub add <package>`
    * Dev: `flutter pub add dev:<package>`
    * Override: `flutter pub add override:<package>:1.0.0`
    * Remove: `dart pub remove <package>`

## Lint Rules
Use `package:flutter_lints/flutter.yaml` in `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Add additional lint rules here
```
