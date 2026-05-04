# AGENTS.md - Church Servants Management System (CSMS)

## Build / Lint / Test Commands

### Flutter Core Commands
```bash
flutter run                          # Run the app
flutter build apk --debug            # Build debug APK
flutter build apk --release          # Build release APK
flutter analyze                     # Analyze code (linting)
flutter test                        # Run all tests
flutter test --coverage             # Run tests with coverage
flutter test test/path/to/file.dart # Run single test file
flutter test --name "TestName"      # Run single test by name
flutter test --watch                # Run tests in watch mode
flutter clean && flutter pub get    # Clean and rebuild
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs  # Generate code
dart run build_runner watch --delete-conflicting-outputs # Watch mode
```

---

## Code Style Guidelines

### General Principles
- Write **production-grade** code, not tutorial code
- Follow **Clean Architecture** already established in this project
- Enforce **offline-first** as a non-negotiable constraint
- Protect the **Firebase Spark free tier** budget at all times

### Linting Rules (analysis_options.yaml)
```yaml
rules:
  - always_use_package_imports     # Use package: imports, not relative
  - prefer_final_locals            # Use final for local variables
  - prefer_final_in_for_each       # Use final in for-each loops
  - avoid_print                    # Never use print(), use log() from dart:developer
  - prefer_single_quotes           # Use single quotes for strings
  - directives_ordering           # Order imports properly
  - cascade_invocations            # Use cascades where appropriate
  - unnecessary_lambdas            # Avoid unnecessary lambdas
  - use_build_context_synchronously
  - unawaited_futures              # Always handle futures properly
  - unreachable_from_main          # No unreachable code in main
```

### Imports & Naming
- **Always use package imports:** `import 'package:church_management_system/features/auth/...'`
- **Never use relative imports**
- **Order:** dart imports → package imports → relative imports
- **Classes/Types:** PascalCase (`AuthBloc`, `AttendanceSession`)
- **Methods/variables:** camelCase (`getSessionRecords`, `syncStatus`)
- **Files:** snake_case (`auth_bloc.dart`, `attendance_repository.dart`)

### Error Handling
- **Use Either<Failure, T>** for repository return types
- **Domain failures only:** Never expose raw Exceptions in domain layer
- **Wrap exceptions:** Convert Firebase/Hive exceptions to domain Failures

### Types
- Use built-in types when appropriate (int, String, bool, List, Map)
- **Use Freezed** for immutable data classes with equality
- **Use Equatable** for BLoC states and events
- **Avoid dynamic** - always type explicitly

---

## Architecture Rules

### Clean Architecture Layers
```
lib/
├── core/                    # Shared utilities (constants, errors, services, di)
├── features/               # Feature modules with domain/data/presentation
│   ├── auth/              # Login, JWT, role resolution
│   ├── attendance/        # Session creation, mark attendance
│   ├── servant/           # Servant management
│   ├── student/           # Student management
│   └── team/              # Team management
└── shared/                 # Shared widgets
```

### BLoC Pattern Conventions
```dart
// State must model all three loading states
abstract class AttendanceState {}
class AttendanceInitial extends AttendanceState {}
class AttendanceLoading extends AttendanceState {}
class AttendanceLoaded extends AttendanceState {
  final List<AttendanceRecord> records;
  final SyncStatus syncStatus;
}
class AttendanceError extends AttendanceState {
  final Failure failure;  // Use domain Failure, not raw Exception
}
```

### Offline-First Rules (CRITICAL)
- **Hive reads BEFORE Firestore reads** - minimize quota consumption
- **Never read Firestore in loops** - can exhaust daily quota
- **Use recordId as Firestore document ID** - idempotent writes
- **syncStatus on EVERY attendance record** - `pending → synced → failed`
- **Batch writes on sync** - never single writes
- **Custom Claims for RBAC** - zero-cost vs. Firestore reads

### Firebase Spark Plan Constraints
- **NO Cloud Functions** - unavailable on Spark plan
- **Client-side handles everything** - manual token refresh, claim updates
- **Local-first, sync-on-demand** - writes to Hive first, Firestore sync when online
- **Pagination + lazy loading** - no full collection reads

---

## Security Rules Pattern
```javascript
// servants — servants read own profile; admin writes all
match /servants/{userId} {
  allow read: if request.auth.uid == userId || request.auth.token.role == 'admin';
  allow write: if request.auth.token.role == 'admin';
}

// attendanceRecords — servant writes; student reads own only
match /attendanceRecords/{recordId} {
  allow read: if request.auth.token.role in ['admin', 'servant']
              || request.auth.uid == resource.data.studentUid;
  allow create, update: if request.auth.token.role in ['admin', 'servant'];
}

// audit_logs — admin read only
match /audit_logs/{logId} {
  allow read: if request.auth.token.role == 'admin';
  allow write: if false;
}
```

---

## Role Matrix

| Capability | Admin | Servant | Teacher | Viewer |
|------------|:----:|:-------:|:-------:|:------:|
| Create attendance session | ✅ | ❌ | ❌ | ❌ |
| Mark attendance | ✅ | ✅ | ❌ | ❌ |
| View group attendance report | ✅ | ✅ | ✅ | ❌ |
| View own attendance only | ✅ | ✅ | ✅ | ✅ |
| Add/edit students | ✅ | ❌ | ❌ | ❌ |
| View audit logs | ✅ | ❌ | ❌ | ❌ |
| Upload results | ✅ | ❌ | ❌ | ❌ |

---

## CodeRabbit Configuration
- Review focuses on `lib/` directory and `firestore.rules`
- Focus: Flutter/Dart best practices, clean architecture, offline-first logic
- Security: RBAC (Servant vs Admin vs Student), data integrity

---

## Definition of Done
A task is **Done** only when:
- [ ] Works 100% offline (no crash, no empty state, no spinner freeze)
- [ ] Firestore writes use `recordId` as document ID
- [ ] `syncStatus` field present and correctly transitions
- [ ] Role enforcement works via Custom Claims (not Firestore reads)
- [ ] No Firestore reads inside loops or on every rebuild
- [ ] Unit test for use case logic exists
- [ ] Widget test for loading/error/success states exists
- [ ] No `print()` statements left in code (use `log()` from `dart:developer`)
- [ ] Tested on real device with **airplane mode ON**