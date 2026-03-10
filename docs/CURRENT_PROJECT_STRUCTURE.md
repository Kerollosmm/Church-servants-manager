# CSMS Current Project Structure

> **Date Captured:** 2026-02-03
> **Status:** In Development (Cleaned)
>
> **Important:** This file is partially stale after the archive/restore and attendance refactors.
> See `docs/ACCOUNT_LIFECYCLE_AND_ATTENDANCE_POLICY.md` for the current lifecycle and attendance behavior.

---

## 📁 Root Directory

```plaintext
church_managment_system/
├── .agent/                         # AI Agent Configuration (Antigravity Kit)
├── .dart_tool/                     # Dart tooling cache
├── .firebaserc                     # Firebase project alias
├── .flutter-plugins-dependencies   # Flutter plugin metadata
├── .git/                           # Git repository
├── .gitignore                      # Git ignore rules
├── .idea/                          # IDE settings
├── .metadata                       # Flutter project metadata
├── android/                        # Android platform
├── build/                          # Build output
├── docs/                           # Project documentation
├── firebase.json                   # Firebase configuration
├── firestore.indexes.json          # Firestore index definitions
├── firestore.rules                 # Firestore security rules
├── ios/                            # iOS platform
├── lib/                            # Main Dart source code
├── linux/                          # Linux platform
├── macos/                          # macOS platform
├── pubspec.lock                    # Dependency lock file
├── pubspec.yaml                    # Project dependencies
├── test/                           # Unit and widget tests
├── web/                            # Web platform
└── windows/                        # Windows platform
```

---

## 📂 `lib/` Source Code Structure

```plaintext
lib/
├── app.dart                        # App root widget (role-based initial routing)
├── firebase_options.dart           # Firebase configuration (generated)
├── main.dart                       # App entrypoint
│
├── core/                           # Shared infrastructure
│   ├── constants/
│   │   ├── enums.dart              # App-wide enums (UserRole, etc.)
│   │   └── firestore_collections.dart  # Firestore collection names
│   │
│   ├── models/
│   │   └── auth_user.dart          # Firebase Auth user model
│   │
│   ├── routing/
│   │   ├── app_router.dart         # Named route generation
│   │   └── route_args.dart         # Route argument passing
│   │
│   ├── theme/
│   │   └── app_theme.dart          # App-wide theme configuration
│   │
│   ├── utils/
│   │   └── data_seeder.dart        # Test data seeding utility
│   │
│   └── widgets/
│       └── dialogs/
│           ├── error_dialog.dart   # Error dialog widget
│           └── generic_dialog.dart # Generic dialog base
│
└── features/                       # Feature modules (Clean Architecture)
    │
    ├── auth/                       # ✅ Authentication feature
    │   ├── data/
    │   │   └── services/
    │   │       ├── auth_provider.dart          # Auth provider interface
    │   │       ├── auth_service.dart           # Auth service facade
    │   │       └── firebase_auth_provider.dart # Firebase implementation
    │   │
    │   ├── domain/
    │   │   ├── failures/
    │   │   │   ├── auth_exceptions.dart        # Auth exception types
    │   │   │   └── auth_failures.dart          # Auth failure model
    │   │   │
    │   │   └── repos/
    │   │       └── auth_repository.dart        # Repository interface
    │   │
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── auth_bloc.dart              # Auth BLoC (login, logout, role)
    │       │   ├── auth_event.dart             # Auth events
    │       │   └── auth_state.dart             # Auth states
    │       │
    │       ├── screens/
    │       │   ├── forgot_password_screen.dart # Password reset UI
    │       │   ├── login_screen.dart           # Login UI
    │       │   └── register_screen.dart        # Registration UI
    │       │
    │       └── widgets/
    │           ├── auth_header.dart            # Auth screen header
    │           ├── auth_submit_button.dart     # Submit button widget
    │           ├── auth_text_field.dart        # Styled text field
    │           └── email_verification_dialog.dart  # Email verify dialog
    │
    ├── devtools/                   # Development tools
    │   └── presentation/
    │       └── dev_tools_screen.dart   # Developer utilities screen
    │
    ├── servant/                    # ✅ Servant (Teacher) feature
    │   └── presentation/
    │       └── screens/
    │           └── servant_dashboard_screen.dart   # Servant main dashboard
    │
    └── student/                    # ✅ Student management feature
        ├── data/
        │   ├── models/
        │   │   ├── student_model.dart          # Student data model
        │   │   ├── student_model.freezed.dart  # Freezed generated
        │   │   └── student_model.g.dart        # JSON serialization
        │   │
        │   ├── repos/
        │   │   └── student_data_repository.dart    # Firestore CRUD repository
        │   │
        │   └── services/
        │       └── role_based_student_service.dart # Role-filtered service
        │
        └── presentation/
            ├── bloc/
            │   ├── student_data/
            │   │   ├── student_data_bloc.dart      # Student list BLoC
            │   │   ├── student_data_event.dart     # Events
            │   │   └── student_data_state.dart     # States
            │   │
            │   └── student_profile/
            │       ├── student_profile_bloc.dart   # Profile BLoC
            │       ├── student_profile_event.dart  # Events
            │       └── student_profile_state.dart  # States
            │
            └── screens/
                ├── student_detail_screen.dart      # View single student
                ├── student_edit_screen.dart        # Edit student form
                ├── student_home_screen.dart        # Student role home
                ├── student_management_screen.dart  # Admin student list
                └── student_profile_screen.dart     # Profile view
```

