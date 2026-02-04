# CODEBASE.md - File Dependency Map

> **Purpose:** Track file dependencies to ensure related files are updated together.
> **Last Updated:** 2026-02-03

---

## 🔗 Core Dependency Graph

### Entry Points

| File | Depends On | Dependents |
|------|------------|------------|
| `lib/main.dart` | `app.dart`, `AppRouter`, `AppTheme`, `AuthService`, `AuthBloc`, `StudentDataRepository`, `StudentDataBloc`, `StudentProfileBloc`, `firebase_options.dart` | *(App entrypoint)* |
| `lib/app.dart` | `AuthBloc`, `LoginScreen`, `ServantDashboardScreen`, `StudentProfileScreen`, `UserRole` | `main.dart` |

---

## 🏛️ Core Layer Dependencies

### Constants

| File | Depends On | Dependents |
|------|------------|------------|
| `core/constants/enums.dart` | *(none)* | `AuthUser`, `app.dart`, `StudentModel`, most screens |
| `core/constants/firestore_collections.dart` | *(none)* | `StudentDataRepository`, `AuthService` |

### Models

| File | Depends On | Dependents |
|------|------------|------------|
| `core/models/auth_user.dart` | `enums.dart` (UserRole) | `AuthBloc`, `AuthState`, `app.dart`, `ServantDashboardScreen`, `StudentProfileScreen` |

### Routing

