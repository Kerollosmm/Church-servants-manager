# Implementation Plan: Fix P3 Backlog Issues

**Branch**: `008-fix-p3-issues` | **Date**: 2026-03-23 | **Spec**: [/specs/008-fix-p3-issues/spec.md](spec.md)
**Input**: Feature specification from `/specs/008-fix-p3-issues/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature addresses several P3 issues identified in the Principal Engineer Code Review. The primary goal is to improve the app's stability, UX transparency, and code quality. Technical approaches include implementing cursor-based Firestore pagination for large data sets, integrating a system-wide network connectivity listener with a non-intrusive UI indicator, adding a real-time session countdown timer in the attendance flow, and cleaning up legacy theme tokens.

## Technical Context

**Language/Version**: Dart ^3.9.2, Flutter 3.x  
**Primary Dependencies**: `flutter_bloc`, `get_it`, `go_router`, `freezed`, `equatable`, `firebase_auth`, `cloud_firestore`, `connectivity_plus` (expected for offline detection)  
**Storage**: Firebase Firestore (Offline persistence enabled)  
**Testing**: `flutter test` (Unit tests for pagination logic, Widget tests for OfflineIndicator and CountdownBanner)  
**Target Platform**: Mobile (Android/iOS)
**Project Type**: Mobile app  
**Performance Goals**: Initial list load (20 items) < 500ms; List memory pressure < 100MB for 500+ items  
**Constraints**: MUST be offline-capable; MUST NOT break existing Firestore schema; Logic MUST reside in Cubits/Blocs  
**Scale/Scope**: Support for churches with 500+ students per team; App-wide connectivity awareness

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Production Stability & Schema Integrity | ✅ PASS | No schema changes requested; strictly additive/refactoring behavior. |
| Surgical & Minimal Interventions | ✅ PASS | Each fix is targeted at a specific P3 issue. |
| Business Logic Isolation (Cubits Only) | ✅ PASS | Pagination and Timer logic will be encapsulated in Cubits. |
| Encapsulated Data Access (Repository Layer) | ✅ PASS | Firestore pagination will be implemented in the Repository layer. |
| Feature-First Structure | ✅ PASS | Changes will be applied within existing feature slices (`attendance`, `student_management`). |
| Immutable & Comparable State | ✅ PASS | Using `freezed` and `equatable` for all state updates. |
| Dependency Injection (GetIt) | ✅ PASS | New services (e.g., ConnectivityService) will be registered in `injection.dart`. |

## Project Structure

### Documentation (this feature)

```text
specs/008-fix-p3-issues/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── theme/
│   │   └── app_colors.dart      # Mark legacy aliases as @Deprecated
│   ├── widgets/
│   │   └── offline_indicator.dart # NEW: Global offline banner
│   └── services/
│       └── connectivity_service.dart # NEW: Wrapper for connectivity_plus
├── features/
│   ├── attendance/
│   │   ├── data/repositories/
│   │   ├── domain/repositories/
│   │   ├── presentation/
│   │   │   ├── cubits/
│   │   │   │   └── attendance_session_timer_cubit.dart # NEW: Countdown logic
│   │   │   └── widgets/
│   │   │       └── session_expiry_banner.dart # NEW: UI for countdown
│   └── student_management/
│       ├── data/repositories/ # Update with pagination
│       ├── domain/repositories/
│       └── presentation/
│           └── cubits/ # Update with pagination state
```

**Structure Decision**: Standard feature-first structure. New global components (OfflineIndicator) go into `core/`. Feature-specific P3 fixes stay within their respective folders.

## Complexity Tracking

*No violations detected.*
