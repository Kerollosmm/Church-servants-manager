# Implementation Plan: Protect Student Attendance Access

**Branch**: `011-fix-student-access` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-fix-student-access/spec.md`

## Summary

Correct student attendance authorization so self-read access is based on the student
document's linked user bridge instead of matching the student document ID to the signed-in
user ID. The implementation stays surgical: update the Firestore ownership helper, keep
servant/team access unchanged, add emulator coverage for self-read and cross-read, and
deploy the updated rules.

## Technical Context

**Language/Version**: Dart >= 3.9.2, TypeScript 5.9, Firestore Rules v2, Node 20  
**Primary Dependencies**: Flutter 3.x app, Cloud Firestore, Firebase CLI, Firebase Local Emulator Suite, `@firebase/rules-unit-testing`  
**Storage**: Cloud Firestore with attendance marks under `classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`  
**Testing**: `flutter analyze`, Firestore emulator rules tests, targeted rules deployment verification  
**Target Platform**: Firebase-backed Flutter mobile app (Android/iOS primary)  
**Project Type**: Mobile app with Firebase backend configuration  
**Performance Goals**: Preserve current attendance read behavior while keeping ownership evaluation to a single student-document lookup per authorization check  
**Constraints**: No schema-breaking change to attendance records; servant access path remains unchanged; changes must be limited to rules, rules-test support, and deployment workflow; changed code must include `// FIX [011-*]: reason` traceability where applicable  
**Scale/Scope**: Expected touch points are `firestore.rules`, `firebase.json` only if emulator config is needed, `functions/package.json` and test files for rules coverage, plus feature docs under `specs/011-fix-student-access/`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Production Stability & Schema Integrity | PASS | Plan limits changes to authorization logic and test coverage; attendance mark paths remain unchanged. |
| II. Surgical & Minimal Interventions | PASS | No unrelated refactors; only rule ownership logic, emulator tests, and deployment steps are in scope. |
| III. Business Logic Isolation (Cubits Only) | PASS | No widget or Cubit logic changes planned. |
| IV. Encapsulated Data Access (Repository Layer) | PASS | No application-layer Firestore access changes are introduced. |
| V. Feature-First Structure | PASS | App structure remains intact; new automated coverage lives alongside existing Firebase tooling. |
| Technical Constraints | PASS | No new app state models, DI changes, or codegen impact expected. |
| Dev Workflow: Fix Traceability | PASS | Implementation phase will annotate changed rule and test lines with `// FIX [011-*]: reason`. |

**Gate Result (Pre-Research)**: PASS

**Gate Result (Post-Design)**: PASS — design stays within existing Firestore schema boundaries, avoids app-layer architecture changes, and preserves servant authorization behavior.

## Project Structure

### Documentation (this feature)

```text
specs/011-fix-student-access/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── firestore-rules-access.md
└── tasks.md
```

### Source Code (repository root)

```text
firestore.rules
firebase.json
functions/
├── package.json
├── tsconfig.json
└── test/
    └── firestore_rules/
        └── student_attendance_access.test.ts

lib/
├── core/constants/firestore_collections.dart
└── features/
    ├── attendance/data/repos/attendance_repository.dart
    └── student/data/models/student_model.dart
```

**Structure Decision**: Keep implementation centered on repo-root Firebase configuration and
the existing `functions/` TypeScript toolchain for emulator rule tests. App feature files are
referenced only as schema/context inputs; no application code changes are planned unless the
implementation reveals a mismatch that blocks rules verification.

## Phase 0: Research

Research is complete. See [research.md](research.md).

Resolved decisions:
1. Firestore rules testing will be added as new automated coverage because no existing rules-test harness is present.
2. The existing `functions/` Node/TypeScript package is the lowest-friction home for emulator rule tests.
3. The feature will treat `students/{studentId}.linkedUser` as the authoritative ownership bridge for student self-read authorization, as required by the active feature request.
4. Attendance storage remains unchanged at `classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}`; only read authorization logic changes.
5. Rules deployment remains a dedicated Firebase CLI step after emulator verification.

## Phase 1: Design & Contracts

Design artifacts are complete:
- [data-model.md](data-model.md)
- [quickstart.md](quickstart.md)
- [contracts/firestore-rules-access.md](contracts/firestore-rules-access.md)

Design outcome:
- No new business entities or attendance document paths are introduced.
- The authorization contract is narrowed to one ownership bridge: student profile `linkedUser` to authenticated user ID.
- Emulator fixtures define the verification surface for allowed self-read, denied cross-read, and unchanged servant access.

## Phase 2: Implementation Plan

### Workstream A - Rule Update

1. Update `isOwnStudent(studentId)` in `firestore.rules` to load the student document and compare its `linkedUser` value to `request.auth.uid`.
2. Wire mark-read authorization so student reads depend on the ownership helper while servant access continues to rely on team-based access.
3. Keep collection paths and helper lookups aligned with the canonical runtime paths used by this feature's acceptance criteria.

### Workstream B - Emulator Test Coverage

1. Add Firestore rules test dependencies and a runnable test command in `functions/package.json`.
2. Create test fixtures covering:
   - student reads own mark -> allowed
   - student reads another student's mark -> denied
   - servant reads within team scope -> unchanged behavior
3. Seed only the minimum required documents for auth users, student profiles, team/session records, and mark docs.

### Workstream C - Deployment and Verification

1. Run the rules test suite against the Firestore emulator until self-read and cross-read outcomes pass.
2. Deploy the updated rules with the Firebase CLI once local verification succeeds.
3. Perform a targeted post-deploy verification against the same authorization scenarios or an equivalent smoke check.

## Complexity Tracking

No constitution violations or exceptional complexity expected.
