# Church Management System — اعداد خدام

A Flutter + Firebase mobile application for managing church servants, students, and attendance. The system supports three distinct roles (admin, servant, student) with role-gated navigation and real-time data synchronisation via Firestore.

---

## Capabilities

| Domain | Features |
|---|---|
| **Authentication** | Email/password sign-in, sign-up, email verification, password reset, account archival |
| **Role Dispatch** | Admin, Servant, and Student portals rendered from a single root widget based on `AuthState` |
| **Student Management** | CRUD for student profiles (name, contact info, grade, school, team assignment, archive) |
| **Servant Management** | CRUD for servant profiles; admin-only creation and archival |
| **Team Management** | Admin creates/archives teams; assigns servants to teams; manages team membership |
| **Attendance** | Session-based attendance (create → take → close → reopen); per-student mark history and statistics |
| **Dev Tools** | Internal screen for seeding and diagnostics (admin-gated) |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Material 3) |
| Language | Dart ≥ 3.9.2 |
| Backend | Firebase (Auth, Firestore, Cloud Functions) |
| State Management | `flutter_bloc` — BLoC for auth; Cubits for features |
| Dependency Injection | `get_it` (manual, no code-gen) |
| Data Models | `freezed` + `json_serializable` (immutable, auto-serialised) |
| Local Persistence | `hive` / `hive_flutter` |
| Reactive Streams | `rxdart` (`combineLatest`, `switchMap`) |
| Fonts | `google_fonts` |
| Functional Utilities | `dartz` (Either), `equatable` |

---

## Quick Start

See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for full prerequisites and environment setup.

```bash
# 1. Install dependencies
flutter pub get

# 2. Run code generation (Freezed, JSON, Hive)
dart run build_runner build --delete-conflicting-outputs

# 3. Start on a connected device / emulator
flutter run
```

---

## Repository Overview

```
church_managment_system/
├── lib/
│   ├── main.dart              # Entry point — Firebase init, DI setup, error handling
│   ├── church_app.dart        # Root widget — DI providers, global BLoC registration
│   ├── role_user_route.dart   # Role-based root dispatcher
│   ├── firebase_options.dart  # Generated Firebase config
│   ├── core/                  # Shared infrastructure
│   └── features/              # Vertical feature slices
├── firestore.rules            # Server-side security rules
├── firestore.indexes.json     # Composite index definitions
├── functions/                 # Cloud Functions (Node.js)
├── assets/                    # Static assets
└── pubspec.yaml
```

---

## Roles

| Role | Access |
|---|---|
| `admin` | Full system access — manages servants, students, teams, sessions; can reopen closed sessions |
| `servant` | Manages own team's students and takes attendance during open sessions |
| `student` | Read-only view of their own profile and attendance history |
