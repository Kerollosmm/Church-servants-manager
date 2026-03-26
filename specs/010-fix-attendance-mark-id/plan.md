# Implementation Plan: Fix Attendance Mark Document ID

**Branch**: `010-fix-attendance-mark-id` | **Date**: 2026-03-24 | **Spec**: `specs/010-fix-attendance-mark-id/spec.md`
**Input**: Feature specification from `C:\Users\KimoStore\church_managment_system\specs\010-fix-attendance-mark-id\spec.md`

## Summary

Align attendance mark identity around `studentId` so repeated marking for the same student and session remains idempotent, preserve the existing attendance-taking Cubit workflow, and align any local attendance-record identity with the same student-based key while keeping queue correlation IDs separate.

## Technical Context

**Language/Version**: Dart >= 3.9.2  
**Primary Dependencies**: Flutter 3.x, `cloud_firestore`, `flutter_bloc`, `fake_cloud_firestore`  
**Storage**: Cloud Firestore under `classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`; local attendance persistence only if an attendance-record model exists in the current source tree  
**Testing**: `flutter_test`, `fake_cloud_firestore` repository tests, targeted Cubit regression verification  
**Target Platform**: Flutter mobile app (Android/iOS primary) with Firebase-backed data flows  
**Project Type**: Feature-first mobile application  
**Performance Goals**: Preserve the current single-mark mutation flow so repeat marking updates the same record without introducing extra user-visible steps or slower roster refresh behavior  
**Constraints**: Minimal surgical change only; Firestore access remains in the repository layer; no widget logic changes; preserve existing present/late mark behavior and derived absent behavior; add fix traceability comments on touched lines  
**Scale/Scope**: One attendance feature slice, one repository mutation path, one attendance-taking Cubit flow, and related regression coverage

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Production Stability & Schema Integrity**: PASS - plan preserves the existing attendance collection structure and keeps mark writes scoped to the existing marks subcollection; no cross-feature schema redesign or destructive migration is introduced.
- **II. Surgical & Minimal Interventions**: PASS - scope is limited to attendance mark identity, local record identity alignment if present, and regression tests.
- **III. Business Logic Isolation (Cubits Only)**: PASS - no new business logic is moved into widgets; the existing Cubit continues to call repository methods only.
- **IV. Encapsulated Data Access (Repository Layer)**: PASS - Firestore write behavior remains inside `lib/features/attendance/data/repos/attendance_repository.dart`.
- **V. Feature-First Structure**: PASS - planned changes stay inside the attendance feature and its corresponding tests, with any local persistence touch kept adjacent to the feature if present.
- **Technical Constraints**: PASS - no DI changes are required, immutable state remains unchanged, and any generated-model change would trigger the required code generation workflow.
- **Fix Traceability**: PASS - implementation will annotate touched fix lines using `// FIX [010-*]: ...`.

**Post-Design Re-check**: PASS - research confirms the repository already resolves mark documents by `studentId`, so the design remains a compatibility-preserving verification and local identity-alignment task rather than a broader schema change.

## Project Structure

### Documentation (this feature)

```text
specs/010-fix-attendance-mark-id/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── README.md
│   └── attendance-mark-identity.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── constants/
│       └── firestore_collections.dart
└── features/
    └── attendance/
        ├── data/
        │   ├── models/
        │   │   ├── attendance_enums.dart
        │   │   ├── attendance_mark.dart
        │   │   ├── attendance_roster_item.dart
        │   │   └── attendance_session.dart
        │   └── repos/
        │       └── attendance_repository.dart
        ├── domain/
        │   └── repos/
        │       └── i_attendance_repository.dart
        └── presentation/
            └── bloc/
                └── attendance_taking/
                    ├── attendance_taking_cubit.dart
                    └── attendance_taking_state.dart

test/
└── features/
    └── attendance/
        └── data/
            └── repos/
                └── attendance_repository_test.dart
```

**Structure Decision**: Use the existing single-project Flutter structure and keep the work inside the attendance feature repository and regression tests. No route, DI, or UI structure changes are planned. If a local attendance-record persistence model is found during implementation outside the currently scanned attendance files, it should be updated surgically in place rather than restructuring the feature.

## Complexity Tracking

No constitution violations or exceptional complexity are expected for this feature.