| File | Depends On | Dependents |
|------|------------|------------|
| `core/routing/app_router.dart` | `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `StudentManagementScreen`, `StudentDetailScreen`, `StudentEditScreen`, `DevToolsScreen`, `route_args.dart` | `main.dart` |
| `core/routing/route_args.dart` | `StudentModel` | `app_router.dart`, `StudentDetailScreen`, `StudentEditScreen` |

### Theme

| File | Depends On | Dependents |
|------|------------|------------|
| `core/theme/app_theme.dart` | *(Flutter)* | `main.dart` |

### Widgets

| File | Depends On | Dependents |
|------|------------|------------|
| `core/widgets/dialogs/error_dialog.dart` | `generic_dialog.dart` | `app.dart`, various screens |
| `core/widgets/dialogs/generic_dialog.dart` | *(Flutter)* | `error_dialog.dart` |

---

## 🔐 Auth Feature Dependencies

### Data Layer

| File | Depends On | Dependents |
|------|------------|------------|
| `auth/data/services/auth_service.dart` | `auth_provider.dart`, `firebase_auth_provider.dart` | `AuthBloc`, `main.dart` |
| `auth/data/services/auth_provider.dart` | `AuthUser` | `auth_service.dart`, `firebase_auth_provider.dart` |
| `auth/data/services/firebase_auth_provider.dart` | `auth_provider.dart`, `AuthUser`, `auth_exceptions.dart`, FirebaseAuth | `auth_service.dart` |

### Domain Layer

| File | Depends On | Dependents |
|------|------------|------------|
| `auth/domain/failures/auth_exceptions.dart` | *(none)* | `firebase_auth_provider.dart`, `AuthBloc` |
| `auth/domain/failures/auth_failures.dart` | *(none)* | `AuthBloc`, `AuthState` |
| `auth/domain/repos/auth_repository.dart` | `AuthUser` | *(interface - not actively used yet)* |

### Presentation Layer

| File | Depends On | Dependents |
|------|------------|------------|
| `auth/presentation/bloc/auth_bloc.dart` | `auth_event.dart`, `auth_state.dart`, `auth_service.dart`, `AuthUser` | `main.dart`, `app.dart`, all authenticated screens |
| `auth/presentation/bloc/auth_event.dart` | *(none)* | `auth_bloc.dart`, screens triggering auth |
| `auth/presentation/bloc/auth_state.dart` | `AuthUser` | `auth_bloc.dart`, `app.dart` |
| `auth/presentation/screens/login_screen.dart` | `AuthBloc`, auth widgets | `app.dart`, `app_router.dart` |
| `auth/presentation/screens/register_screen.dart` | `AuthBloc`, auth widgets | `app_router.dart` |
| `auth/presentation/screens/forgot_password_screen.dart` | `AuthBloc`, auth widgets | `app_router.dart` |

---

## 👨‍🎓 Student Feature Dependencies

### Data Layer

| File | Depends On | Dependents |
|------|------------|------------|
| `student/data/models/student_model.dart` | `freezed`, `json_annotation` | `StudentDataRepository`, `StudentDataBloc`, all student screens |
| `student/data/models/student_model.freezed.dart` | `student_model.dart` | *(generated)* |
| `student/data/models/student_model.g.dart` | `student_model.dart` | *(generated)* |
| `student/data/repos/student_data_repository.dart` | `StudentModel`, `firestore_collections.dart`, Firestore | `main.dart`, `StudentDataBloc`, `StudentProfileBloc` |
| `student/data/services/role_based_student_service.dart` | `StudentDataRepository`, `StudentModel` | *(role filtering layer)* |

### Presentation Layer

| File | Depends On | Dependents |
|------|------------|------------|
| `student/presentation/bloc/student_data/student_data_bloc.dart` | `student_data_event.dart`, `student_data_state.dart`, `StudentDataRepository`, `StudentModel` | `main.dart`, `StudentManagementScreen` |
| `student/presentation/bloc/student_data/student_data_event.dart` | *(none)* | `student_data_bloc.dart`, screens |
| `student/presentation/bloc/student_data/student_data_state.dart` | `StudentModel` | `student_data_bloc.dart`, screens |
| `student/presentation/bloc/student_profile/student_profile_bloc.dart` | `student_profile_event.dart`, `student_profile_state.dart`, `StudentDataRepository` | `main.dart`, `StudentProfileScreen` |
| `student/presentation/screens/student_management_screen.dart` | `StudentDataBloc`, `StudentModel` | `app_router.dart` |
| `student/presentation/screens/student_detail_screen.dart` | `StudentModel`, `route_args.dart` | `app_router.dart` |
| `student/presentation/screens/student_edit_screen.dart` | `StudentModel`, `StudentDataBloc`, `route_args.dart` | `app_router.dart` |
| `student/presentation/screens/student_profile_screen.dart` | `AuthUser`, `StudentProfileBloc` | `app.dart` |
| `student/presentation/screens/student_home_screen.dart` | `AuthUser` | *(role-based home)* |

---

## 👨‍🏫 Servant Feature Dependencies

| File | Depends On | Dependents |
|------|------------|------------|
| `servant/presentation/screens/servant_dashboard_screen.dart` | `AuthUser`, `AppRouter` | `app.dart` |

---

## 🔧 DevTools Feature Dependencies

| File | Depends On | Dependents |
|------|------------|------------|
| `devtools/presentation/dev_tools_screen.dart` | *(Flutter)* | `app_router.dart` |

---



---

## ⚠️ Critical Dependency Rules

### When modifying these files, ALWAYS update:

| If You Change... | Also Update... |
|------------------|----------------|
| `UserRole` enum | All role-checking logic in `app.dart`, screens |
| `AuthUser` model | `AuthState`, `auth_bloc.dart`, screens using user |
| `StudentModel` | Generated files (run `build_runner`), repository, BLoC states |
| `firestore_collections.dart` | Verify Firestore rules match |
| `app_router.dart` routes | Any screen navigation calls |
| BLoC events/states | Screens consuming the BLoC |

### Code Generation Commands

```bash
# After changing @freezed or @JsonSerializable models:
dart run build_runner build --delete-conflicting-outputs
```

---

## 🔄 Dependency Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        main.dart                            │
│  (Initializes Firebase, creates BLoCs, runs app)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         app.dart                            │
│  (Listens to AuthBloc, routes by role)                      │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────────┐   ┌────────────┐
        │ Login    │   │ Servant      │   │ Student    │
        │ Screen   │   │ Dashboard    │   │ Profile    │
        └──────────┘   └──────────────┘   └────────────┘
              │               │                   │
              ▼               ▼                   ▼
        ┌──────────┐   ┌──────────────┐   ┌────────────────┐
        │ AuthBloc │   │ AppRouter    │   │ StudentProfile │
        │          │   │ (navigate)   │   │ Bloc           │
        └──────────┘   └──────────────┘   └────────────────┘
              │               │                   │
              ▼               ▼                   ▼
        ┌──────────┐   ┌──────────────┐   ┌────────────────┐
        │ Auth     │   │ Student      │   │ StudentData    │
        │ Service  │   │ Management   │   │ Repository     │
        └──────────┘   └──────────────┘   └────────────────┘
              │               │                   │
              ▼               ▼                   ▼
        ┌──────────────────────────────────────────────────┐
        │                    FIREBASE                      │
        │  (Auth + Firestore)                              │
        └──────────────────────────────────────────────────┘
```

---

*This document must be kept in sync with the actual codebase. Update when adding new features or changing dependencies.*