---

## 📊 Current State Summary

| Metric | Count |
|--------|-------|
| **Features** | 3 Active (auth, student, devtools) + 1 Scaffold (servant) |
| **BLoCs** | 3 (AuthBloc, StudentDataBloc, StudentProfileBloc) |
| **Screens** | 10 |
| **Widgets** | 6 (shared) |
| **Data Models** | 2 (AuthUser, StudentModel) |
| **Repositories** | 1 (StudentDataRepository) |
| **Services** | 3 (AuthService, AuthProvider, RoleBasedStudentService) |

---

## 🏗️ Architecture Pattern

**Current Implementation:**
- **State Management:** BLoC/Cubit (flutter_bloc)
- **Folder Structure:** Feature-first with Clean Architecture layers
- **Data Layer:** Direct Firestore calls (Firebase SDK)
- **Auth:** Firebase Authentication
- **Code Generation:** Freezed + json_serializable

---

## ✅ What's Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| Firebase Auth (Email/Password) | ✅ Complete | Login, Register, Forgot Password |
| Role-based Routing | ✅ Complete | Admin, Servant, Student roles |
| Student CRUD | ✅ Complete | Create, Read, Update, Delete |
| Student List with Pagination | ✅ Complete | Cursor-based pagination |
| Search Students | ✅ Complete | Prefix search on name |
| Student Profile View | ✅ Complete | Detail and edit screens |
| Servant Dashboard | ✅ Scaffold | Basic layout only |
| Dev Tools | ✅ Utility | For development/debug |

---

## 🚧 What's Pending (Empty/Placeholder)

| Area | Status | Missing |
|------|--------|---------|
| `features/attendance/` | ❌ Removed | Cleanup: Folders removed as they were empty |
| `features/servant/` | ⚠️ Partial | Missing data/domain layers (folders removed) |
| Offline Storage (Hive) | ❌ Not Started | No local caching implemented |
| Sync Engine | ❌ Not Started | No background sync queue |
| Conflict Detection | ❌ Not Started | No versioning/flagging mechanism |
| Admin Portal | ❌ Not Started | No admin-specific web features |
| Reporting/Analytics | ❌ Not Started | No reporting module |

---

## 📁 Documentation (`docs/`)

```plaintext
docs/
├── PLAN-role-crud-ui.md            # Role CRUD implementation plan
├── bloc.md                         # BLoC pattern reference
├── code_review.md                  # Code review guidelines
├── dart_3_updates.md               # Dart 3 features reference
├── effective_dart.md               # Dart style guide
├── firebase/                       # Firebase-specific docs
├── flutter_app_architecture.md     # Architecture decisions
├── flutter_change_notifier.md      # ChangeNotifier reference
├── flutter_errors.md               # Error handling patterns
├── mockito.md                      # Mockito testing reference
├── mocktail.md                     # Mocktail testing reference  
├── provider.md                     # Provider reference
├── riverpod.md                     # Riverpod reference
└── testing.md                      # Testing strategy
```

---

## 🔥 Firebase Configuration

| File | Purpose |
|------|---------|
| `firebase.json` | Firebase CLI config |
| `firestore.rules` | Security rules |
| `firestore.indexes.json` | Composite indexes |
| `.firebaserc` | Project alias |
| `lib/firebase_options.dart` | Platform-specific config |

---

## 🧪 Test Directory

```plaintext
test/
└── (5 files - unit/widget tests)
```

---

*This document represents the current state as of the capture date and should be updated as the project evolves.*
