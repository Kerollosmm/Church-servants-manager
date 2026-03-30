# Research: Production Audit Remediation

## Decision 1: Keep attendance writes in the existing repository flow, but make audit writes atomic with the business mutation

- **Decision**: Use Firestore transactions or write batches inside the attendance repository so mark/session mutations and their audit records commit together, and ensure clear/delete paths only write audits after the underlying mutation succeeds.
- **Rationale**: This fixes the false-success audit gap while staying aligned with the constitution's requirement for surgical changes and repository-layer data access. It avoids a larger migration of attendance writes into new backend-only callables.
- **Alternatives considered**:
  - Sequential client writes after the mutation: rejected because it still allows missing or false-success audit records.
  - Migrating all attendance mutations to callable functions: rejected for this feature because it broadens scope beyond the minimum required remediation.

## Decision 2: Preserve session uniqueness with the existing deterministic session ID and transaction lock, but remove the non-atomic pre-check

- **Decision**: Eliminate the pre-transaction overlap query, rely on the deterministic session identifier plus the transaction lock as the authoritative duplicate guard, and extend rules to support early close by authorized servants or admins.
- **Rationale**: The current pre-check introduces a race window without adding true protection. Removing it is a targeted correctness fix that keeps the proven transaction-based guard.
- **Alternatives considered**:
  - Keep the pre-check as a UX optimization: rejected because stale reads create misleading results without improving correctness.
  - Replace the whole flow with backend-only session creation: rejected as a broader architectural change than needed.

## Decision 3: Add additive attendance read models to remove N-listener and N+1 scaling risks

- **Decision**: Introduce additive read models for student history and rolling summaries so the UI reads a bounded history collection and summary documents instead of scanning many sessions and opening one listener per session.
- **Rationale**: The audit findings show the current history and statistics flow scales poorly as attendance accumulates. Additive read models preserve backward compatibility while giving the client stable, low-cost reads.
- **Alternatives considered**:
  - Limit history to the most recent 10 sessions only: rejected because it reduces cost but does not fully satisfy the requirement for stable history and summary views over time.
  - Add short-lived in-memory caching only: rejected because it does not address listener fan-out or cross-device consistency.

## Decision 4: Refresh the signed-in user's access context after permission-denied attendance actions

- **Decision**: When an attendance mutation fails for authorization reasons, surface an explicit access-changed message and trigger a refresh of the current `AuthUser` before allowing the next attempt.
- **Rationale**: This directly addresses stale team-assignment confusion without weakening Firestore rule enforcement.
- **Alternatives considered**:
  - Trust the stale in-memory user object and show a generic error: rejected because it leaves users confused and repeating blocked actions.
  - Refresh user data before every attendance action: rejected because it adds unnecessary latency to the primary workflow.

## Decision 5: Enforce restored-account password change as a hard auth gate

- **Decision**: Keep `restorePendingPasswordReset` active until the user completes an in-app password change flow, expose a dedicated auth state for required password change, and block normal navigation until the gate is cleared.
- **Rationale**: Restored privileged users currently can sign in and operate with temporary credentials. A dedicated auth gate is the smallest reliable fix.
- **Alternatives considered**:
  - Continue sending reset email only: rejected because it does not guarantee the user changes the password before gaining access.
  - Clear the flag on login and rely on user education: rejected because it does not satisfy the security requirement.

## Decision 6: Keep legacy/current servant assignment compatibility through centralized dual-write helpers

- **Decision**: Treat `assignedTeamIds` as the canonical assignment list, continue dual-writing legacy `assignedTeamId`, and centralize normalization for reads and writes across auth, admin-team assignment, and team cleanup flows.
- **Rationale**: Existing code and rules still rely on both fields. Dual-write compatibility preserves production behavior while removing split-brain risk.
- **Alternatives considered**:
  - Remove `assignedTeamId` immediately: rejected because it risks breaking legacy reads and rules in production.
  - Leave each writer to update fields independently: rejected because it perpetuates the inconsistency already flagged by the audit.

## Decision 7: Use custom claims for callable admin authorization and server timestamps for function-managed lifecycle fields

- **Decision**: Update `requireAdmin` to authorize from authenticated custom claims, block self-archive in the archive callable, preserve/merge existing claims when updating users, and write lifecycle timestamps using authoritative server-managed timestamps.
- **Rationale**: This removes unnecessary caller-role document reads on every callable invocation and aligns privileged operations with the same trust model used elsewhere.
- **Alternatives considered**:
  - Continue reading the caller's Firestore user document for every privileged request: rejected because it adds avoidable latency and cost.
  - Use client-generated timestamps in function payload builders: rejected because lifecycle and audit time should reflect the committed server event.

## Decision 8: Establish linked student ownership at creation time and enforce uniqueness before commit

- **Decision**: During student creation or linkage update, write both student-side ownership (`linkedUserId`) and user-side linkage (`linkedStudentId`) immediately, and reject linking if the same user is already attached to another student.
- **Rationale**: The audit found that initial linkage is not consistently established and uniqueness is not enforced. Fixing both at the write boundary prevents silent integrity drift.
- **Alternatives considered**:
  - Rely on later sync services to fill in linkage: rejected because it leaves a window where access rules and profile views are wrong.
  - Permit duplicate linkage and resolve conflicts manually: rejected because it creates privacy and authorization risk.
