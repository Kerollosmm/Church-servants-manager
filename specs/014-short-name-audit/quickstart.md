# Quickstart: CSMS Production Hardening Remediation

## Goal
Deliver the remediation in smaller phases so each phase can be implemented, verified, and accepted independently.

## Phase Sequence

### Phase 1 - Restore Attendance Operations
- Re-enable attendance entry points, session creation, active roster management, and history screens.
- Verify with widget/smoke flows for create -> mark -> review.

### Phase 2 - Harden Access Control
- Lock self-registration to the allowed role.
- Tighten protected navigation and record visibility for admin, servant, student, archived, and restored users.
- Verify with authorization and rules coverage.

### Phase 3 - Protect Data Integrity and Auditability
- Prevent conflicting sessions and silent bulk overwrites.
- Preserve accountable mark and lifecycle history.
- Verify with concurrency and audit acceptance tests.

### Phase 4 - Stabilize Membership and Admin Lifecycle Flows
- Remove actor attribution gaps.
- Make team membership and managed account lifecycle flows consistent and reviewable.
- Verify with admin lifecycle and membership consistency tests.

### Phase 5 - Bound Reporting and Operational Performance
- Limit reporting to defined windows.
- Reduce heavy attendance query patterns and align indexes.
- Verify with bounded-report performance checks and regression tests.

## Acceptance Notes

- Phase 1 acceptance: attendance create/take/history/student flows are reachable and no longer blank.
- Phase 2 acceptance: self-registration, degraded sessions, and role boundaries are enforced consistently.
- Phase 3 acceptance: concurrent attendance actions preserve intent and audit events are written for lifecycle changes.
- Phase 4 acceptance: restore/lifecycle follow-up guidance is visible and membership updates carry actor attribution.
- Phase 5 acceptance: attendance summaries are bounded by default windows and admins can review recent audit activity without inspecting raw backend data.

## Suggested Verification Commands

```bash
flutter analyze
flutter test
npm run lint --prefix functions
```

## Acceptance Order

1. Accept Phase 1 before starting broad security hardening.
2. Accept Phase 2 before shipping restored attendance broadly.
3. Accept Phase 3 before treating reports or audit screens as trustworthy.
4. Accept Phase 4 before relying on lifecycle and membership administration.
5. Accept Phase 5 before calling the remediation production-ready.

## Explicit Exclusion

This remediation does not redesign offline sync, write replay, pending status tracking, or retry orchestration.
