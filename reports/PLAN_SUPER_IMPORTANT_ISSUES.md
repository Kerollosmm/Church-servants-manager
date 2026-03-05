# Super Important Issues Plan (P0)

This file contains the highest-risk blockers that make the app unsafe for production.

## Overall Verdict for This Group

- Status: **Release blocked**
- Reason: these issues can lead to privilege escalation, unauthorized data access, or insecure production distribution.
- Required timeline: fix before any production rollout.

## Issue 1: Missing versioned Firestore security artifacts

- Severity: P0
- Category: Security / Release Governance
- Evidence:
  - Missing `firestore.rules` at repo root.
  - Missing `firestore.indexes.json` at repo root.
  - Missing `.firebaserc` at repo root.
  - Runbook expects these files in `docs/REMEDIATION_RELEASE_RUNBOOK.md:12` and `docs/REMEDIATION_RELEASE_RUNBOOK.md:33`.
- Why this is bad:
  - Security policy is not reproducible across environments.
  - Team cannot verify least-privilege controls before deployment.
  - Incident response and audits fail when policy is not version controlled.
  - High chance of accidental over-permissive production rules.
- Root cause:
  - Firebase security/config files were not committed and enforced as deployment prerequisites.
- Solution:
  1. Add `firestore.rules` with explicit role-based constraints per collection.
  2. Add `firestore.indexes.json` matching all production queries.
  3. Add `.firebaserc` with explicit project aliases (`dev`, `staging`, `prod`).
  4. Add CI check to fail if these files are missing/invalid.
  5. Add deployment script that always deploys rules + indexes before app release.
- Acceptance criteria:
  - Files exist in repo and are reviewed.
  - Rules emulator tests pass for admin/servant/student cases.
  - CI blocks merges when rules are missing or fail validation.
  - Staging deploy proves policy behavior for all roles.

## Issue 2: Authorization relies on client-side checks

- Severity: P0
- Category: Security / Architecture
- Evidence:
  - Client role checks in `lib/features/admin/data/admin_team_service.dart:29`.
  - Client mutation path in `lib/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart:30`.
  - UI gate only in `lib/features/admin/presentation/widget/admin_gate.dart:27`.
- Why this is bad:
  - Mobile/web clients are untrusted; checks can be bypassed.
  - An attacker can call Firestore directly if rules are weak.
  - UI-level restrictions do not equal backend security.
- Root cause:
  - Trust boundary is implemented in presentation/domain layers instead of server-side policy.
- Solution:
  1. Move all privilege enforcement to Firestore rules and/or Cloud Functions.
  2. Restrict direct client writes for admin-only paths.
  3. Keep client-side checks only as UX guidance, not security.
  4. Add negative tests proving non-admin cannot mutate admin data.
- Acceptance criteria:
  - Unauthorized writes are denied by backend even with modified client.
  - Security tests include direct Firestore call attempts by each role.
  - Admin-only operations succeed only for valid admin claims/rules.

## Issue 3: Privileged account creation exposed from client

- Severity: P0
- Category: Security
- Evidence:
  - Public API in `lib/features/auth/data/services/auth_provider.dart:41`.
  - Service exposure in `lib/features/auth/data/services/auth_service.dart:114`.
  - Client implementation in `lib/features/auth/data/services/firebase_auth_provider.dart:326`.
  - Role write in `_saveUserToFirestore` at `lib/features/auth/data/services/firebase_auth_provider.dart:288`.
- Why this is bad:
  - Role assignment from client can be abused if backend checks are incomplete.
  - Creates a direct privilege-escalation path.
  - Violates principle of trusted backend for identity provisioning.
- Root cause:
  - Admin provisioning logic is implemented inside app client instead of backend service.
- Solution:
  1. Remove direct privileged creation from client surface.
  2. Create a callable HTTPS/Cloud Function for admin provisioning.
  3. Enforce admin claim verification in function.
  4. Set roles with server authority only.
  5. Add audit logging for account creation events.
- Acceptance criteria:
  - Client cannot assign privileged roles directly.
  - Backend function rejects non-admin callers.
  - Security tests cover escalation attempts.
  - Audit trail exists for role/account provisioning.

## Issue 4: Android release uses debug signing config

- Severity: P0
- Category: Release / Security
- Evidence:
  - `android/app/build.gradle.kts:40` uses debug signing config.
  - TODO marker near `android/app/build.gradle.kts:38` indicates incomplete release setup.
- Why this is bad:
  - Debug keys are not acceptable for production integrity.
  - Compromises release trust and store compliance posture.
  - Increases risk of package impersonation and key management failures.
- Root cause:
  - Production signing was never finalized and wired to secure secrets.
- Solution:
  1. Create production keystore and secure credential handling.
  2. Configure `release` signing to use secured env/gradle properties.
  3. Remove debug signing reference from release block.
  4. Document signing process and rotation policy.
- Acceptance criteria:
  - Release build signs with production key only.
  - No debug key references in release config.
  - Build pipeline can produce reproducible signed artifacts.

## Execution Plan (Super Important)

1. **Security foundation first**: add rules/indexes/.firebaserc and validate in emulator.
2. **Privilege boundary hardening**: move admin account creation and role assignment server-side.
3. **Release hardening**: complete Android production signing.
4. **Gate with CI**: block deployment until all P0 checks pass.

## Done Definition for This File

- All 4 P0 items resolved and verified in staging.
- Security tests pass for role boundaries and escalation attempts.
- Release candidate is signed properly and deploys with enforced policies.
