# Implementation Plan: God File Remediation

**Branch**: `002-god-file-remediation` | **Date**: 2026-03-19 | **Spec**: [docs/review/ORCHESTRATION_REPORT.md](../../docs/review/ORCHESTRATION_REPORT.md)

## Summary

Execute surgical, phased decomposition of every God Widget (>150 lines) and God Cubit/Bloc (>200 lines) identified in the `001-full-code-review` orchestration pass. Each fix follows the project constitution: **read, extract, test, never break the Firestore schema**.

25 files violate size and responsibility heuristics across 6 feature domains plus core routing. Work is split into 7 independent phases (one folder per phase) so each can be reviewed, tested, and merged independently.

## Technical Context

**Language/Version**: Dart ^3.9.2, Flutter 3.x
**Primary Dependencies**: flutter_bloc, get_it, go_router, freezed, equatable
**Storage**: Firebase Firestore (Production — no schema changes permitted)
**Testing**: flutter_test, mocktail, fake_cloud_firestore
**Target Platform**: Android, iOS (Mobile)
**Project Type**: Feature-First Vertical Slice
**Constraints**: Production stability, zero-breaking changes to Firestore schema, no route renaming, surgical fixes only.

## Constitution Check

- [x] **Schema Safety**: All fixes are UI/presentation-layer decomposition only — zero Firestore model changes.
- [x] **Production Stability**: Behavior must be identical before and after each phase.
- [x] **Surgical Scope**: Each file is only decomposed, not rewritten or feature-changed.
- [x] **Logic Isolation**: Business logic extracted from Widgets moves to Cubits (not the other way around).
- [x] **Data Access**: No Firestore calls are being moved. Repository layer unchanged.
- [x] **Immutable State**: No state class changes. Only file decomposition.
- [x] **Traceability**: All changed lines will include `// FIX [PHASE]: reason`.
- [x] **Design Decisions**: If a split introduces ambiguity, mark `HUMAN DECISION REQUIRED`.

## Project Structure

```text
specs/002-god-file-remediation/
├── plan.md                       # This file
├── phase-1-core-blocs/
│   ├── guide.md                  # Step-by-step instructions
│   └── tasks.md                  # Task checklist
├── phase-2-auth/
│   ├── guide.md
│   └── tasks.md
├── phase-3-servant/
│   ├── guide.md
│   └── tasks.md
├── phase-4-student/
│   ├── guide.md
│   └── tasks.md
├── phase-5-attendance/
│   ├── guide.md
│   └── tasks.md
├── phase-6-team/
│   ├── guide.md
│   └── tasks.md
└── phase-7-core-routing/
    ├── guide.md
    └── tasks.md
```

## Phase Overview

| Phase | Domain | God Files | Key Risk | Depends On |
|-------|--------|-----------|----------|------------|
| **1 - Core Blocs** | `auth`, `servant`, `student`, `team` Blocs/Cubits | 4 | State design breakage | None (can start immediately) |
| **2 - Auth** | `auth` screens & routing | 2 | Login/register regression | Phase 1 (auth_bloc fixed) |
| **3 - Servant** | `servant` screens & widgets | 5 | Form state breakage | Phase 1 (servant_data_cubit fixed) |
| **4 - Student** | `student` screens & widgets | 5 | CRUD regression | Phase 1 (student_data_bloc fixed) |
| **5 - Attendance** | `attendance` screens | 4 | Session flow regression | Phase 1 (attendance cubits stable) |
| **6 - Team** | `team` screens & dialogs | 3 | Team assignment breakage | Phase 1 (team_cubit fixed) |
| **7 - Core Routing** | `role_user_route.dart` | 1 | App-wide routing crash | Phase 2 (auth routing stable) |

> **Phase 1 is the prerequisite for all other phases.** Run Phase 1 first.

## Execution Rules

1. **One phase at a time.** Do not mix phases in a single PR.
2. **Run `flutter analyze` + `flutter test`** after each file extraction before moving on.
3. **Run `dart run build_runner build --delete-conflicting-outputs`** if any `freezed` or `json_serializable` files are touched.
4. **Mark every changed line** with `// FIX [P{phase_number}]: reason`.
5. If a split is ambiguous, write `// HUMAN DECISION REQUIRED` and skip that sub-extraction.

## Verification Plan

### Automated

```bash
# After each phase
flutter analyze
flutter test

# Only if freezed files changed
dart run build_runner build --delete-conflicting-outputs
```

### Manual

1. Run the app on an Android emulator or physical device.
2. Navigate to the screen that was refactored.
3. Verify all interactions (scroll, submit, error states) behave identically to before.
4. Check Firestore reads/writes still fire correctly by monitoring Firebase console logs.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| Multi-file extraction | God files are >3× the size limit | Partial in-file refactor leaves cyclomatic complexity unchanged |
| New widget files per feature | Required by feature-first structure | Co-locating widgets in screen file violates constitution V |
