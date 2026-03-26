# Research: Protect Student Attendance Access

**Branch**: `011-fix-student-access` | **Date**: 2026-03-24
**Input**: Student ownership rule fix, rules deployment, and emulator coverage request

## Decision 1: Add dedicated Firestore rules tests

**Decision**: Introduce automated Firestore emulator rules tests for this feature.

**Rationale**: The repository contains `firestore.rules` and `firebase.json`, but no existing
rules-test harness or assertions for allow/deny behavior. The feature acceptance criteria
require verified self-read and cross-read outcomes, which cannot be proven with Flutter-side
repository tests alone.

**Alternatives considered**:
- Rely on manual emulator checks only - rejected because the feature explicitly requires automated emulator verification.
- Reuse application tests - rejected because those tests do not evaluate Firestore security rules.

## Decision 2: Reuse the existing `functions/` TypeScript toolchain for rules tests

**Decision**: Place rules tests in `functions/test/firestore_rules/` and extend the existing
Node/TypeScript package for execution.

**Rationale**: `functions/package.json` is the only existing JavaScript/TypeScript package in
the repo, so it is the smallest change surface for adding emulator test dependencies and a
repeatable test command.

**Alternatives considered**:
- Create a new root-level Node package - rejected as unnecessary additional tooling surface.
- Add Dart-based rule tests - rejected because Firestore rules evaluation is better supported by the Firebase rules unit testing library.

## Decision 3: Treat `students/{studentId}.linkedUser` as the ownership bridge for this feature

**Decision**: Plan the authorization fix around the requested ownership check:
student self-read is granted only when the requested student profile's `linkedUser` value
matches the authenticated user ID.

**Rationale**: The active feature request and accepted specification explicitly define
`linkedUser` as the bridge between a student profile and the authenticated account. The plan
therefore treats that relationship as authoritative for security-rule evaluation.

**Alternatives considered**:
- Continue comparing `studentId` to the authenticated user ID - rejected because the feature exists specifically to replace this incorrect assumption.
- Continue using another profile field as the ownership bridge - rejected because it would not satisfy the requested rule behavior.

## Decision 4: Keep attendance storage and servant access unchanged

**Decision**: Do not redesign attendance mark storage or servant authorization logic.

**Rationale**: Attendance marks already live under
`classes/{teamId}/attendance_sessions/{sessionId}/marks/{studentId}` and the feature scope is
limited to student ownership evaluation for reads. Servant access must continue to use the
existing team-based authorization path.

**Alternatives considered**:
- Move marks to a different path - rejected as out of scope and risky.
- Merge student and servant access into one new authorization model - rejected because it would violate the surgical-change requirement.

## Decision 5: Verify locally before deploying rules

**Decision**: Make emulator verification the required gate before deploying updated Firestore rules.

**Rationale**: The change directly affects production authorization behavior. Running local
allow/deny tests before deployment reduces the risk of blocking legitimate student access or
opening cross-student access unexpectedly.

**Alternatives considered**:
- Deploy first and verify afterward - rejected because authorization regressions would reach production before validation.
- Skip deployment guidance in the plan - rejected because the user explicitly requested rule deployment.
