# Implementation Plan: Fix P1 Stability Issues

**Branch**: `006-fix-p1-stability` | **Date**: 2026-03-23 | **Spec**: [specs/006-fix-p1-stability/spec.md](spec.md)
**Input**: Feature specification from `/specs/006-fix-p1-stability/spec.md`

## Summary

Resolve critical stability issues (P1-A, P1-B, P1-C) identified in the code review by unifying dependency injection in the router, implementing type-safe role routing, and eliminating race conditions in attendance processing using a state-snapshot pattern.

## Technical Context

**Language/Version**: Dart ^3.9.2, Flutter 3.x  
**Primary Dependencies**: `flutter_bloc`, `get_it`, `go_router`, `freezed`, `equatable`, `firebase_auth`, `cloud_firestore`  
**Storage**: Firebase Firestore  
**Testing**: `package:test`, `package:flutter_test`  
**Target Platform**: Mobile (Android/iOS)  
**Project Type**: Mobile App  
**Performance Goals**: Latency-free attendance marking, immediate UI feedback.  
**Constraints**: Offline-capable, strictly immutable state, surgical interventions only.  
**Scale/Scope**: Support for 500+ students per team.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Production Stability | ✅ PASS | Design ensures atomic updates and safe navigation transitions. |
| II. Surgical Interventions | ✅ PASS | Contract surface area is limited to identified P1 files. |
| III. Business Logic Isolation | ✅ PASS | Mutation logic isolated in `AttendanceTakingCubit`. |
| IV. Encapsulated Data Access | ✅ PASS | Router and Cubit interact only with UseCases and Repositories. |
| V. Feature-First Structure | ✅ PASS | No cross-feature leakage introduced. |
| 1. Immutable State | ✅ PASS | State snapshot pattern preserves immutability and equality. |
| 2. Dependency Injection | ✅ PASS | `getIt` mapping documented in router-di contract. |

## Project Structure

### Documentation (this feature)

```text
specs/006-fix-p1-stability/
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
│   └── routing/
│       ├── app_router.dart      # [P1-A] Refactor DI
│       └── role_router.dart     # [P1-B] Type-safe routing
└── features/
    └── attendance/
        └── presentation/
            └── bloc/
                └── attendance_taking/
                    └── attendance_taking_cubit.dart # [P1-C] Atomic mutations
```

**Structure Decision**: Standard vertical slice architecture as defined in `lib/`. No new top-level directories required.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*(No violations detected)*
