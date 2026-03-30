# Implementation Plan: CSMS Production Hardening Remediation

**Branch**: `[014-short-name-audit]` | **Date**: 2026-03-28 | **Spec**: `C:\Users\KimoStore\church_managment_system\specs\014-short-name-audit\spec.md`
**Input**: Feature specification from `C:\Users\KimoStore\church_managment_system\specs\014-short-name-audit\spec.md`

## Summary

Harden the Church Servants Management System for production readiness by restoring the core attendance workflow, tightening authorization and account boundaries, preserving auditability and concurrent-write correctness, and bounding reporting/admin operations for operational scale. Per user request, the work is split into smaller implementation phases, and each phase has its own focused delivery plan. Offline sync redesign remains explicitly out of scope.

## Technical Context

**Language/Version**: Dart `^3.9.2`, Flutter mobile application  
**Primary Dependencies**: Flutter, flutter_bloc, get_it, cloud_firestore, firebase_auth, cloud_functions, freezed, equatable, rxdart, connectivity_plus  
**Storage**: Firestore, Firebase Auth, Cloud Functions, local Firestore persistence, existing Hive dependency not used for this scoped feature  
**Testing**: `flutter_test`, `mocktail`, `fake_cloud_firestore`, analyzer, emulator/rules validation to be added in this feature  
**Target Platform**: Android and iOS mobile clients backed by Firebase services  
**Project Type**: Feature-first Flutter mobile app with Firebase backend  
**Performance Goals**: Core attendance workflows complete without blank screens; bounded reports load in under 3 seconds for expected operating volumes; no unbounded scans for routine reporting  
**Constraints**: Must preserve production schema compatibility, keep changes surgical, keep business logic in Cubits/repositories, avoid offline-sync redesign, maintain backward compatibility with current data  
**Scale/Scope**: Church operations with hundreds of active students, multi-servant attendance sessions, role-based admin/servant/student access, audit-sensitive lifecycle actions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Production Stability & Schema Integrity**: PASS with additive-only changes. New audit or aggregate structures must be backward-compatible and must not break current document reads.
- **II. Surgical & Minimal Interventions**: PASS. Plan is limited to audited logic gaps and phased remediation; offline sync redesign is excluded.
- **III. Business Logic Isolation (Cubits Only)**: PASS. Restored screens must remain thin; logic stays in Cubits/repositories/services.
- **IV. Encapsulated Data Access (Repository Layer)**: PASS with enforcement work included. The plan reduces direct boundary leakage and keeps Firebase access behind repositories/services or backend functions.
- **V. Feature-First Structure**: PASS. Work stays within existing feature slices for auth, attendance, student, servant, team, admin, and shared core routing/DI.
- **Fix Traceability Requirement**: PASS. Implementation tasks will require `// FIX [014-*]` annotations near changed logic.
- **Design Governance**: PASS. No unresolved architecture decisions remain for planning; each phase uses existing patterns or explicit additive backend extensions.

**Post-Design Re-Check**: PASS. Generated research, data model, contracts, and phase plan keep changes additive, feature-first, and repository-centered.

## Project Structure

### Documentation (this feature)

```text
specs/014-short-name-audit/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── attendance-operations.md
│   └── access-and-audit.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   ├── di/
│   ├── routing/
│   └── services/
├── Features/
│   ├── admin/
│   ├── attendance/
│   ├── attendance_record/
│   ├── auth/
│   ├── servant/
│   ├── student/
│   └── team/
└── church_app.dart

functions/
└── src/

test/
├── core/
└── features/

specs/
└── 014-short-name-audit/
```

**Structure Decision**: Use the existing single Flutter mobile app plus Firebase backend structure. Phase work is organized by feature slice, with backend authorization/audit work in `functions/`, client routing/DI in `lib/core/`, and domain-specific changes inside the relevant `lib/Features/` directories.

## Implementation Phases

### Phase 1 - Restore Operational Attendance Surfaces

**Goal**: Re-enable the end-to-end attendance workflow through working screens and route entry points without redesigning domain logic.

