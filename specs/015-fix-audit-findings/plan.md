# Implementation Plan: Production Audit Remediation

**Branch**: `015-fix-audit-findings` | **Date**: 2026-03-29 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-fix-audit-findings/spec.md`

**Note**: This plan covers production-hardening fixes from the audit while explicitly excluding offline sync, offline retry queues, and other offline-first infrastructure.

## Summary

Remediate the production audit findings by hardening attendance write reliability, session lifecycle enforcement, authorization-refresh behavior, restored-account password gating, linked-student/account consistency, privileged admin safeguards, and scalable attendance history/statistics. The implementation will preserve the existing Firestore schema through additive changes, keep Firebase access in repositories/services/functions, and prioritize surgical updates to attendance, auth, student, team, admin, Cloud Functions, Firestore rules, and their tests.

## Technical Context

**Language/Version**: Dart `^3.9.2` for Flutter app; TypeScript `^5.9.2` on Node `20` for Firebase Functions  
**Primary Dependencies**: Flutter, flutter_bloc, get_it, cloud_firestore, firebase_auth, cloud_functions, freezed, equatable, rxdart, firebase-admin, firebase-functions  
**Storage**: Cloud Firestore, Firebase Auth, Firestore Security Rules, Firebase Cloud Functions  
**Testing**: `flutter_test`, `mocktail`, `fake_cloud_firestore`, Firestore rules tests, Functions `tsc` build/lint  
**Target Platform**: Flutter mobile app (Android/iOS) with Firebase backend  
**Project Type**: Mobile application with repo-local backend and security rules  
**Performance Goals**: Student history/summary loads under 3 seconds at p95 for a 52-session student history; team summary loads under 5 seconds at p95 for 10 mature teams; bulk mark of 200 remaining students completes without partial result  
**Constraints**: Preserve existing production schema and behavior through backward-compatible changes; keep business logic out of widgets; keep Firebase access inside repositories/services/functions; exclude offline sync scope; maintain both `assignedTeamIds` and legacy `assignedTeamId`; treat `linkedUserId` as canonical student-link ownership; add `FIX [015]` traceability comments during implementation  
**Scale/Scope**: Cross-feature remediation spanning `attendance`, `auth`, `student`, `team`, `admin`, `servant`, `core/routing`, `firestore.rules`, `functions/src`, and targeted unit/widget/rules tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Pre-Research Gate Review**

- **Production Stability & Schema Integrity**: PASS - all planned data changes are additive or dual-write compatible; no existing production document shape is removed or renamed.
- **Surgical & Minimal Interventions**: PASS - scope is limited to audited failure points and their direct tests; no unrelated refactors are planned.
- **Business Logic Isolation (Cubits Only)**: PASS - new behavior stays in repositories, services, rules, functions, and cubits; widgets remain presentation-only.
- **Encapsulated Data Access (Repository Layer)**: PASS - Flutter-side Firebase access remains in repository/service layers; no UI or cubit direct Firestore usage is introduced.
- **Feature-First Structure**: PASS - changes stay within existing feature slices and `lib/core` routing/DI support.
- **Fix Traceability**: PASS WITH ENFORCEMENT - implementation tasks must add `FIX [015]` comments near changed logic.

**Post-Design Re-Check**

- **Production Stability & Schema Integrity**: PASS - planned read models are additive and do not replace current documents; legacy assignment fields remain supported.
- **Surgical & Minimal Interventions**: PASS - the design favors transaction/batch hardening and small read-model additions over broad architectural migration.
- **Business Logic Isolation (Cubits Only)**: PASS - password-change gating, permission refresh, and session management remain state-driven rather than widget-driven.
- **Encapsulated Data Access (Repository Layer)**: PASS - new summary/history consumers remain behind attendance/auth/student repositories and services.
- **Feature-First Structure**: PASS - new artifacts fit existing attendance/auth/student/admin slices plus `functions/src` and `firestore.rules`.

## Project Structure

### Documentation (this feature)

```text
specs/015-fix-audit-findings/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── admin-callables.md
│   └── attendance-read-models.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── Features/
│   ├── admin/
│   ├── attendance/
│   ├── auth/
│   ├── servant/
│   ├── student/
│   └── team/
├── core/
├── church_app.dart
└── main.dart

functions/
├── src/
│   ├── admin.ts
│   ├── index.ts
│   └── lifecycle_helpers.ts
└── package.json

firestore.rules

test/
├── core/
├── features/attendance/
├── features/admin/
├── features/auth/
├── features/servant/
├── features/student/
└── features/team/
```

**Structure Decision**: Use the existing single Flutter mobile app plus repo-local Firebase backend structure. Application changes will be made under `lib/Features/` and `lib/core/`, backend safeguards under `functions/src/`, rule changes in `firestore.rules`, and regression coverage under `test/`.

## Complexity Tracking

No constitution violations or special complexity exemptions are required for this plan.
