# Implementation Plan: Fix Firestore Collection Casing

**Branch**: `009-fix-firestore-casing` | **Date**: 2026-03-24 | **Spec**: `C:\Users\KimoStore\church_managment_system\specs\009-fix-firestore-casing\spec.md`
**Input**: Feature specification from `C:\Users\KimoStore\church_managment_system\specs\009-fix-firestore-casing\spec.md`

## Summary

Correct the canonical Firestore collection path values from uppercase to lowercase, then normalize any hardcoded Firestore path literals that still use `Users`, `Students`, or `Classes` across app code, Cloud Functions, tests, and Firestore index configuration. The implementation remains intentionally surgical: only string values representing Firestore collection paths are changed, while Dart type names, constant identifiers, and existing feature behavior stay intact.

## Technical Context

**Language/Version**: Dart >= 3.9.2 for Flutter app, TypeScript for Firebase Cloud Functions  
**Primary Dependencies**: Flutter, Firebase Auth, Cloud Firestore, Cloud Functions, flutter_bloc, get_it, freezed/json_serializable  
**Storage**: Cloud Firestore  
**Testing**: `flutter test`, `flutter analyze`, existing repository/BLoC tests, Firebase-related unit tests  
**Target Platform**: Android/iOS Flutter client and Firebase backend tooling  
**Project Type**: Mobile app with Firebase backend  
**Performance Goals**: No measurable runtime change; maintain current behavior with zero additional user-visible latency  
**Constraints**: Surgical scope only; no schema redesign; no class or constant renames; must preserve repository-layer Firestore access patterns; must align with lowercase security-rule paths  
**Scale/Scope**: Shared collection path contract used by app repositories, services, Cloud Functions, test fixtures, and Firestore index definitions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Production Stability & Schema Integrity**: Pass. Lowercase collection paths restore alignment with the intended Firestore schema and security rules without changing document structure.
- **Surgical & Minimal Interventions**: Pass. Scope is limited to Firestore path string values and direct path literals discovered by repo-wide search.
- **Business Logic Isolation (Cubits Only)**: Pass. No widget or Cubit business logic changes are planned.
- **Encapsulated Data Access (Repository Layer)**: Pass. Repository usage remains intact; only collection path values change.
- **Feature-First Structure**: Pass. No feature structure changes are required.
- **Fix Traceability**: Pass with implementation requirement. Any changed production code lines must include `// FIX [009]: reason` annotations.
- **Code Generation**: Not applicable. No `freezed` or `json_serializable` source changes are planned.

**Post-Design Re-Check**: Pass. Phase 1 artifacts keep the implementation within existing architecture, require no schema redesign, and do not justify any constitution exceptions.

## Project Structure

### Documentation (this feature)

```text
specs/009-fix-firestore-casing/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── firestore-collection-paths.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/constants/firestore_collections.dart
├── features/auth/data/services/
├── features/student/data/repos/
├── features/student/data/services/
├── features/team/data/repos/
├── features/attendance/data/repos/
└── features/admin/data/

functions/
└── src/index.ts

test/
├── features/team/data/repos/team_repository_test.dart
└── features/attendance/data/repos/attendance_repository_test.dart

firestore.indexes.json
```

**Structure Decision**: Keep the existing single-project Flutter + Firebase repository structure. The implementation touches only the shared Firestore collection constant file and any direct Firestore path literals found in `lib/`, `functions/`, `test/`, and `firestore.indexes.json`.

## Phase 0: Research Summary

- Confirm the canonical collection names that must be used everywhere.
- Identify all hardcoded Firestore path literals that bypass the shared constants.
- Confirm whether non-Dart artifacts participating in Firestore path resolution are in scope.

## Phase 1: Design Summary

- Treat collection names as a shared cross-layer contract.
- Update the contract in one canonical constant file.
- Normalize discovered hardcoded Firestore path strings in code, tests, functions, and index config.
- Verify no identifier renames or behavior changes are needed.

## Complexity Tracking

No constitution violations or complexity exceptions are required for this feature.