**Plan**:
- Restore admin/servant entry points that lead into attendance workflows.
- Replace placeholder attendance screens and widgets with working flows for session creation, attendance taking, session review/history, and student attendance viewing.
- Keep screens thin and bind them to existing Cubits/repository streams.
- Add smoke/widget/integration-level coverage for the five core attendance journeys.

**Primary Areas**:
- `lib/Features/attendance/presentation/screens/`
- `lib/Features/attendance/presentation/widgets/`
- `lib/Features/admin/presentation/screens/`
- `lib/Features/servant/presentation/screens/`
- `lib/core/routing/`

**Exit Gate**:
- No attendance-management screen is blank or placeholder.
- Authorized users can create, take, and review attendance from the app.

### Phase 2 - Access Control and Session Hardening

**Goal**: Make role enforcement, self-registration, archive behavior, and Firestore access rules consistent and safe.

**Plan**:
- Restrict self-registration to the self-service role only.
- Make protected navigation reactive to auth changes and stale-session demotion.
- Replace hot-path rule lookups with a lighter authorization strategy for coarse role/archive checks while preserving server authority.
- Standardize the canonical student-user link field and remove ambiguous self-read paths.
- Tighten session and mark access rules to reflect intended team and student scope.

**Primary Areas**:
- `lib/Features/auth/`
- `lib/core/routing/`
- `firestore.rules`
- `functions/src/`

**Exit Gate**:
- Authorization tests pass for admin, servant, student, archived, restored, and self-registered flows.
- No direct self-elevation path remains.

### Phase 3 - Attendance Integrity and Auditability

**Goal**: Prevent destructive concurrent overwrites and preserve accountable history for mark/session lifecycle changes.

**Plan**:
- Protect manual attendance exceptions from bulk actions.
- Make conflicting session creation impossible within an active window.
- Replace destructive attendance clear behavior with accountable change history.
- Ensure all high-impact lifecycle actions record actor and timestamp.
- Introduce immutable audit events for attendance and account lifecycle changes if needed as additive records.

**Primary Areas**:
- `lib/Features/attendance/data/`
- `lib/Features/attendance/presentation/bloc/`
- `lib/Features/servant/data/`
- `lib/Features/team/data/`
- `functions/src/`

**Exit Gate**:
- Concurrent attendance tests preserve intended outcomes.
- Audit records exist for create/close/archive/restore/mark-change actions.

### Phase 4 - Membership, Identity, and Admin Lifecycle Consistency

**Goal**: Remove stale fallback truth, fix actor attribution gaps, and make managed account lifecycle flows operational.

**Plan**:
- Eliminate remaining `'system'` actor writes for servant/team lifecycle actions.
- Harden team membership projections and reduce silent stale fallbacks.
- Improve managed account restore/provisioning follow-up so administrators have a clear next-step workflow.
- Ensure identity links and membership-derived fields stay consistent across impacted features.

**Primary Areas**:
- `lib/Features/student/data/`
- `lib/Features/servant/data/`
- `lib/Features/team/data/`
- `lib/Features/admin/data/`
- `lib/Features/admin/presentation/`

**Exit Gate**:
- Lifecycle actor attribution is complete.
- Membership and identity linkage tests no longer rely on ambiguous fallback behavior.

### Phase 5 - Reporting and Query-Bound Performance Hardening

**Goal**: Make reporting/admin flows bounded, reliable, and operationally performant for expected church data volumes.

**Plan**:
- Require bounded periods for team and student summaries.
- Reduce high-cost attendance history and stats query patterns.
- Review and align Firestore indexes with actual runtime collection names and query shapes.
- Add admin-facing audit/review surface and reporting entry points that operate within bounded scopes.

**Primary Areas**:
- `lib/Features/attendance/data/`
- `lib/Features/admin/presentation/`
- `firestore.indexes.json`
- reporting-related tests/docs

**Exit Gate**:
- Report queries are bounded and validated.
- Expected-size reporting acceptance tests meet response-time targets.

## Complexity Tracking

No constitution violations are currently required. If implementation introduces additive audit or aggregate records, they must be documented as backward-compatible schema extensions rather than replacements.
