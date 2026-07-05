# Audit Report: CSMS Project State Gap Analysis (`project_state_audit`)

> **Track Goal**: Perform a comprehensive, read-only code-archaeologist gap analysis comparing the documented specifications (`conductor/product.md`, `conductor/tech-stack.md`, `conductor/product-guidelines.md`) against the actual implementation in the `lib/` codebase.

---

## Section A: ✅ Fully Implemented (Matches Spec)

### 1. Client-Side Outbox Sync Engine & Offline Data Flow
- **Hive Local Storage**: Outbox queue (`SyncEntry`), dead letter queue (`DeadLetterQueue`), and local model persistence implemented using `hive` (^2.2.3) and `hive_flutter` (^1.1.0).
- **Client-Side Outbox Pattern**: Implemented in [`lib/core/models/sync_entry.dart`](file:///C:/Users/KimoStore/church_managment_system/lib/core/models/sync_entry.dart) and [`lib/core/services/sync_service.dart`](file:///C:/Users/KimoStore/church_managment_system/lib/core/services/sync_service.dart).
- **Idempotent Client Synchronization**: Every sync transaction is assigned a unique, client-side generated UUID `recordId`. Mutations use Firestore batch writes without Cloud Functions.
- **Retry & Resilience**: Sequential FIFO queue execution with consecutive batch chunking (up to 400 entries), exponential backoff with random jitter, and dead-letter queue (DLQ) eviction after 5 max retries.
- **Connectivity & Background Execution**: Integrated with `connectivity_plus` (^7.1.1) and `workmanager` (^0.9.0+3) background tasks.

### 2. Firestore Security Rules & Firestore-First RBAC
- **Security Rules File**: Found at [`firestore.rules`](file:///C:/Users/KimoStore/church_managment_system/firestore.rules) (481 lines).
- **Firestore-First RBAC**: Server-side security reads user roles directly from Firestore document `/Users/$(request.auth.uid)` using `get()`. Evaluates `callerRole() in ['admin', 'servant']` and sector/team access.
- **Zero Cloud Functions Constraint**: Completely free of Cloud Functions or Custom Claims dependencies, fulfilling Firebase Spark Plan constraints.

### 3. Authentication & User Management Feature (`lib/features/auth/`)
- **Domain Layer**: [`lib/features/auth/domain/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/auth/domain/) contains `AuthUser` entity, `AuthException`/`AuthFailure` types, and `AuthRepository` interface.
- **Data Layer**: [`lib/features/auth/data/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/auth/data/) contains `AuthUser` DTO models, `FirebaseAuthRepository` implementation, `AuthUserLocalStore` (Hive), and `FirebaseIdentityProvider`.
- **Presentation Layer**: [`lib/features/auth/presentation/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/auth/presentation/) contains `AuthBloc`, `AuthGate`, `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `VerifyEmailScreen`, and `ForcedPasswordResetScreen`.

### 4. Servants Management Feature (`lib/features/servant/`)
- **Domain Layer**: [`lib/features/servant/domain/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/servant/domain/) contains `Servant` & `ServantPage` entities, `IServantRepository` interface, and `ProvisionServantWithAuthUseCase`.
- **Data Layer**: [`lib/features/servant/data/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/servant/data/) contains `ServantLocalDatasource` (Hive), `ServantDataRepository`, and `ServantSyncHandler`.
- **Presentation Layer**: [`lib/features/servant/presentation/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/servant/presentation/) contains `ServantDashboardCubit`, `ServantDataBloc`, `ServantDashboardScreen`, `ServantListScreen`, `ServantDetailScreen`, and `AddEditServantScreen`.

### 5. Students Management Feature (`lib/features/student/`)
- **Domain Layer**: [`lib/features/student/domain/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/student/domain/) contains `Student` entity, `IStudentRepository`, `IPastoralRepository`, `GetStudentsListUseCase`, `CanMutateStudentUseCase`, and `ProvisionStudentWithAuthUseCase`.
- **Data Layer**: [`lib/features/student/data/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/student/data/) contains `StudentLocalDatasource`, `PastoralLocalDatasource`, `StudentDataRepository`, `PastoralRepository`, `StudentSyncHandler`, and `PastoralSyncHandler`.
- **Presentation Layer**: [`lib/features/student/presentation/`](file:///C:/Users/KimoStore/church_managment_system/lib/features/student/presentation/) contains `StudentDataBloc`, `StudentProfileBloc`, `StudentFormTeamsCubit`, `StudentManagementScreen`, `StudentHomeScreen`, `StudentDetailScreen`, `StudentEditScreen`, and `StudentProfileScreen`.

---

## Section B: 🟡 Partially Implemented (Exists but Incomplete / Non-Standard)

### 1. Attendance Tracking Feature (`lib/features/attendance/`)
- **Domain & Data Layers**: Entities (`AttendanceSession`, `AttendanceRosterSnapshot`), datasources (`AttendanceLocalDatasource`, `AttendanceSessionLocalDatasource`), repositories (`AttendanceRepository`, `AttendanceSessionRepository`), and sync handlers (`AttendanceSyncHandler`) exist.
- **Presentation Layer**: BLoCs (`AttendanceBloc`, `AttendanceTakingBloc`, `AttendanceHistoryBloc`, `AttendanceSessionAdminBloc`) and screens (`TakeAttendanceScreen`, `AttendanceHistoryScreen`, `AttendanceSessionCreateScreen`) exist.
- **Structural Anomaly**: Non-standard folders [`lib/features/attendance/bloc`](file:///C:/Users/KimoStore/church_managment_system/lib/features/attendance/bloc) and [`lib/features/attendance/screens`](file:///C:/Users/KimoStore/church_managment_system/lib/features/attendance/screens) exist directly under `attendance/` in addition to `presentation/`. These legacy/duplicate folders must be consolidated into `presentation/` to strictly align with Feature-First Clean Architecture.

### 2. Results & Term Management Feature (`lib/features/results/`)
- **Status**: Partially stubbed.
- **Existing Code**: `Result` entity, `ResultsLocalDatasource`, `ResultsRepository`, `ResultSyncHandler`, `ResultsBloc`, and `GradeEntryScreen` exist.
- **Gaps**: Missing comprehensive student result history view screen, term configuration management screen, and domain-layer failures/usecases.

### 3. Admin & Team Management Features (`lib/features/admin/`, `lib/features/team/`)
- **Existing Code**: `AdminPolicy`, `AdminTeamService`, `AdminDashboardScreen`, and `AdminGate` exist in `admin/`. Basic team structures exist in `team/`.
- **Gaps**: Lacks full CRUD workflows for team assignment and servant sector role delegation.

### 4. UI Product Guidelines Violations
- **Hardcoded Colors**: Direct usage of raw color literals (e.g. `Color(0xFF334155)`, `Colors.grey.shade500`, `Colors.blue.shade600`) found in presentation screens instead of referencing centralized `AppColors` tokens in [`lib/core/theme/app_colors.dart`](file:///C:/Users/KimoStore/church_managment_system/lib/core/theme/app_colors.dart).
- **Hardcoded Strings**: Raw hardcoded Arabic strings (e.g., `'إنشاء جلسة حضور'`) embedded directly inside UI widgets instead of using centralized localization assets or string constants.

---

## Section C: ❌ Not Started (Planned but Zero Code Found)

- **Automated Localization & ARB Files**: Comprehensive ARB-based internationalization setup (`l10n.yaml` and `.arb` files) is not configured; strings are currently inline.
- **Automated End-to-End Golden UI Tests**: While unit/mocktail tests exist, automated Golden UI snapshot tests for key attendance taking flows are not yet implemented.

---

## Section D: 🚫 Out-of-Scope Code Found (Needs Cleanup / Removal)

1. **Unused AI Package in `pubspec.yaml`**:
   - Package `google_generative_ai: ^0.4.7` is listed in [`pubspec.yaml`](file:///C:/Users/KimoStore/church_managment_system/pubspec.yaml#L49) but has zero imports or references across `lib/`. It should be removed to keep dependencies lean.
2. **Duplicate/Legacy Folder Remnants in `lib/features/attendance/`**:
   - `lib/features/attendance/bloc/` and `lib/features/attendance/screens/` exist alongside `lib/features/attendance/presentation/`. These legacy folders create confusion and violate strict 3-layer Clean Architecture.

---

## Section E: Recommended Next Track

Based on the missing components, architectural priorities, and dependency flow, the recommended next tracks are:

1. **Track 1 (`attendance_refactor_and_sync`)**:
   - Clean up non-standard directory structure in `lib/features/attendance/` (consolidate `bloc` and `screens` into `presentation/`).
   - Finalize offline attendance recording, local roster caching, and outbox batch sync verification.
2. **Track 2 (`results_management`)**:
   - Complete domain use cases, term management UI, and student grade view screens for the Results feature.
3. **Track 3 (`theme_and_l10n_hardening`)**:
   - Refactor hardcoded colors to `AppColors` design tokens and extract UI strings to centralized localization.

---
*Audit completed by Code Archaeologist Subagent on 2026-07-06.*
