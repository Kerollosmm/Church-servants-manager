# Medium Issues Plan (P1)

This file contains important stability and scale issues that should be fixed before wide user rollout.

## Overall Verdict for This Group

- Status: **High priority stabilization required**
- Reason: these issues can cause role inconsistency, hidden data, weak quality control, and brittle releases.
- Required timeline: complete during pre-production stabilization.

## Issue 1: Firestore collection naming mismatch risk

- Severity: P1
- Category: Reliability / Architecture
- Evidence:
  - App constants currently use uppercase names in `lib/core/constants/firestore_collections.dart:3`.
  - Release runbook references lowercase canonical naming in `docs/REMEDIATION_RELEASE_RUNBOOK.md:16`.
- Why this is bad:
  - Different environments/tools may read/write different collections.
  - Can create split data and silent partial outages.
  - Hard to detect quickly because app may still appear to work for some users.
- Root cause:
  - Schema naming decision is not unified and enforced across code + docs + tooling.
- Solution:
  1. Decide one canonical naming strategy.
  2. Align constants, rules, scripts, docs, and migration tools.
  3. Add startup guard/check to detect invalid schema path usage.
  4. Run one-time migration (if needed) with verification script.
- Acceptance criteria:
  - Single naming scheme used everywhere.
  - Data parity check passes between old/new paths after migration.
  - No references to legacy naming in app runtime paths.

## Issue 2: Critical test coverage is still too small

- Severity: P1
- Category: Testing
- Evidence:
  - Current tests are only:
    - `test/core/utils/validators_test.dart`
    - `test/features/auth/presentation/bloc/auth_bloc_test.dart`
  - `lib/` contains a much larger surface area (many repositories/blocs/screens).
- Why this is bad:
  - Regressions in data mutation and authorization paths are likely.
  - Refactors remain risky and slow because behavior is not protected.
- Root cause:
  - Testing started recently and has not expanded to high-risk modules.
- Solution:
  1. Add unit tests for repository authorization and failure mapping.
  2. Add bloc/cubit tests for student/servant/team mutation flows.
  3. Add integration tests for role-based navigation and admin restrictions.
  4. Add Firestore rules emulator tests.
- Acceptance criteria:
  - High-risk flows covered (authz + mutations + refresh/degraded paths).
  - CI runs full test suite on PR.
  - Failing tests block merge.

## Issue 3: No CI quality gates

- Severity: P1
- Category: Release / DevOps
- Evidence:
  - No workflows found under `.github/workflows/`.
- Why this is bad:
  - Broken code can merge/deploy without checks.
  - No repeatable validation for analyze/test/build/security policy checks.
- Root cause:
  - Pipeline automation not yet established for this repository.
- Solution:
  1. Add CI workflow for `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`.
  2. Add job for `dart run build_runner build --delete-conflicting-outputs` validation.
  3. Add artifact build smoke jobs (Android/iOS as feasible).
  4. Require CI checks before merge.
- Acceptance criteria:
  - CI runs on PR and main.
  - Merge is blocked on failed analyze/test/build checks.
  - Security policy files are validated in CI.

## Issue 4: Degraded auth state may keep stale permissions

- Severity: P1
- Category: Security / Reliability
- Evidence:
  - Degraded user state fallback in `lib/features/auth/presentation/bloc/auth_bloc.dart:92` and `:186`.
  - Role routing trusts degraded state in `lib/role_user_route.dart:60`.
  - Admin gate accepts degraded user state in `lib/features/admin/presentation/widget/admin_gate.dart:27`.
- Why this is bad:
  - Revoked roles may still access privileged UI/flows temporarily.
  - Causes inconsistent permission behavior and security confusion.
- Root cause:
  - Offline/degraded UX was prioritized without strict privilege revalidation.
- Solution:
  1. Restrict degraded mode to read-only safe paths.
  2. Force fresh permission check before admin mutations.
  3. Show explicit re-auth/refresh requirement for privileged actions.
  4. Add tests for role revocation while app is active.
- Acceptance criteria:
  - Admin actions blocked in degraded mode until revalidated.
  - Revoked role behavior is deterministic and tested.

## Issue 5: Hard list limits hide data at scale

- Severity: P1
- Category: Performance / Reliability
- Evidence:
  - Students capped at 200 in `lib/features/student/data/repos/student_data_repository.dart:392`.
  - Servants capped at 200 in `lib/features/servant/data/repo/servant_data_repository.dart:205`.
- Why this is bad:
  - Larger datasets become partially invisible.
  - Users may make decisions on incomplete information.
- Root cause:
  - Fixed cap implemented without pagination/infinite loading strategy.
- Solution:
  1. Implement cursor-based pagination.
  2. Provide visible total/count and "load more" UX.
  3. Add query/index validation for paginated endpoints.
  4. Add stress tests for large datasets.
- Acceptance criteria:
  - No silent truncation of records.
  - Users can access full dataset safely and predictably.

## Execution Plan (Medium)

1. Unify schema naming and run migration checks.
2. Build CI workflow with mandatory gates.
3. Expand tests around authz and mutation paths.
4. Tighten degraded-mode authorization behavior.
5. Implement pagination where fixed 200 caps exist.

## Done Definition for This File

- All P1 issues resolved with tests and CI enforcement.
- Staging demonstrates stable behavior for role changes and large datasets.
