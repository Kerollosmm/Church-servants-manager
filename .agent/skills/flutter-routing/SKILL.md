---
name: flutter-routing
description: Routing and Navigation standards using GoRouter and Navigator
license: Private
---

# Flutter Routing

## GoRouter (Preferred for App Nav)
Use `go_router` for deep linking, web support, and declarative routing.

**Setup:**
1. `flutter pub add go_router`
2. Define `GoRouter` config.
3. Use `MaterialApp.router`.

```dart
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'details/:id',
          builder: (context, state) => DetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    // Handle auth redirection here
  },
);
```

## Navigator (Simple/Local)
Use `Navigator` for short-lived, linear interactions (Dialogs, temporary screens) that typically don't need deep links.

```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen()));
Navigator.pop(context);
```
